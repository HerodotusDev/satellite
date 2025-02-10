// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {LibSatellite} from "src/libraries/LibSatellite.sol";
import {IZkSyncMailbox} from "src/interfaces/external/IZkSyncMailbox.sol";
import {IL1ToZkSyncSenderModule} from "src/interfaces/modules/messaging/sender/IL1ToZkSyncSenderModule.sol";
import {AccessController} from "src/libraries/AccessController.sol";
contract L1ToZkSyncSenderModule is IL1ToZkSyncSenderModule, AccessController {
    /// @inheritdoc IL1ToZkSyncSenderModule
    function sendMessageL1ToZkSync(uint256 satelliteAddress, address inboxAddress, bytes memory _data, bytes memory _xDomainMsgGasData) external payable onlyModule {
        IZkSyncMailbox zkSyncMailbox = IZkSyncMailbox(inboxAddress);
        (uint256 l2GasLimit, uint256 l2GasPerPubdataByteLimit) = abi.decode(_xDomainMsgGasData, (uint256, uint256));

        zkSyncMailbox.requestL2Transaction{value: msg.value}(address(uint160(satelliteAddress)), 0, _data, l2GasLimit, l2GasPerPubdataByteLimit, new bytes[](0), msg.sender);
    }
}
