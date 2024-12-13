// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {SatelliteRegistryModule} from "src/modules/SatelliteRegistryModule.sol";

contract DeploySatelliteRegistryModule is IDeploy {
    string contractName = "SatelliteRegistryModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());
        SatelliteRegistryModule module = new SatelliteRegistryModule();
        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
