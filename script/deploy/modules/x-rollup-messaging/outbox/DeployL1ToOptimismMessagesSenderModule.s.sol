// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {L1ToOptimismMessagesSenderModule} from "src/modules/x-rollup-messaging/outbox/L1ToOptimismMessagesSenderModule.sol";

contract DeployL1ToOptimismMessagesSenderModule is IDeploy {
    string contractName = "L1ToOptimismMessagesSenderModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());

        L1ToOptimismMessagesSenderModule module = new L1ToOptimismMessagesSenderModule();

        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
