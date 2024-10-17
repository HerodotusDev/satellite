// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeployModule} from "script/deploy/interfaces/IDeployModule.sol";

import {IFactsRegistry} from "interfaces/external/IFactsRegistry.sol";

import {NativeSharpMmrGrowingModule} from "src/modules/NativeSharpMmrGrowingModule.sol";
import {MockFactsRegistry} from "src/mocks/MockFactsRegistry.sol";

contract DeployNativeSharpMmrGrowingModule is IDeployModule {
    string contractName = "NativeSharpMmrGrowingModule";

    function deploy() internal override returns (address moduleAddress) {
        IFactsRegistry sharpFactsRegistry = IFactsRegistry(getFactsRegistryAddress());
        vm.startBroadcast(getPrivateKey());
        NativeSharpMmrGrowingModule module = new NativeSharpMmrGrowingModule(sharpFactsRegistry);
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
