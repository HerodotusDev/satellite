// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {L1ToArbitrumMessagesSenderModule} from "src/modules/x-rollup-messaging/outbox/L1ToArbitrumMessagesSenderModule.sol";
import {IArbitrumInbox} from "interfaces/external/IArbitrumInbox.sol";

contract DeployL1ToArbitrumMessagesSenderModule is IDeploy {
    string contractName = "L1ToArbitrumMessagesSenderModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());

        L1ToArbitrumMessagesSenderModule module = new L1ToArbitrumMessagesSenderModule();

        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
