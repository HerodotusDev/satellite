// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {LibSatellite} from "../../../libraries/LibSatellite.sol";
import {IOptimismCrossDomainMessenger} from "../../../interfaces/external/IOptimismCrossDomainMessenger.sol";
import {IL1ToOptimismSenderModule} from "../../../interfaces/modules/messaging/sender/IL1ToOptimismSenderModule.sol";
import {AccessController} from "../../../libraries/AccessController.sol";

contract L1ToOptimismSenderModule is IL1ToOptimismSenderModule, AccessController {
    /// @inheritdoc IL1ToOptimismSenderModule
    function sendMessageL1ToOptimism(uint256 satelliteAddress, address inboxAddress, bytes memory _data, bytes memory _xDomainMsgGasData) external payable onlyModule {
        IOptimismCrossDomainMessenger optimismMessenger = IOptimismCrossDomainMessenger(inboxAddress);
        uint32 l2GasLimit = abi.decode(_xDomainMsgGasData, (uint32));

        optimismMessenger.sendMessage{value: msg.value}(address(uint160(satelliteAddress)), _data, l2GasLimit);
    }
}
