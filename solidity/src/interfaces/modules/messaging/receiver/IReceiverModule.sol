// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {RootForHashingFunction} from "../../IMmrCoreModule.sol";

/// @notice Receives messages from satellites deployed on other chains
interface IReceiverModule {
    function receiveParentHash(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes32 parentHash) external;

    function receiveMmr(
        uint256 newMmrId,
        RootForHashingFunction[] calldata rootsForHashingFunctions,
        uint256 mmrSize,
        uint256 accumulatedChainId,
        uint256 originChainId,
        uint256 originalMmrId,
        bool isSiblingSynced
    ) external;
}
