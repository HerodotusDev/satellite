// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {IDeployModule} from "script/deploy/interfaces/IDeployModule.sol";

import {SatelliteInspectorModule} from "src/modules/SatelliteInspectorModule.sol";

contract DeploySatelliteInspectorModule is Script, IDeployModule {
    string contractName = "SatelliteInspectorModule";

    function deploy() internal override returns (address moduleAddress) {
        SatelliteInspectorModule module = new SatelliteInspectorModule();
        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
