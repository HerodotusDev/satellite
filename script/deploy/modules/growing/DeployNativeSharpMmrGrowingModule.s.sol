// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {NativeSharpMmrGrowingModule} from "src/modules/growing/NativeSharpMmrGrowingModule.sol";
import {MockFactsRegistry} from "src/mocks/MockFactsRegistry.sol";

contract DeployNativeSharpMmrGrowingModule is IDeploy {
    string contractName = "NativeSharpMmrGrowingModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());
        NativeSharpMmrGrowingModule module = new NativeSharpMmrGrowingModule();
        // TODO: initNativeSharpMmrGrowingModule
        vm.stopBroadcast();
        moduleAddress = address(module);
    }

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
