// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {SimpleReceiverModule} from "src/modules/messaging/receiver/SimpleReceiverModule.sol";

contract DeploySimpleReceiverModule is IDeploy {
    string contractName = "ReceiverModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());
        SimpleReceiverModule module = new SimpleReceiverModule();
        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
