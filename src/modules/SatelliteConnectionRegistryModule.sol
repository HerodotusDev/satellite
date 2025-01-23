// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "src/interfaces/ISatellite.sol";
import {ISatelliteConnectionRegistryModule} from "src/interfaces/modules/ISatelliteConnectionRegistryModule.sol";
import {ILibSatellite} from "src/interfaces/ILibSatellite.sol";
import {LibSatellite} from "src/libraries/LibSatellite.sol";
import {AccessController} from "src/libraries/AccessController.sol";

/// @notice Satellite Connection Registry is responsible for storing information about chains to which message can be sent and from which message can be received
contract SatelliteConnectionRegistryModule is ISatelliteConnectionRegistryModule, AccessController {
    /// @inheritdoc ISatelliteConnectionRegistryModule
    function registerSatelliteConnection(uint256 chainId, address satellite, address inbox, address senderSatelliteAlias, bytes4 sendMessageSelector) external onlyOwner {
        require(satellite != address(0), "SatelliteConnectionRegistry: invalid satellite");

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        require(s.SatelliteConnectionRegistry[chainId].satelliteAddress == address(0), "SatelliteConnectionRegistry: satellite already registered");
        s.SatelliteConnectionRegistry[chainId] = ILibSatellite.SatelliteConnection(satellite, inbox, sendMessageSelector);

        if (senderSatelliteAlias != address(0)) {
            require(!s.senderSatellites[senderSatelliteAlias], "SatelliteConnectionRegistry: crossDomainCounterpart already registered");
            s.senderSatellites[senderSatelliteAlias] = true;
        }
    }

    /// @inheritdoc ISatelliteConnectionRegistryModule
    function removeSatelliteConnection(uint256 chainId, address crossDomainCounterpart) external onlyOwner {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        delete s.SatelliteConnectionRegistry[chainId];
        if (crossDomainCounterpart != address(0)) {
            delete s.senderSatellites[crossDomainCounterpart];
        }
    }

    /// @inheritdoc ISatelliteConnectionRegistryModule
    function getSatelliteConnection(uint256 chainId) external view returns (ILibSatellite.SatelliteConnection memory) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.SatelliteConnectionRegistry[chainId];
    }
}
