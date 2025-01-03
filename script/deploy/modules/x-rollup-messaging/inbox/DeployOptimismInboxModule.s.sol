// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {OptimismInboxModule} from "src/modules/x-rollup-messaging/inbox/OptimismInboxModule.sol";

contract DeployOptimismInboxModule is IDeploy {
    string contractName = "InboxModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());
        OptimismInboxModule module = new OptimismInboxModule();
        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
