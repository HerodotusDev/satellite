// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {L1ToOptimismSenderModule} from "src/modules/messaging/sender/L1ToOptimismSenderModule.sol";

contract DeployL1ToOptimismSenderModule is IDeploy {
    string contractName = "L1ToOptimismSenderModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());

        L1ToOptimismSenderModule module = new L1ToOptimismSenderModule();

        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
