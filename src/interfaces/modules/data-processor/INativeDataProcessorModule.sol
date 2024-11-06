// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {IFactsRegistry} from "interfaces/external/IFactsRegistry.sol";
import {ModuleTask} from "libraries/internal/data-processor/ModuleCodecs.sol";
import {IFactsRegistryCommon} from "interfaces/modules/common/IFactsRegistryCommon.sol";

interface INativeDataProcessorModule is IFactsRegistryCommon {
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
    function setProgramHash(bytes32 programHash) external;

    /// @notice Requests the execution of a task with a module
    /// @param moduleTask module task
    function requestExecutionOfModuleTask(ModuleTask calldata moduleTask) external;

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
    ) external;

    /// @notice Returns the result of a finalized task
    function getFinalizedTaskResult(bytes32 taskCommitment) external view returns (bytes32);

    /// @notice Returns the status of a task
    function getTaskStatus(bytes32 taskCommitment) external view returns (TaskStatus);

    /// @notice Returns the leaf of standard merkle tree
    function standardLeafHash(bytes32 value) external pure returns (bytes32);
}
