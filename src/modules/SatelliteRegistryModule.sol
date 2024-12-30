// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "interfaces/ISatellite.sol";
import {ISatelliteRegistryModule} from "interfaces/modules/ISatelliteRegistryModule.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";

contract SatelliteRegistryModule is ISatelliteRegistryModule {
    function registerSatellite(uint256 chainId, address satellite, address crossDomainCounterpart) external {
        LibSatellite.enforceIsContractOwner();
        require(satellite != address(0), "SatelliteRegistry: invalid satellite");

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        require(s.satelliteRegistry[chainId] == address(0), "SatelliteRegistry: satellite already registered");
        s.satelliteRegistry[chainId] = satellite;

        if (crossDomainCounterpart != address(0)) {
            require(!s.crossDomainMsgSenders[crossDomainCounterpart], "SatelliteRegistry: crossDomainCounterpart already registered");
            s.crossDomainMsgSenders[crossDomainCounterpart] = true;
        }
    }

    function removeSatellite(uint256 chainId, address satellite, address crossDomainCounterpart) external {
        LibSatellite.enforceIsContractOwner();

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        require(s.satelliteRegistry[chainId] == satellite, "SatelliteRegistry: satellite not registered");
        delete s.satelliteRegistry[chainId];
        if(crossDomainCounterpart != address(0)) {
            delete s.crossDomainMsgSenders[crossDomainCounterpart];
        }
    }

    function getSatellite(uint256 chainId) external view returns (address) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.satelliteRegistry[chainId];
    }
}
