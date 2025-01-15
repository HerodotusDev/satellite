// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ILibSatellite} from "interfaces/ILibSatellite.sol";

interface ISatelliteRegistryModule {
    function registerSatellite(
        uint256 chainId,
        address satellite,
        address inbox,
        address crossDomainCounterpart, 
        bytes4 sendMessageSelector
    ) external;

    function removeSatellite(uint256 chainId, address crossDomainCounterpart) external;
    function getSatellite(uint256 chainId) external view returns (ILibSatellite.SatelliteInfo memory);
}
