// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface IL1ToArbitrumSenderModule {
    /// @notice Send message from L1 to Arbitrum
    /// @param satelliteAddress the address of the satellite on Arbitrum
    /// @param inboxAddress the address of the Arbitrum Inbox
    /// @dev inboxAddress - Delayed Inbox in https://docs.arbitrum.io/build-decentralized-apps/reference/contract-addresses
    function sendMessageL1ToArbitrum(address satelliteAddress, address inboxAddress, bytes memory _data, bytes memory _xDomainMsgGasData) external payable;
}
