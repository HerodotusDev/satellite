// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {NativeBlockHashFetcherModule} from "src/modules/block-hash-fetching/NativeBlockHashFetcherModule.sol";

contract DeployNativeBlockHashFetcherModule is IDeploy {
    string contractName = "NativeBlockHashFetcherModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());
        NativeBlockHashFetcherModule module = new NativeBlockHashFetcherModule();
        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
