// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "interfaces/ISatellite.sol";
import {ISatelliteConnectionRegistryModule} from "interfaces/modules/ISatelliteConnectionRegistryModule.sol";
import {ILibSatellite} from "interfaces/ILibSatellite.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";

contract SatelliteConnectionRegistryModule is ISatelliteConnectionRegistryModule {
    function registerSatelliteConnection(uint256 chainId, address satellite, address inbox, address crossDomainCounterpart, bytes4 sendMessageSelector) external {
        LibSatellite.enforceIsContractOwner();
        require(satellite != address(0), "SatelliteConnectionRegistry: invalid satellite");

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        require(s.SatelliteConnectionRegistry[chainId].satelliteAddress == address(0), "SatelliteConnectionRegistry: satellite already registered");
        s.SatelliteConnectionRegistry[chainId] = ILibSatellite.SatelliteConnection(satellite, inbox, sendMessageSelector);

        if (crossDomainCounterpart != address(0)) {
            require(!s.crossDomainMsgSenders[crossDomainCounterpart], "SatelliteConnectionRegistry: crossDomainCounterpart already registered");
            s.crossDomainMsgSenders[crossDomainCounterpart] = true;
        }
    }

    function removeSatelliteConnection(uint256 chainId, address crossDomainCounterpart) external {
        LibSatellite.enforceIsContractOwner();

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        delete s.SatelliteConnectionRegistry[chainId];
        if (crossDomainCounterpart != address(0)) {
            delete s.crossDomainMsgSenders[crossDomainCounterpart];
        }
    }

    function getSatelliteConnection(uint256 chainId) external view returns (ILibSatellite.SatelliteConnection memory) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.SatelliteConnectionRegistry[chainId];
    }
}
