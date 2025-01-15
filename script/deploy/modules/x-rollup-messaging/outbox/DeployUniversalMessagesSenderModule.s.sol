// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {UniversalMessagesSenderModule} from "src/modules/x-rollup-messaging/outbox/UniversalMessagesSenderModule.sol";

contract DeployUniversalMessagesSenderModule is IDeploy {
    string contractName = "UniversalMessagesSenderModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());

        UniversalMessagesSenderModule module = new UniversalMessagesSenderModule();

        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
