// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "../interfaces/ISatellite.sol";
import {ISatelliteRegistryModule} from "../interfaces/modules/ISatelliteRegistryModule.sol";
import {ILibSatellite} from "../interfaces/ILibSatellite.sol";
import {LibSatellite} from "../libraries/LibSatellite.sol";
import {AccessController} from "../libraries/AccessController.sol";

/// @notice Satellite Registry is responsible for storing information about all other satellites and connections to them
contract SatelliteRegistryModule is ISatelliteRegistryModule, AccessController {
    /// @inheritdoc ISatelliteRegistryModule
    function registerSatellite(uint256 chainId, uint256 satelliteAddress, address inbox, bytes4 sendMessageSelector, address senderSatelliteAliased) external onlyOwner {
        if (satelliteAddress == 0) revert InvalidSatelliteAddress();
        // inbox == 0 means that satellite is non-connected, so sendMessageSelector must also be 0
        if (inbox == address(0) && sendMessageSelector != bytes4(0)) revert InvalidNonConnectedSatelliteParameters();
        bool canReceive = senderSatelliteAliased != address(0);

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        if (s.satelliteRegistry[chainId].satelliteAddress != 0) revert SatelliteAlreadyRegistered();
        s.satelliteRegistry[chainId] = ILibSatellite.SatelliteData(satelliteAddress, inbox, sendMessageSelector, canReceive);

        if (canReceive) {
            if (s.senderSatellites[senderSatelliteAliased]) revert SenderSatelliteAlreadyRegistered();
            s.senderSatellites[senderSatelliteAliased] = true;
        }

        emit SatelliteRegistered(chainId, satelliteAddress, inbox != address(0), senderSatelliteAliased);
    }

    /// @inheritdoc ISatelliteRegistryModule
    function removeSatellite(uint256 chainId, address crossDomainCounterpart) external onlyOwner {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        ILibSatellite.SatelliteData storage satellite = s.satelliteRegistry[chainId];
        if (satellite.satelliteAddress == 0) revert SatelliteNotRegistered();

        emit SatelliteRemoved(chainId, satellite.satelliteAddress);

        if (satellite.canReceive) {
            if (crossDomainCounterpart == address(0)) revert InvalidSenderSatelliteAddress();
            delete s.senderSatellites[crossDomainCounterpart];
        } else {
            if (crossDomainCounterpart != address(0)) revert InvalidSenderSatelliteAddress();
        }
        delete s.satelliteRegistry[chainId];
    }

    /// @inheritdoc ISatelliteRegistryModule
    function getSatellite(uint256 chainId) external view returns (ILibSatellite.SatelliteData memory) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.satelliteRegistry[chainId];
    }
}
