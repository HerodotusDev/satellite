// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Script} from "./AbstractScript.sol";
import {console} from "forge-std/console.sol";
import {IEvmSharpMmrGrowingModule} from "src/interfaces/modules/growing/IEvmSharpMmrGrowingModule.sol";

contract TestScript is Script {
    function run() public {
        vm.startBroadcast(deployerPK);

        console.log(satellite.isProgramHashAuthorized(bytes32(uint256(0x123))));
        satellite.setDataProcessorProgramHash(bytes32(uint256(0x123)));

        vm.stopBroadcast();

        vm.startBroadcast(PK);

        console.log(satellite.isProgramHashAuthorized(bytes32(uint256(0x345))));
        console.log(satellite.isProgramHashAuthorized(bytes32(uint256(0x123))));

        vm.stopBroadcast();
    }
}
