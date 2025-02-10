// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface IL1ToStarknetSenderModule {
    /// @notice Send message from L1 to Starknet
    /// @param satelliteAddress the address of the satellite on Starknet
    /// @param inboxAddress the address of the Starknet Core
    function sendMessageL1ToStarknet(address satelliteAddress, address inboxAddress, bytes memory _data, bytes memory _xDomainMsgGasData) external payable;
}
