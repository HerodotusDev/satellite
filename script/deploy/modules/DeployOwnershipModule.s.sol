// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {IDeployModule} from "script/deploy/interfaces/IDeployModule.sol";

import {OwnershipModule} from "src/modules/OwnershipModule.sol";

contract DeployOwnershipModule is Script, IDeployModule {
    string contractName = "OwnershipModule";

    function deploy() internal override returns (address moduleAddress) {
        OwnershipModule module = new OwnershipModule();
        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
