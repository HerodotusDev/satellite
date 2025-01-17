// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {LibSatellite} from "libraries/LibSatellite.sol";
import {IOptimismCrossDomainMessenger} from "interfaces/external/IOptimismCrossDomainMessenger.sol";
import {IL1ToOptimismSenderModule} from "interfaces/modules/messaging/sender/IL1ToOptimismSenderModule.sol";

contract L1ToOptimismSenderModule is IL1ToOptimismSenderModule {
    /// @inheritdoc IL1ToOptimismSenderModule
    function sendMessageL1ToOptimism(address satelliteAddress, address inboxAddress, bytes memory _data, bytes memory _xDomainMsgGasData) external payable {
        LibSatellite.enforceIsSatelliteModule();

        IOptimismCrossDomainMessenger optimismMessenger = IOptimismCrossDomainMessenger(inboxAddress);

        uint32 l2GasLimit = abi.decode(_xDomainMsgGasData, (uint32));
        optimismMessenger.sendMessage{value: msg.value}(satelliteAddress, _data, l2GasLimit);
    }
}
