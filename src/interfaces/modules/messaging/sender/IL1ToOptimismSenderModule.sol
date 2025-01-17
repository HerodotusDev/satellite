// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface IL1ToOptimismSenderModule {
    function sendMessageL1ToOptimism(address satelliteAddress, address inboxAddress, bytes memory _data, bytes memory _xDomainMsgGasData) external payable;
}
