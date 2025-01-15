// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "interfaces/ISatellite.sol";
import {ISatelliteRegistryModule} from "interfaces/modules/ISatelliteRegistryModule.sol";
import {ILibSatellite} from "interfaces/ILibSatellite.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";

contract SatelliteRegistryModule is ISatelliteRegistryModule {
    function registerSatellite(
        uint256 chainId,
        address satellite,
        address inbox,
        address crossDomainCounterpart, 
        bytes4 sendMessageSelector
    ) external {
        LibSatellite.enforceIsContractOwner();
        require(satellite != address(0), "SatelliteRegistry: invalid satellite");

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        require(s.satelliteRegistry[chainId].satelliteAddress == address(0), "SatelliteRegistry: satellite already registered");
        s.satelliteRegistry[chainId] = ILibSatellite.SatelliteInfo(satellite, inbox, sendMessageSelector);

        if (crossDomainCounterpart != address(0)) {
            require(!s.crossDomainMsgSenders[crossDomainCounterpart], "SatelliteRegistry: crossDomainCounterpart already registered");
            s.crossDomainMsgSenders[crossDomainCounterpart] = true;
        }
    }

    function removeSatellite(uint256 chainId, address crossDomainCounterpart) external {
        LibSatellite.enforceIsContractOwner();

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        delete s.satelliteRegistry[chainId];
        if(crossDomainCounterpart != address(0)) {
            delete s.crossDomainMsgSenders[crossDomainCounterpart];
        }
    }

    function getSatellite(uint256 chainId) external view returns (ILibSatellite.SatelliteInfo memory) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.satelliteRegistry[chainId];
    }
}
