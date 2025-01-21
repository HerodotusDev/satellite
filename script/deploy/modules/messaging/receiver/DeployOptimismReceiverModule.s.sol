// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {OptimismReceiverModule} from "src/modules/messaging/receiver/OptimismReceiverModule.sol";

contract DeployOptimismReceiverModule is IDeploy {
    string contractName = "ReceiverModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());
        OptimismReceiverModule module = new OptimismReceiverModule();
        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
