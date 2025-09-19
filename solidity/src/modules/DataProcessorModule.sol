// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ICairoFactRegistryModule} from "../interfaces/modules/ICairoFactRegistryModule.sol";
import {ISatellite} from "../interfaces/ISatellite.sol";
import {LibSatellite} from "../libraries/LibSatellite.sol";
import {ModuleTask, ModuleCodecs} from "../libraries/internal/data-processor/ModuleCodecs.sol";
import {IDataProcessorModule} from "../interfaces/modules/IDataProcessorModule.sol";
import {AccessController} from "../libraries/AccessController.sol";

/// @title DataProcessorModule
/// @author Herodotus Dev Ltd
/// @notice A contract to store the execution results of HDP tasks
contract DataProcessorModule is IDataProcessorModule, AccessController {
    // ========================= Types ========================= //

    using MerkleProof for bytes32[];
    using ModuleCodecs for ModuleTask;

    // ========================= Constants ========================= //

    bytes32 constant POSEIDON_HASHING_FUNCTION = keccak256("poseidon");
    bytes32 constant KECCAK_HASHING_FUNCTION = keccak256("keccak");


    // ========================= Satellite Module Storage ========================= //

    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.satellite.module.storage.data-processor");

    function moduleStorage() internal pure returns (DataProcessorModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // ========================= Setup Functions ========================= //

    /// @inheritdoc IDataProcessorModule
    function setDataProcessorProgramHash(bytes32 programHash) external onlyOwner {
        DataProcessorModuleStorage storage ms = moduleStorage();
        ms.authorizedProgramHashes[programHash] = true;
        emit ProgramHashEnabled(programHash);
    }

    /// @inheritdoc IDataProcessorModule
    function disableProgramHashes(bytes32[] calldata programHashes) external onlyOwner {
        DataProcessorModuleStorage storage ms = moduleStorage();

        for (uint256 i = 0; i < programHashes.length; i++) {
            ms.authorizedProgramHashes[programHashes[i]] = false;
        }
        emit ProgramHashesDisabled(programHashes);
    }

    /// @inheritdoc IDataProcessorModule
    function isProgramHashAuthorized(bytes32 programHash) public view returns (bool) {
        DataProcessorModuleStorage storage ms = moduleStorage();
        return ms.authorizedProgramHashes[programHash];
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
    function authenticateDataProcessorTaskExecution(TaskData calldata taskData) external {
        DataProcessorModuleStorage storage ms = moduleStorage();

        require(taskData.taskHashLow >> 128 == 0, "INVALID taskHashLow");
        require(taskData.taskHashHigh >> 128 == 0, "INVALID taskHashHigh");
        bytes32 taskHash = bytes32((taskData.taskHashHigh << 128) | taskData.taskHashLow);

        if (ms.cachedTasksResult[taskHash].status == TaskStatus.FINALIZED) {
            revert TaskAlreadyFinalized();
        }

        if (!isProgramHashAuthorized(taskData.programHash)) {
            revert UnauthorizedProgramHash();
        }

        // Initialize an array of uint256 to store the program output
        uint256[] memory programOutput = new uint256[](
            6 + taskData.mmrCollection.poseidonMmr.length * 4 
            + taskData.mmrCollection.keccakMmr.length * 5
        );

        // Assign values to the program output array
        // This needs to be compatible with cairo program
        // https://github.com/HerodotusDev/hdp-cairo/blob/main/src/utils/utils.cairo#L27-L48
        programOutput[0] = taskData.taskHashLow;
        programOutput[1] = taskData.taskHashHigh;
        programOutput[2] = taskData.taskResultLow;
        programOutput[3] = taskData.taskResultHigh;
        programOutput[4] = taskData.mmrCollection.poseidonMmr.length;
        programOutput[5] = taskData.mmrCollection.keccakMmr.length;

        // Proccess Poseidon MMRs 
        for (uint8 i = 0; i < taskData.mmrCollection.poseidonMmr.length; i++) {
            MmrData memory mmr = taskData.mmrCollection.poseidonMmr[i];
            bytes32 usedMmrRoot = LibSatellite.satelliteStorage().mmrs[mmr.chainId][mmr.mmrId][POSEIDON_HASHING_FUNCTION].mmrSizeToRoot[mmr.mmrSize];
            if (usedMmrRoot == bytes32(0)) {
                revert InvalidMmrRoot();
            }
            programOutput[4 + i * 4] = mmr.mmrId;
            programOutput[4 + i * 4 + 1] = mmr.mmrSize;
            programOutput[4 + i * 4 + 2] = mmr.chainId;
            programOutput[4 + i * 4 + 3] = uint256(usedMmrRoot);
        }


         // Proccess Keccak MMRs 
        for (uint8 i = 0; i < taskData.mmrCollection.keccakMmr.length; i++) {
            MmrData memory mmr = taskData.mmrCollection.keccakMmr[i];
            bytes32 usedMmrRoot = LibSatellite.satelliteStorage().mmrs[mmr.chainId][mmr.mmrId][KECCAK_HASHING_FUNCTION].mmrSizeToRoot[mmr.mmrSize];
            if (usedMmrRoot == bytes32(0)) {
                revert InvalidMmrRoot();
            }

            uint256 usedMmrRootLow = uint256(uint128(uint256(usedMmrRoot)));
            uint256 usedMmrRootHigh = uint256(uint128(uint256(usedMmrRoot >> 128)));

            uint256 offset = 6 + taskData.mmrCollection.poseidonMmr.length*4;

            programOutput[offset + i * 5] = mmr.mmrId;
            programOutput[offset + i * 5 + 1] = mmr.mmrSize;
            programOutput[offset + i * 5 + 2] = mmr.chainId;
            programOutput[offset + i * 5 + 3] = uint256(usedMmrRootLow);
            programOutput[offset + i * 5 + 4] = uint256(usedMmrRootHigh);
        }

        // Compute program output hash
        bytes32 programOutputHash = keccak256(abi.encodePacked(programOutput));

        // Compute GPS fact hash
        bytes32 gpsFactHash = keccak256(abi.encode(taskData.programHash, programOutputHash));

        // Ensure GPS fact is registered
        if (!ICairoFactRegistryModule(address(this)).isCairoFactValidForInternal(gpsFactHash)) {
            revert InvalidFact();
        }

        require(taskData.taskResultHigh >> 128 == 0, "INVALID taskResultHigh");
        require(taskData.taskResultLow >> 128 == 0, "INVALID taskResultLow");
        bytes32 taskResult = bytes32((taskData.taskResultHigh << 128) | taskData.taskResultLow);

        // Store the task result
        ms.cachedTasksResult[taskHash] = TaskResult({status: TaskStatus.FINALIZED, result: taskResult});
        emit TaskFinalized(taskHash, taskResult);
    }

    /// @inheritdoc IDataProcessorModule
    function getDataProcessorTaskStatus(bytes32 taskCommitment) external view returns (TaskStatus) {
        DataProcessorModuleStorage storage ms = moduleStorage();
        return ms.cachedTasksResult[taskCommitment].status;
    }

    /// @inheritdoc IDataProcessorModule
    function getDataProcessorFinalizedTaskResult(bytes32 taskCommitment) external view returns (bytes32) {
        DataProcessorModuleStorage storage ms = moduleStorage();
        // Ensure task is finalized
        if (ms.cachedTasksResult[taskCommitment].status != TaskStatus.FINALIZED) {
            revert NotFinalized();
        }
        return ms.cachedTasksResult[taskCommitment].result;
    }
}
