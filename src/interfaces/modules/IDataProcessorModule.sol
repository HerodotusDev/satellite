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
        bytes32 programHash;
        IFactsRegistry factsRegistry;
        mapping(bytes32 => TaskResult) cachedTasksResult;
    }

    struct MmrData {
        uint256 chainId;
        uint256 mmrId;
        uint256 mmrSize;
    }

    struct TaskData {
        /// @dev The Merkle proof of the task
        bytes32[] taskInclusionProof;
        /// @dev The Merkle proof of the result
        bytes32[] resultInclusionProof;
        /// @dev The commitment of the task
        bytes32 commitment;
        /// @dev The result of the computational task
        bytes32 result;
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

    /// @notice Set the program hash for the HDP program
    function setDataProcessorProgramHash(bytes32 programHash) external;

    /// @notice Set the facts registry contract
    function setDataProcessorFactsRegistry(IFactsRegistry factsRegistry) external;

    /// @notice Requests the execution of a task with a module
    /// @param moduleTask module task
    function requestDataProcessorExecutionOfTask(ModuleTask calldata moduleTask) external;

    /// @notice Authenticates the execution of a task is finalized
    ///     by verifying the FactRegistry and Merkle proofs
    /// @param mmrData The chain ID, MMR ID and MMR size
    /// @param taskMerkleRootLow The low 128 bits of the tasks Merkle root
    /// @param taskMerkleRootHigh The high 128 bits of the tasks Merkle root
    /// @param resultMerkleRootLow The low 128 bits of the results Merkle root
    /// @param resultMerkleRootHigh The high 128 bits of the results Merkle root
    /// @param taskData task and result inclusion proofs, commitments and results
    function authenticateDataProcessorTaskExecution(
        MmrData[] calldata mmrData,
        uint256 taskMerkleRootLow,
        uint256 taskMerkleRootHigh,
        uint256 resultMerkleRootLow,
        uint256 resultMerkleRootHigh,
        TaskData[] calldata taskData
    ) external;

    /// @notice Returns the result of a finalized task
    function getDataProcessorFinalizedTaskResult(bytes32 taskCommitment) external view returns (bytes32);

    /// @notice Returns the status of a task
    function getDataProcessorTaskStatus(bytes32 taskCommitment) external view returns (TaskStatus);
}
