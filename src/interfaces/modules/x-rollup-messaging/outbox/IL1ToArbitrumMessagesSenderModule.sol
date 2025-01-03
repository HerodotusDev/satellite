// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface IL1ToArbitrumMessagesSenderModule {
    /// @notice Set the messenger and satellite addresses
    /// @param arbitrumInbox address of contract that send messages, e.g. ArbitrumInbox or OptimismCrossDomainMessenger
    /// @param arbitrumSatellite address of Satellite contract deployed on destination chain
    function configureL1ToArbitrum(address arbitrumInbox, address arbitrumSatellite) external;

    function sendParentHashL1ToArbitrum(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes calldata _xDomainMsgGasData) external payable;
    function sendMmrL1ToArbitrum(uint256 accumulatedChainId, uint256 originalMmrId, uint256 newMmrId, bytes32[] calldata hashingFunctions, bytes calldata _xDomainMsgGasData) external payable;
}
