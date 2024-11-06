// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {IFactsRegistry} from "interfaces/external/IFactsRegistry.sol";
import {ISatellite} from "interfaces/ISatellite.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";
import {ModuleTask, ModuleCodecs} from "libraries/internal/data-processor/ModuleCodecs.sol";
import {INativeDataProcessorModule} from "interfaces/modules/data-processor/INativeDataProcessorModule.sol";

/// @title NativeDataProcessorModule
/// @author Herodotus Dev Ltd
/// @notice A contract to store the execution results of HDP tasks
contract NativeDataProcessorModule is INativeDataProcessorModule {
    using MerkleProof for bytes32[];
    using ModuleCodecs for ModuleTask;

    /// @notice constant representing the pedersen hash of the Cairo HDP program
    bytes32 public PROGRAM_HASH;

    /// @notice interface to the facts registry of SHARP
    IFactsRegistry public FACTS_REGISTRY;

    /// @notice representing the chain id
    uint256 public CHAIN_ID;

    /// @notice hashing function used in this contract
    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");

    /// @notice mapping of task result hash => task
    mapping(bytes32 => TaskResult) public cachedTasksResult;

    constructor(IFactsRegistry factsRegistry, uint256 chainId, bytes32 programHash) {
        FACTS_REGISTRY = factsRegistry;
        CHAIN_ID = chainId;
        PROGRAM_HASH = programHash;
    }

    /// @notice Set the program hash for the HDP program
    function setProgramHash(bytes32 programHash) external {
        LibSatellite.enforceIsContractOwner();
        PROGRAM_HASH = programHash;
    }

    /// @notice Requests the execution of a task with a module
    /// @param moduleTask module task
    function requestExecutionOfModuleTask(ModuleTask calldata moduleTask) external {
        bytes32 taskCommitment = moduleTask.commit();

        if (cachedTasksResult[taskCommitment].status == TaskStatus.FINALIZED) {
            emit TaskAlreadyStored(taskCommitment);
        } else {
            // Ensure task is not already scheduled
            if (cachedTasksResult[taskCommitment].status != TaskStatus.NONE) {
                revert DoubleRegistration();
            }

            // Store the task result
            cachedTasksResult[taskCommitment] = TaskResult({status: TaskStatus.SCHEDULED, result: ""});

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
    function authenticateTaskExecution(
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
        assert(mmrIds.length == mmrSizes.length);

        // Initialize an array of uint256 to store the program output
        uint256[] memory programOutput = new uint256[](4 + mmrIds.length * 4);

        // Assign values to the program output array
        programOutput[0] = resultMerkleRootLow;
        programOutput[1] = resultMerkleRootHigh;
        programOutput[2] = taskMerkleRootLow;
        programOutput[3] = taskMerkleRootHigh;

        for (uint8 i = 0; i < mmrIds.length; i++) {
            bytes32 usedMmrRoot = loadMmrRoot(mmrIds[i], mmrSizes[i]);
            programOutput[4 + i * 4] = mmrIds[i];
            programOutput[4 + i * 4 + 1] = mmrSizes[i];
            programOutput[4 + i * 4 + 2] = CHAIN_ID;
            programOutput[4 + i * 4 + 3] = uint256(usedMmrRoot);
        }

        // Compute program output hash
        bytes32 programOutputHash = keccak256(abi.encodePacked(programOutput));

        // Compute GPS fact hash
        bytes32 gpsFactHash = keccak256(abi.encode(PROGRAM_HASH, programOutputHash));

        // Ensure GPS fact is registered
        if (!FACTS_REGISTRY.isValid(gpsFactHash)) {
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
            bytes32 taskMerkleLeaf = standardLeafHash(taskCommitment);
            // Ensure that the task is included in the batch, by verifying the Merkle proof
            bool isVerifiedTask = taskInclusionProof.verify(taskMerkleRoot, taskMerkleLeaf);

            if (!isVerifiedTask) {
                revert NotInBatch();
            }

            // Compute the Merkle leaf of the task result
            bytes32 taskResultCommitment = keccak256(abi.encode(taskCommitment, computationalTaskResult));
            bytes32 taskResultMerkleLeaf = standardLeafHash(taskResultCommitment);
            // Ensure that the task result is included in the batch, by verifying the Merkle proof
            bool isVerifiedResult = resultInclusionProof.verify(resultMerkleRoot, taskResultMerkleLeaf);

            if (!isVerifiedResult) {
                revert NotInBatch();
            }

            // Store the task result
            cachedTasksResult[taskCommitment] = TaskResult({status: TaskStatus.FINALIZED, result: computationalTaskResult});
        }
    }

    /// @notice Load MMR root from cache with given mmrId and mmrSize
    function loadMmrRoot(uint256 mmrId, uint256 mmrSize) internal view returns (bytes32) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.mmrs[CHAIN_ID][mmrId][KECCAK_HASHING_FUNCTION].mmrSizeToRoot[mmrSize];
    }

    /// @notice Returns the result of a finalized task
    function getFinalizedTaskResult(bytes32 taskCommitment) external view returns (bytes32) {
        // Ensure task is finalized
        if (cachedTasksResult[taskCommitment].status != TaskStatus.FINALIZED) {
            revert NotFinalized();
        }
        return cachedTasksResult[taskCommitment].result;
    }

    /// @notice Returns the status of a task
    function getTaskStatus(bytes32 taskCommitment) external view returns (TaskStatus) {
        return cachedTasksResult[taskCommitment].status;
    }

    /// @notice Returns the leaf of standard merkle tree
    function standardLeafHash(bytes32 value) public pure returns (bytes32) {
        bytes32 firstHash = keccak256(abi.encode(value));
        bytes32 leaf = keccak256(abi.encode(firstHash));
        return leaf;
    }
}
