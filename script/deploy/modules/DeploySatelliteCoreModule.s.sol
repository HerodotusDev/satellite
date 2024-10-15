// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";

import {IDeployModule} from "script/deploy/interfaces/IDeployModule.sol";

import {SatelliteCoreModule} from "src/modules/SatelliteCoreModule.sol";

contract DeploySatelliteCoreModule is IDeployModule {
    string contractName = "SatelliteCoreModule";

    function deploy() internal override returns (address moduleAddress) {
        vm.startBroadcast(getPrivateKey());
        SatelliteCoreModule module = new SatelliteCoreModule();
        vm.stopBroadcast();

        moduleAddress = address(module);
    }

    function getContractName() public view override returns (string memory) {
        return contractName;
    }
}
