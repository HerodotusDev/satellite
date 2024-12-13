// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {SimpleInboxModule} from "src/modules/x-rollup-messaging/inbox/SimpleInboxModule.sol";

contract DeploySimpleInboxModule is IDeploy {
    string contractName = "SimpleInboxModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());
        SimpleInboxModule module = new SimpleInboxModule();
        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
