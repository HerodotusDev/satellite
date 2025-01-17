// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {LibSatellite} from "libraries/LibSatellite.sol";
import {ISatellite} from "interfaces/ISatellite.sol";
import {RootForHashingFunction} from "interfaces/modules/IMmrCoreModule.sol";
import {AbstractReceiverModule} from "./AbstractReceiverModule.sol";

contract SimpleReceiverModule is AbstractReceiverModule {
    function isCrossdomainCounterpart() internal view override returns (bool) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.senderSatellites[msg.sender];
    }
}
