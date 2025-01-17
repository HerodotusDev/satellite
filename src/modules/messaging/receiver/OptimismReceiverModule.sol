// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {LibSatellite} from "libraries/LibSatellite.sol";
import {ISatellite} from "interfaces/ISatellite.sol";
import {AbstractReceiverModule} from "./AbstractReceiverModule.sol";
import {IL1CrossDomainMessenger} from "interfaces/external/IOptimismCrossDomainMessenger.sol";

contract OptimismReceiverModule is AbstractReceiverModule {
    function isCrossdomainCounterpart() internal view override returns (bool) {
        IL1CrossDomainMessenger messenger = IL1CrossDomainMessenger(0x4200000000000000000000000000000000000007);

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return msg.sender == address(messenger) && s.crossDomainMsgSenders[messenger.xDomainMessageSender()];
    }
}
