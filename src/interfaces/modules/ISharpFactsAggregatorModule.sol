// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Uint256Splitter} from "libraries/Uint256Splitter.sol";
import {IFactsRegistry} from "interfaces/external/IFactsRegistry.sol";

interface ISharpFactsAggregatorModule {
    // Representation of the Cairo program's output (raw unpacked)
    struct JobOutput {
        uint256 fromBlockNumberHigh;
        uint256 toBlockNumberLow;
        bytes32 blockNPlusOneParentHashLow;
        bytes32 blockNPlusOneParentHashHigh;
        bytes32 blockNMinusRPlusOneParentHashLow;
        bytes32 blockNMinusRPlusOneParentHashHigh;
        bytes32 mmrPreviousRootPoseidon;
        bytes32 mmrPreviousRootKeccakLow;
        bytes32 mmrPreviousRootKeccakHigh;
        uint256 mmrPreviousSize;
        bytes32 mmrNewRootPoseidon;
        bytes32 mmrNewRootKeccakLow;
        bytes32 mmrNewRootKeccakHigh;
        uint256 mmrNewSize;
    }

    // Packed representation of the Cairo program's output (for gas efficiency)
    struct JobOutputPacked {
        uint256 blockNumbersPacked;
        bytes32 blockNPlusOneParentHash;
        bytes32 blockNMinusRPlusOneParentHash;
        bytes32 mmrPreviousRootPoseidon;
        bytes32 mmrPreviousRootKeccak;
        bytes32 mmrNewRootPoseidon;
        bytes32 mmrNewRootKeccak;
        uint256 mmrSizesPacked;
    }

    event SharpFactsAggregate(
        uint256 firstAppendedBlock,
        uint256 lastAppendedBlock,
        uint256 newMmrSize,
        uint256 mmrId,
        bytes32 newPoseidonMmrRoot,
        bytes32 newKeccakMmrRoot,
        uint256 chainId
    );

    // Custom errors for better error handling and clarity
    error NotEnoughJobs();
    error UnknownParentHash();
    error AggregationError(string message); // Generic error with a message
    error AggregationBlockMismatch();
    error GenesisBlockReached();
    error InvalidFact();

    function aggregateSharpJobs(uint256 mmrId, uint256 fromBlockNumber, JobOutputPacked[] calldata outputs) external;
}
