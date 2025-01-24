// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IFactsRegistry} from "src/interfaces/external/IFactsRegistry.sol";
import {ISatellite} from "src/interfaces/ISatellite.sol";
import {LibSatellite} from "src/libraries/LibSatellite.sol";
import {ModuleTask, ModuleCodecs} from "src/libraries/internal/data-processor/ModuleCodecs.sol";
import {IDataProcessorModule} from "src/interfaces/modules/IDataProcessorModule.sol";
import {AccessController} from "src/libraries/AccessController.sol";
/// @title DataProcessorModule
/// @author Herodotus Dev Ltd
/// @notice A contract to store the execution results of HDP tasks
contract DataProcessorModule is IDataProcessorModule, AccessController {
    // ========================= Types ========================= //

    using MerkleProof for bytes32[];
    using ModuleCodecs for ModuleTask;

    // ========================= Constants ========================= //

    bytes32 constant POSEIDON_HASHING_FUNCTION = keccak256("poseidon");

    // ========================= Satellite Module Storage ========================= //

    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.satellite.module.storage.data-processor");

    function moduleStorage() internal pure returns (DataProcessorModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // ========================= Owner-only Functions ========================= //

    /// @inheritdoc IDataProcessorModule
    function setDataProcessorProgramHash(bytes32 programHash) external onlyOwner {
        DataProcessorModuleStorage storage ms = moduleStorage();
        ms.programHash = programHash;
    }

    /// @inheritdoc IDataProcessorModule
    function setDataProcessorFactsRegistry(IFactsRegistry factsRegistry) external onlyOwner {
        DataProcessorModuleStorage storage ms = moduleStorage();
        ms.factsRegistry = factsRegistry;
    }

    // ========================= Core Functions ========================= //

    /// @inheritdoc IDataProcessorModule
    function requestDataProcessorExecutionOfTask(ModuleTask calldata moduleTask) external {
        DataProcessorModuleStorage storage ms = moduleStorage();
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

    /// @inheritdoc IDataProcessorModule
    function authenticateDataProcessorTaskExecution(
        MmrData[] calldata mmrData,
        uint256 taskMerkleRootLow,
        uint256 taskMerkleRootHigh,
        uint256 resultMerkleRootLow,
        uint256 resultMerkleRootHigh,
        TaskData[] calldata taskData
    ) external {
        DataProcessorModuleStorage storage ms = moduleStorage();

        // Initialize an array of uint256 to store the program output
        uint256[] memory programOutput = new uint256[](4 + mmrData.length * 4);

        // Assign values to the program output array
        // This needs to be compatible with cairo program
        // https://github.com/HerodotusDev/hdp-cairo/blob/main/src/utils/utils.cairo#L27-L48
        programOutput[0] = resultMerkleRootLow;
        programOutput[1] = resultMerkleRootHigh;
        programOutput[2] = taskMerkleRootLow;
        programOutput[3] = taskMerkleRootHigh;

        for (uint8 i = 0; i < mmrData.length; i++) {
            MmrData memory mmr = mmrData[i];
            bytes32 usedMmrRoot = loadMmrRoot(mmr.mmrId, mmr.mmrSize, mmr.chainId);
            programOutput[4 + i * 4] = mmr.mmrId;
            programOutput[4 + i * 4 + 1] = mmr.mmrSize;
            programOutput[4 + i * 4 + 2] = mmr.chainId;
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
        for (uint256 i = 0; i < taskData.length; i++) {
            TaskData memory task = taskData[i];

            // Convert the low and high 128 bits to a single 256 bit value
            bytes32 resultMerkleRoot = bytes32((resultMerkleRootHigh << 128) | resultMerkleRootLow);
            bytes32 taskMerkleRoot = bytes32((taskMerkleRootHigh << 128) | taskMerkleRootLow);

            // Compute the Merkle leaf of the task
            bytes32 taskMerkleLeaf = standardEvmHDPLeafHash(task.commitment);
            // Ensure that the task is included in the batch, by verifying the Merkle proof
            bool isVerifiedTask = task.taskInclusionProof.verify(taskMerkleRoot, taskMerkleLeaf);

            if (!isVerifiedTask) {
                revert NotInBatch();
            }

            // Compute the Merkle leaf of the task result
            bytes32 taskResultCommitment = keccak256(abi.encode(task.commitment, task.result));
            bytes32 taskResultMerkleLeaf = standardEvmHDPLeafHash(taskResultCommitment);

            // Ensure that the task result is included in the batch, by verifying the Merkle proof
            bool isVerifiedResult = task.resultInclusionProof.verify(resultMerkleRoot, taskResultMerkleLeaf);

            if (!isVerifiedResult) {
                revert NotInBatch();
            }

            // Store the task result
            ms.cachedTasksResult[task.commitment] = TaskResult({status: TaskStatus.FINALIZED, result: task.result});
        }
    }

    // ========================= View Functions ========================= //

    /// @inheritdoc IDataProcessorModule
    function getDataProcessorFinalizedTaskResult(bytes32 taskCommitment) external view returns (bytes32) {
        DataProcessorModuleStorage storage ms = moduleStorage();
        // Ensure task is finalized
        if (ms.cachedTasksResult[taskCommitment].status != TaskStatus.FINALIZED) {
            revert NotFinalized();
        }
        return ms.cachedTasksResult[taskCommitment].result;
    }

    /// @inheritdoc IDataProcessorModule
    function getDataProcessorTaskStatus(bytes32 taskCommitment) external view returns (TaskStatus) {
        DataProcessorModuleStorage storage ms = moduleStorage();
        return ms.cachedTasksResult[taskCommitment].status;
    }

    // ========================= Internal Functions ========================= //

    /// @notice Load MMR root from cache with given mmrId and mmrSize
    function loadMmrRoot(uint256 mmrId, uint256 mmrSize, uint256 chainId) internal view returns (bytes32) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.mmrs[chainId][mmrId][POSEIDON_HASHING_FUNCTION].mmrSizeToRoot[mmrSize];
    }

    /// @notice Returns the leaf of standard merkle tree
    function standardEvmHDPLeafHash(bytes32 value) internal pure returns (bytes32) {
        bytes32 firstHash = keccak256(abi.encode(value));
        bytes32 leaf = keccak256(abi.encode(firstHash));
        return leaf;
    }
}
