// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "interfaces/ISatellite.sol";
import {ISatelliteRegistryModule} from "interfaces/modules/ISatelliteRegistryModule.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";

contract SatelliteRegistryModule is ISatelliteRegistryModule {
    function registerSatellite(uint256 chainId, address satellite, address crossDomainCounterpart) external {
        LibSatellite.enforceIsContractOwner();

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        s.satelliteRegistry[chainId] = satellite;
        s.crossDomainMsgSenders[crossDomainCounterpart] = true;
    }

    function removeSatellite(uint256 chainId, address satellite, address crossDomainCounterpart) external {
        LibSatellite.enforceIsContractOwner();

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        require(s.satelliteRegistry[chainId] == satellite, "SatelliteRegistry: satellite not registered");
        delete s.satelliteRegistry[chainId];
        delete s.crossDomainMsgSenders[crossDomainCounterpart];
    }

    function getSatellite(uint256 chainId) external view returns (address) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.satelliteRegistry[chainId];
    }
}
