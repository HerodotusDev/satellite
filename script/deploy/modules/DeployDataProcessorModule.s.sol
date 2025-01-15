// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {IFactsRegistry} from "interfaces/external/IFactsRegistry.sol";

import {DataProcessorModule} from "src/modules/DataProcessorModule.sol";
import {MockFactsRegistry} from "src/mocks/MockFactsRegistry.sol";

contract DeployDataProcessorModule is IDeploy {
    string contractName = "DataProcessorModule";
    bytes32 programHash = bytes32(0x0);

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());
        DataProcessorModule module = new DataProcessorModule();
        vm.stopBroadcast();
        moduleAddress = address(module);
    }

    // TODO: we need a way to run some functions after adding to the diamond, some "initialization" standard

    function getFactsRegistryAddress() internal returns (address sharpFactsRegistryAddress) {
        address envSharpFactsRegistryAddress = vm.envAddress("SHARP_FACTS_REGISTRY_ADDRESS");
        if (envSharpFactsRegistryAddress != address(0)) {
            sharpFactsRegistryAddress = envSharpFactsRegistryAddress;
        } else {
            sharpFactsRegistryAddress = deployMockFactsRegistry();
        }
    }

    function deployMockFactsRegistry() internal returns (address mockFactsRegistryAddress) {
        vm.startBroadcast(getPrivateKey());
        MockFactsRegistry mockFactsRegistry = new MockFactsRegistry();
        vm.stopBroadcast();
        mockFactsRegistryAddress = address(mockFactsRegistry);
        console.log("MockFactsRegistry:", mockFactsRegistryAddress);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
