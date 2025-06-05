// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface IL1ToZkSyncSenderModule {
    /// @notice Send message from L1 to ZkSync
    /// @param satelliteAddress the address of the satellite on ZkSync
    /// @param inboxAddress the address of the ZkSync Inbox
    /// @dev inboxAddress - STM (official) address of ZkSync in https://docs.zksync.io/zk-stack/zk-chain-addresses
    function sendMessageL1ToZkSync(uint256 satelliteAddress, address inboxAddress, bytes memory _data, bytes memory _xDomainMsgGasData) external payable;
}
