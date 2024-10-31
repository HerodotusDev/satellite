// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {NativeOnChainGrowingModule} from "src/modules/growing/NativeOnChainGrowingModule.sol";

contract DeployNativeOnChainGrowingModule is IDeploy {
    string contractName = "NativeOnChainGrowingModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());
        NativeOnChainGrowingModule module = new NativeOnChainGrowingModule();
        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
