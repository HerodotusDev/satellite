// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeployModule} from "script/deploy/interfaces/IDeployModule.sol";

import {IFactsRegistry} from "interfaces/external/IFactsRegistry.sol";

import {SharpFactsAggregatorModule} from "src/modules/SharpFactsAggregatorModule.sol";
import {MockFactsRegistry} from "src/mocks/MockFactsRegistry.sol";

contract DeploySharpFactsAggregatorModule is IDeployModule {
    string contractName = "SharpFactsAggregatorModule";

    function deploy() internal override returns (address moduleAddress) {
        IFactsRegistry sharpFactsRegistry = IFactsRegistry(getFactsRegistryAddress());
        vm.startBroadcast(getPrivateKey());
        SharpFactsAggregatorModule module = new SharpFactsAggregatorModule(sharpFactsRegistry);
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
