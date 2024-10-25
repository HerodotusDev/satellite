// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {MMRsCoreModule} from "src/modules/MMRsCoreModule.sol";

contract DeployMMRsCoreModule is IDeploy {
    string contractName = "MMRsCoreModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());
        MMRsCoreModule module = new MMRsCoreModule();
        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
