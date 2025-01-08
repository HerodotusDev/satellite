// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {IStarknet} from "interfaces/external/IStarknet.sol";

import {StarknetParentHashFetcherModule} from "src/modules/x-rollup-messaging/parent-hash-fetcher/StarknetParentHashFetcherModule.sol";
import {MockStarknetCore} from "src/mocks/MockStarknetCore.sol";

contract DeployStarknetParentHashFetcherModule is IDeploy {
    string contractName = "StarknetParentHashFetcherModule";

    function deploy() internal override returns (address moduleAddress) {
        IStarknet starknetCore = IStarknet(getStarknetCoreAddress());
        vm.startBroadcast(getPrivateKey());
        StarknetParentHashFetcherModule module = new StarknetParentHashFetcherModule(starknetCore, getStarknetChainId());
        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getStarknetCoreAddress() internal returns (address starknetCoreAddress) {
        address envStarknetCoreAddress = vm.envAddress("STARKNET_CORE_ADDRESS");

        if (envStarknetCoreAddress != address(0)) starknetCoreAddress = envStarknetCoreAddress;
        else starknetCoreAddress = deployMockStarknetCore();
    }

    function deployMockStarknetCore() internal returns (address mockStarknetCoreAddress) {
        vm.startBroadcast(getPrivateKey());
        MockStarknetCore mockFactsRegistry = new MockStarknetCore();
        vm.stopBroadcast();
        mockStarknetCoreAddress = address(mockFactsRegistry);
        console.log("MockStarknetCore:", mockStarknetCoreAddress);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
