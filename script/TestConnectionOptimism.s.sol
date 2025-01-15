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
uint256 constant DESTINATION_CHAIN_ID = 11155420;
uint256 constant BLOCK_NUMBER = 7498494;

contract TestConnectionOptimism is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        address satelliteAddress = vm.envAddress("SATELLITE_ADDRESS_11155111");
        ISatellite satellite = ISatellite(satelliteAddress); // l1

        uint256 l2GasLimit = 170422*2;

        bytes memory gasData = abi.encode(uint32(l2GasLimit));

        vm.startBroadcast(pk);
        // satellite.sendMessageL1ToOptimism(        
        //     0xB0908Cd18B4A1c37dCab093b63595400aE325e8C,
        //     0x58Cc85b8D04EA49cC6DBd3CbFFd00B4B8D6cb3ef,
        //     abi.encodeWithSignature("receiveHashForBlock(uint256,bytes32,uint256,bytes32)", 11155111, 0xdf35a135a69c769066bbb4d17b2fa3ec922c028d4e4bf9d0402e6f7c12b31813, 7498494, 0x123),
        //     gasData
        // );
        satellite.sendParentHash(DESTINATION_CHAIN_ID, ORIGIN_CHAIN_ID, KECCAK_HASHING_FUNCTION, BLOCK_NUMBER, gasData);
        vm.stopBroadcast();
    }
}
