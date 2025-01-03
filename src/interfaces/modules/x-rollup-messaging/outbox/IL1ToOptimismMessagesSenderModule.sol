// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface IL1ToOptimismMessagesSenderModule {
    function configureL1ToOptimism(address optimismCrossDomainMessenger, address optimismSatellite) external;
    function sendParentHashL1ToOptimism(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes calldata _xDomainMsgGasData) external payable;
    function sendMmrL1ToOptimism(uint256 accumulatedChainId, uint256 originalMmrId, uint256 newMmrId, bytes32[] calldata hashingFunctions, bytes calldata _xDomainMsgGasData) external payable;
}
