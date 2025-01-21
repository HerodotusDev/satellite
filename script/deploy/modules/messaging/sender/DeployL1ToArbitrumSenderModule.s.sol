// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {L1ToArbitrumSenderModule} from "src/modules/messaging/sender/L1ToArbitrumSenderModule.sol";

contract DeployL1ToArbitrumSenderModule is IDeploy {
    string contractName = "L1ToArbitrumSenderModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());

        L1ToArbitrumSenderModule module = new L1ToArbitrumSenderModule();

        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
