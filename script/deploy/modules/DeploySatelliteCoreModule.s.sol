// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {IDeployModule} from "script/deploy/interfaces/IDeployModule.sol";

import {SatelliteCoreModule} from "src/modules/SatelliteCoreModule.sol";

contract DeploySatelliteCoreModule is Script, IDeployModule {
    string contractName = "SatelliteCoreModule";

    function deploy() internal override returns (address moduleAddress) {
        SatelliteCoreModule module = new SatelliteCoreModule();
        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
