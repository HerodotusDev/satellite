// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {IFactsRegistry} from "interfaces/external/IFactsRegistry.sol";
import {ISatellite} from "interfaces/ISatellite.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";
import {ModuleTask, ModuleCodecs} from "libraries/internal/data-processor/ModuleCodecs.sol";
import {IDataProcessorModule} from "interfaces/modules/IDataProcessorModule.sol";

/// @title DataProcessorModule
/// @author Herodotus Dev Ltd
/// @notice A contract to store the execution results of HDP tasks
contract DataProcessorModule is IDataProcessorModule {
    // ========================= Types ========================= //

    using MerkleProof for bytes32[];
    using ModuleCodecs for ModuleTask;

    // ========================= Constants ========================= //

    bytes32 constant POSEIDON_HASHING_FUNCTION = keccak256("poseidon");

    // ========================= Satellite Module Storage ========================= //

    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.satellite.module.storage.data-processor");

    function moduleStorage() internal pure returns (ModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // ========================= Owner-only Functions ========================= //

    /// @notice setDataProcessorProgramHash hash for the HDP program
    function setDataProcessorProgramHash(bytes32 programHash) external {
        LibSatellite.enforceIsContractOwner();
        ModuleStorage storage ms = moduleStorage();
        ms.programHash = programHash;
    }

    /// @notice setDataProcessorFactsRegistry address of the facts registry with verified execution of the HDP program
    function setDataProcessorFactsRegistry(IFactsRegistry factsRegistry) external {
        LibSatellite.enforceIsContractOwner();
        ModuleStorage storage ms = moduleStorage();
        ms.factsRegistry = factsRegistry;
    }

    // ========================= Core Functions ========================= //

    /// @notice Requests the execution of a task with a module
    /// @param moduleTask module task
    function requestDataProcessorExecutionOfTask(ModuleTask calldata moduleTask) external {
        ModuleStorage storage ms = moduleStorage();
        bytes32 taskCommitment = moduleTask.commit();

        if (ms.cachedTasksResult[taskCommitment].status == TaskStatus.FINALIZED) {
            emit TaskAlreadyStored(taskCommitment);
        } else {
            // Ensure task is not already scheduled
            if (ms.cachedTasksResult[taskCommitment].status != TaskStatus.NONE) {
                revert DoubleRegistration();
            }

            // Store the task result
            ms.cachedTasksResult[taskCommitment] = TaskResult({status: TaskStatus.SCHEDULED, result: ""});

            emit ModuleTaskScheduled(moduleTask);
        }
    }

    /// @notice Authenticates the execution of a task is finalized
    ///     by verifying the FactRegistry and Merkle proofs
    /// @param mmrIds The id of the MMR used to compute task
    /// @param mmrSizes The size of the MMR used to compute task
    /// @param taskMerkleRootLow The low 128 bits of the tasks Merkle root
    /// @param taskMerkleRootHigh The high 128 bits of the tasks Merkle root
    /// @param resultMerkleRootLow The low 128 bits of the results Merkle root
    /// @param resultMerkleRootHigh The high 128 bits of the results Merkle root
    /// @param tasksInclusionProofs The Merkle proof of the tasks
    /// @param resultsInclusionProofs The Merkle proof of the results
    /// @param taskCommitments The commitment of the tasks
    /// @param taskResults The result of the computational tasks
    function authenticateDataProcessorTaskExecution(
        uint256[] calldata chainIds,
        uint256[] calldata mmrIds,
        uint256[] calldata mmrSizes,
        uint256 taskMerkleRootLow,
        uint256 taskMerkleRootHigh,
        uint256 resultMerkleRootLow,
        uint256 resultMerkleRootHigh,
        bytes32[][] memory tasksInclusionProofs,
        bytes32[][] memory resultsInclusionProofs,
        bytes32[] calldata taskCommitments,
        bytes32[] calldata taskResults
    ) external {
        ModuleStorage storage ms = moduleStorage();

        assert(mmrIds.length == mmrSizes.length);
        assert(chainIds.length == mmrIds.length);
        // Initialize an array of uint256 to store the program output
        uint256[] memory programOutput = new uint256[](4 + mmrIds.length * 4);

        // Assign values to the program output array
        programOutput[0] = resultMerkleRootLow;
        programOutput[1] = resultMerkleRootHigh;
        programOutput[2] = taskMerkleRootLow;
        programOutput[3] = taskMerkleRootHigh;

        for (uint8 i = 0; i < mmrIds.length; i++) {
            bytes32 usedMmrRoot = loadMmrRoot(mmrIds[i], mmrSizes[i], chainIds[i]);
            programOutput[4 + i * 4] = mmrIds[i];
            programOutput[4 + i * 4 + 1] = mmrSizes[i];
            programOutput[4 + i * 4 + 2] = chainIds[i];
            programOutput[4 + i * 4 + 3] = uint256(usedMmrRoot);
        }

        // Compute program output hash
        bytes32 programOutputHash = keccak256(abi.encodePacked(programOutput));

        // Compute GPS fact hash
        bytes32 gpsFactHash = keccak256(abi.encode(ms.programHash, programOutputHash));

        // Ensure GPS fact is registered
        if (!ms.factsRegistry.isValid(gpsFactHash)) {
            revert InvalidFact();
        }

        // Loop through all the tasks in the batch
        for (uint256 i = 0; i < taskResults.length; i++) {
            bytes32 computationalTaskResult = taskResults[i];
            bytes32[] memory taskInclusionProof = tasksInclusionProofs[i];
            bytes32[] memory resultInclusionProof = resultsInclusionProofs[i];

            // Convert the low and high 128 bits to a single 256 bit value
            bytes32 resultMerkleRoot = bytes32((resultMerkleRootHigh << 128) | resultMerkleRootLow);
            bytes32 taskMerkleRoot = bytes32((taskMerkleRootHigh << 128) | taskMerkleRootLow);

            // Compute the Merkle leaf of the task
            bytes32 taskCommitment = taskCommitments[i];
            bytes32 taskMerkleLeaf = standardNativeHDPLeafHash(taskCommitment);
            // Ensure that the task is included in the batch, by verifying the Merkle proof
            bool isVerifiedTask = taskInclusionProof.verify(taskMerkleRoot, taskMerkleLeaf);

            if (!isVerifiedTask) {
                revert NotInBatch();
            }

            // Compute the Merkle leaf of the task result
            bytes32 taskResultCommitment = keccak256(abi.encode(taskCommitment, computationalTaskResult));
            bytes32 taskResultMerkleLeaf = standardNativeHDPLeafHash(taskResultCommitment);
            // Ensure that the task result is included in the batch, by verifying the Merkle proof
            bool isVerifiedResult = resultInclusionProof.verify(resultMerkleRoot, taskResultMerkleLeaf);

            if (!isVerifiedResult) {
                revert NotInBatch();
            }

            // Store the task result
            ms.cachedTasksResult[taskCommitment] = TaskResult({status: TaskStatus.FINALIZED, result: computationalTaskResult});
        }
    }

    // ========================= View Functions ========================= //

    /// @notice Returns the result of a finalized task
    function getDataProcessorFinalizedTaskResult(bytes32 taskCommitment) external view returns (bytes32) {
        ModuleStorage storage ms = moduleStorage();
        // Ensure task is finalized
        if (ms.cachedTasksResult[taskCommitment].status != TaskStatus.FINALIZED) {
            revert NotFinalized();
        }
        return ms.cachedTasksResult[taskCommitment].result;
    }

    /// @notice Returns the status of a task
    function getDataProcessorTaskStatus(bytes32 taskCommitment) external view returns (TaskStatus) {
        ModuleStorage storage ms = moduleStorage();
        return ms.cachedTasksResult[taskCommitment].status;
    }

    // ========================= Internal Functions ========================= //

    /// @notice Load MMR root from cache with given mmrId and mmrSize
    function loadMmrRoot(uint256 mmrId, uint256 mmrSize, uint256 chainId) internal view returns (bytes32) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.mmrs[chainId][mmrId][POSEIDON_HASHING_FUNCTION].mmrSizeToRoot[mmrSize];
    }

    /// @notice Returns the leaf of standard merkle tree
    function standardNativeHDPLeafHash(bytes32 value) internal pure returns (bytes32) {
        bytes32 firstHash = keccak256(abi.encode(value));
        bytes32 leaf = keccak256(abi.encode(firstHash));
        return leaf;
    }
}
