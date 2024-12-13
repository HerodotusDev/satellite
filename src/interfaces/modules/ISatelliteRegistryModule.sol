// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface ISatelliteRegistryModule {
    function registerSatellite(uint256 chainId, address satellite, address crossDomainCounterpart) external;
    function removeSatellite(uint256 chainId, address satellite, address crossDomainCounterpart) external;
    function getSatellite(uint256 chainId) external view returns (address);
}
