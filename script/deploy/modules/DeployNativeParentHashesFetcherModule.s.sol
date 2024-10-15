// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {IDeployModule} from "script/deploy/interfaces/IDeployModule.sol";

import {NativeParentHashesFetcherModule} from "src/modules/x-rollup-messaging/parent-hashes-fetchers/NativeParentHashesFetcherModule.sol";

contract DeployNativeParentHashesFetcherModule is Script, IDeployModule {
    string contractName = "NativeParentHashesFetcherModule";

    function deploy() internal override returns (address moduleAddress) {
        NativeParentHashesFetcherModule module = new NativeParentHashesFetcherModule();
        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
