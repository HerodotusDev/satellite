// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {IFactsRegistry} from "src/interfaces/external/IFactsRegistry.sol";
import {ModuleTask} from "src/libraries/internal/data-processor/ModuleCodecs.sol";
import {IFactsRegistryCommon} from "src/interfaces/modules/common/IFactsRegistryCommon.sol";

interface IDataProcessorModule is IFactsRegistryCommon {
    /// @notice The status of a task
    enum TaskStatus {
        NONE,
        SCHEDULED,
        FINALIZED
    }

    /// @notice The struct representing a task result
    struct TaskResult {
        TaskStatus status;
        bytes32 result;
    }

    /// @notice Storage structure for the module
    struct DataProcessorModuleStorage {
        IFactsRegistry factsRegistry;
        mapping(bytes32 => TaskResult) cachedTasksResult;
        mapping(bytes32 => bool) authorizedProgramHashes;
    }

    struct MmrData {
        uint256 chainId;
        uint256 mmrId;
        uint256 mmrSize;
    }

    /// @param mmrData For each used MMR, its chain ID, ID and size
    /// @param taskResultLow The low part of the task result
    /// @param taskResultHigh The high part of the task result
    /// @param taskHashLow The low part of the task hash
    /// @param taskHashHigh The high part of the task hash
    /// @param moduleHash The module hash that was used to compute the task
    /// @param programHash The program hash that was used to compute the task
    struct TaskData {
        MmrData[] mmrData;
        uint256 taskResultLow;
        uint256 taskResultHigh;
        uint256 taskHashLow;
        uint256 taskHashHigh;
        bytes32 moduleHash;
        bytes32 programHash;
    }

    /// @notice emitted when a task already stored
    event TaskAlreadyStored(bytes32 result);

    /// @notice emitted when a new module task is scheduled
    event ModuleTaskScheduled(ModuleTask moduleTask);

    /// Task is already registered
    error DoubleRegistration();
    /// Element is not in the batch
    error NotInBatch();
    /// Task is not finalized
    error NotFinalized();
    /// Unauthorized or inactive program hash
    error UnauthorizedProgramHash();
    /// Invalid MMR root
    error InvalidMmrRoot();
    /// Task is already finalized
    error TaskAlreadyFinalized();

    /// @notice Emitted when a task is finalized
    event TaskFinalized(bytes32 taskHash, bytes32 taskResult);

    /// @notice Emitted when a program hash is enabled
    event ProgramHashEnabled(bytes32 enabledProgramHash);

    /// @notice Emitted when some program hashes are disabled
    event ProgramHashesDisabled(bytes32[] disabledProgramHashes);

    /// @notice Set the program hash for the HDP program
    function setDataProcessorProgramHash(bytes32 programHash) external;

    /// @notice Disable some program hashes
    function disableProgramHashes(bytes32[] calldata programHashes) external;

    /// @notice Set the facts registry contract
    function setDataProcessorFactsRegistry(IFactsRegistry factsRegistry) external;

    /// @notice Requests the execution of a task with a module
    /// @param moduleTask module task
    function requestDataProcessorExecutionOfTask(ModuleTask calldata moduleTask) external;

    /// @notice Authenticates the execution of a task is finalized
    ///         by verifying the locally computed fact with the FactsRegistry
    /// @param taskData The task data
    function authenticateDataProcessorTaskExecution(TaskData calldata taskData) external;

    /// @notice Returns address of the facts registry
    function getDataProcessorFactsRegistry() external view returns (address);

    /// @notice Returns the result of a finalized task
    function getDataProcessorFinalizedTaskResult(bytes32 taskCommitment) external view returns (bytes32);

    /// @notice Returns the status of a task
    function getDataProcessorTaskStatus(bytes32 taskCommitment) external view returns (TaskStatus);

    /// @notice Checks if a program hash is currently authorized
    function isProgramHashAuthorized(bytes32 programHash) external view returns (bool);
}
