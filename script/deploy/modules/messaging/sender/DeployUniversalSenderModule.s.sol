// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {UniversalSenderModule} from "src/modules/messaging/sender/UniversalSenderModule.sol";

contract DeployUniversalSenderModule is IDeploy {
    string contractName = "UniversalSenderModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());

        UniversalSenderModule module = new UniversalSenderModule();

        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
