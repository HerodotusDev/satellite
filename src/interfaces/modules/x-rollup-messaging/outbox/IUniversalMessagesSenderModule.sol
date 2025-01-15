// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface IUniversalMessagesSenderModule {
    function sendParentHash(uint256 destinationChainId, uint256 accumulatedChainId, bytes32 hashingFunction, uint256 blockNumber, bytes calldata _xDomainMsgGasData) external payable;

    function sendMmr(uint256 destinationChainId, uint256 accumulatedChainId, uint256 originalMmrId, uint256 newMmrId, bytes32[] calldata hashingFunctions, bytes calldata _xDomainMsgGasData) external payable;
}
