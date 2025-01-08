// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {EVMFactRegistryModule} from "src/modules/EVMFactRegistryModule.sol";

contract DeployEVMFactRegistryModule is IDeploy {
    string contractName = "EVMFactRegistryModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());
        EVMFactRegistryModule module = new EVMFactRegistryModule();
        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
