// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {LibSatellite} from "src/libraries/LibSatellite.sol";
import {ISatellite} from "src/interfaces/ISatellite.sol";
import {AbstractReceiverModule} from "./AbstractReceiverModule.sol";
import {IL1CrossDomainMessenger} from "src/interfaces/external/IOptimismCrossDomainMessenger.sol";

/// @notice Implementation of the receiver module for Optimism
contract OptimismReceiverModule is AbstractReceiverModule {
    function isCrossdomainCounterpart() internal view override returns (bool) {
        /// @dev On Optimism, cross-chain messages always come from the same address (L1CrossDomainMessenger)
        ///      whose `xDomainMessageSender()` function should be called for retrieving the address of the sender
        IL1CrossDomainMessenger messenger = IL1CrossDomainMessenger(0x4200000000000000000000000000000000000007);

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return msg.sender == address(messenger) && s.senderSatellites[messenger.xDomainMessageSender()];
    }
}
