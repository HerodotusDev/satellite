// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {IFactsRegistryCommon} from "./IFactsRegistryCommon.sol";

interface ISharpMmrGrowingCommon is IFactsRegistryCommon {
    // Custom errors for better error handling and clarity
    error NotEnoughJobs();
    error UnknownParentHash();
    error AggregationError(string message); // Generic error with a message
    error AggregationBlockMismatch(string message);
    error GenesisBlockReached();
}
