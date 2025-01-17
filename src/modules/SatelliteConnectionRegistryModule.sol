// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "interfaces/ISatellite.sol";
import {ISatelliteConnectionRegistryModule} from "interfaces/modules/ISatelliteConnectionRegistryModule.sol";
import {ILibSatellite} from "interfaces/ILibSatellite.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";

contract SatelliteConnectionRegistryModule is ISatelliteConnectionRegistryModule {
    /// @notice Satellite Connection Registry is responsible for storing information about chains to which message can be sent and from which message can be received
    /// @param chainId - chain id of other side of the connection
    /// @param satellite - address of the satellite deployed on `chainId`
    /// @param inbox - address of the contract deployed on our chain responsible for sending message to `chainId`
    /// @dev message can be sent to `chainId` if and only if `inbox` is set to non-zero address
    /// @param senderSatelliteAlias - (aliased) address of the satellite deployed on `chainId` that sends message to our chain
    /// @dev message can be received from `chainId` if and only if `senderSatelliteAlias` is set to non-zero address
    /// @param sendMessageSelector - selector of the function responsible for sending message to `chainId`, this function should be part of `messaging/sender/*.sol`
    function registerSatelliteConnection(uint256 chainId, address satellite, address inbox, address senderSatelliteAlias, bytes4 sendMessageSelector) external {
        LibSatellite.enforceIsContractOwner();
        require(satellite != address(0), "SatelliteConnectionRegistry: invalid satellite");

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        require(s.SatelliteConnectionRegistry[chainId].satelliteAddress == address(0), "SatelliteConnectionRegistry: satellite already registered");
        s.SatelliteConnectionRegistry[chainId] = ILibSatellite.SatelliteConnection(satellite, inbox, sendMessageSelector);

        if (senderSatelliteAlias != address(0)) {
            require(!s.senderSatellites[senderSatelliteAlias], "SatelliteConnectionRegistry: crossDomainCounterpart already registered");
            s.senderSatellites[senderSatelliteAlias] = true;
        }
    }

    function removeSatelliteConnection(uint256 chainId, address crossDomainCounterpart) external {
        LibSatellite.enforceIsContractOwner();

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        delete s.SatelliteConnectionRegistry[chainId];
        if (crossDomainCounterpart != address(0)) {
            delete s.senderSatellites[crossDomainCounterpart];
        }
    }

    function getSatelliteConnection(uint256 chainId) external view returns (ILibSatellite.SatelliteConnection memory) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.SatelliteConnectionRegistry[chainId];
    }
}
