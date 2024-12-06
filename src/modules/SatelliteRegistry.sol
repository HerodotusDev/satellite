// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "interfaces/ISatellite.sol";
import {ISatelliteRegistry} from "interfaces/modules/ISatelliteRegistry.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";

contract SatelliteRegistry is ISatelliteRegistry {
    function registerSatellite(uint256 chainId, address satellite) external {
        LibSatellite.enforceIsContractOwner();

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        s.satelliteRegistry[chainId] = satellite;
    }

    function getSatellite(uint256 chainId) external view returns (address) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.satelliteRegistry[chainId];
    }
}
