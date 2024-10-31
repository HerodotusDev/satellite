// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {NativeParentHashesFetcherModule} from "src/modules/x-rollup-messaging/parent-hashes-fetchers/NativeParentHashesFetcherModule.sol";

contract DeployNativeParentHashesFetcherModule is IDeploy {
    string contractName = "NativeParentHashesFetcherModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());
        NativeParentHashesFetcherModule module = new NativeParentHashesFetcherModule();
        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
