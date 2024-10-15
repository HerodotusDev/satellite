// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {IDeployModule} from "script/deploy/interfaces/IDeployModule.sol";

import {NativeFactsRegistryModule} from "src/modules/NativeFactsRegistryModule.sol";

contract DeployNativeFactsRegistryModule is Script, IDeployModule {
    string contractName = "NativeFactsRegistryModule";

    function deploy() internal override returns (address moduleAddress) {
        NativeFactsRegistryModule module = new NativeFactsRegistryModule();
        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
