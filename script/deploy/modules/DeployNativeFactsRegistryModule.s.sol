// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {NativeFactsRegistryModule} from "src/modules/NativeFactsRegistryModule.sol";

contract DeployNativeFactsRegistryModule is IDeploy {
    string contractName = "NativeFactsRegistryModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());
        NativeFactsRegistryModule module = new NativeFactsRegistryModule();
        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
