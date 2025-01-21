// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {SatelliteConnectionRegistryModule} from "src/modules/SatelliteConnectionRegistryModule.sol";

contract DeploySatelliteConnectionRegistryModule is IDeploy {
    string contractName = "SatelliteConnectionRegistryModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());
        SatelliteConnectionRegistryModule module = new SatelliteConnectionRegistryModule();
        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
