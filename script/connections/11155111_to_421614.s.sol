// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";

import {ContractsWithSelectors} from "script/helpers/ContractsWithSelectors.s.sol";
import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {ISatellite} from "interfaces/ISatellite.sol";

contract SetupL1 is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        
        address l1SatelliteAddress = vm.envAddress("SATELLITE_ADDRESS_11155111");
        address arbitrumSatelliteAddress = vm.envAddress("SATELLITE_ADDRESS_421614");
        address arbitrumInbox = vm.envAddress("SEPOLIA_ARBITRUM_INBOX");
        bytes4 selector = bytes4(keccak256("sendMessageL1ToArbitrum(address,address,bytes,bytes)"));

        ISatellite l1Satellite = ISatellite(l1SatelliteAddress);
        l1Satellite.registerSatellite(421614, arbitrumSatelliteAddress, arbitrumInbox, address(0x0), selector);
        
        vm.stopBroadcast();
    }
}

contract SetupArbitrum is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        
        address l1SatelliteAddress = vm.envAddress("SATELLITE_ADDRESS_11155111");
        address l1AliasedAddress = address(uint160(uint256(uint160(l1SatelliteAddress)) + uint256(uint160(0x1111000000000000000000000000000000001111))));
        address arbitrumSatelliteAddress = vm.envAddress("SATELLITE_ADDRESS_421614");

        ISatellite arbitrumSatellite = ISatellite(arbitrumSatelliteAddress);
        arbitrumSatellite.registerSatellite(11155111, l1SatelliteAddress, address(0x0), l1AliasedAddress, 0);
        
        vm.stopBroadcast();
    }
}