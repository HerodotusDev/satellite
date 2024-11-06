// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {IFactsRegistry} from "interfaces/external/IFactsRegistry.sol";

import {NativeDataProcessorModule} from "src/modules/data-processor/NativeDataProcessorModule.sol";
import {MockFactsRegistry} from "src/mocks/MockFactsRegistry.sol";

contract DeployNativeDataProcessorModule is IDeploy {
    string contractName = "NativeDataProcessorModule";
    bytes32 programHash = bytes32(0x0);

    function deploy() internal override returns (address moduleAddress) {
        IFactsRegistry sharpFactsRegistry = IFactsRegistry(getFactsRegistryAddress());
        vm.startBroadcast(getPrivateKey());
        NativeDataProcessorModule module = new NativeDataProcessorModule(sharpFactsRegistry, programHash);
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
