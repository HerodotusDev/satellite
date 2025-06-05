// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {LibSatellite} from "src/libraries/LibSatellite.sol";
import {ISatellite} from "src/interfaces/ISatellite.sol";
import {RootForHashingFunction} from "src/interfaces/modules/IMmrCoreModule.sol";
import {AbstractReceiverModule} from "./AbstractReceiverModule.sol";

/// @notice Implementation of the receiver module for chains that use aliased address as message sender for cross-chain communication
contract SimpleReceiverModule is AbstractReceiverModule {
    function isCrossdomainCounterpart() internal view override returns (bool) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.senderSatellites[msg.sender];
    }
}
