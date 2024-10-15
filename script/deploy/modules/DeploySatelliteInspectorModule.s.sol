// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeployModule} from "script/deploy/interfaces/IDeployModule.sol";

import {SatelliteInspectorModule} from "src/modules/SatelliteInspectorModule.sol";

contract DeploySatelliteInspectorModule is IDeployModule {
    string contractName = "SatelliteInspectorModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());
        SatelliteInspectorModule module = new SatelliteInspectorModule();
        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
