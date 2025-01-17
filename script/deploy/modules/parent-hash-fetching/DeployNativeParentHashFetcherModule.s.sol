// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {NativeParentHashFetcherModule} from "src/modules/parent-hash-fetching/NativeParentHashFetcherModule.sol";

contract DeployNativeParentHashFetcherModule is IDeploy {
    string contractName = "NativeParentHashFetcherModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());
        NativeParentHashFetcherModule module = new NativeParentHashFetcherModule();
        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
