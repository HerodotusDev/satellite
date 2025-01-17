// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface IL1ToOptimismSenderModule {
    /// @notice Send message from L1 to Arbitrum
    /// @param satelliteAddress the address of the satellite on Arbitrum
    /// @param inboxAddress the address of the Arbitrum Inbox
    /// @dev inboxAddress - L1CrossDomainMessengerProxy in https://docs.optimism.io/chain/addresses
    function sendMessageL1ToOptimism(address satelliteAddress, address inboxAddress, bytes memory _data, bytes memory _xDomainMsgGasData) external payable;
}
