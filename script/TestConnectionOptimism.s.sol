// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";

import {ISatellite} from "interfaces/ISatellite.sol";
import {IArbitrumInbox} from "interfaces/external/IArbitrumInbox.sol";
import {IL1ToArbitrumMessagesSenderModule} from "interfaces/modules/x-rollup-messaging/outbox/IL1ToArbitrumMessagesSenderModule.sol";

bytes32 constant KECCAK_HASHING_FUNCTION = keccak256("keccak");
uint256 constant ORIGIN_CHAIN_ID = 11155111;
uint256 constant BLOCK_NUMBER = 7413540;

contract TestConnectionOptimism is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        address satelliteAddress = 0xf0D08a411980dDb690848272272081a99D622A44;
        ISatellite satellite = ISatellite(satelliteAddress); // l1

        uint256 l2GasLimit = 170422*2;

        bytes memory gasData = abi.encode(uint32(l2GasLimit));

        vm.startBroadcast(pk);
        satellite.sendParentHashL1ToOptimism(ORIGIN_CHAIN_ID, KECCAK_HASHING_FUNCTION, BLOCK_NUMBER, gasData);
        vm.stopBroadcast();
    }
}
