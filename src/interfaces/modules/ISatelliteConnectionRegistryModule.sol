// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ILibSatellite} from "interfaces/ILibSatellite.sol";

interface ISatelliteConnectionRegistryModule {
    function registerSatelliteConnection(uint256 chainId, address satellite, address inbox, address crossDomainCounterpart, bytes4 sendMessageSelector) external;

    function removeSatelliteConnection(uint256 chainId, address crossDomainCounterpart) external;
    function getSatelliteConnection(uint256 chainId) external view returns (ILibSatellite.SatelliteConnection memory);
}
