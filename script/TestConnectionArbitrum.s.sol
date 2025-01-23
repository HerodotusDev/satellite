// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";

import {ISatellite} from "src/interfaces/ISatellite.sol";
import {IArbitrumInbox} from "src/interfaces/external/IArbitrumInbox.sol";

bytes32 constant KECCAK_HASHING_FUNCTION = keccak256("keccak");
uint256 constant ORIGIN_CHAIN_ID = 11155111;
uint256 constant DESTINATION_CHAIN_ID = 421614;
uint256 constant BLOCK_NUMBER = 7498494;

contract TestConnectionArbitrum is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        address satelliteAddress = vm.envAddress("SATELLITE_ADDRESS_11155111");
        ISatellite satellite = ISatellite(satelliteAddress); // l1

        uint256 l1BaseFee = 2 * 1000000000; // Gwei from etherscan main page
        uint256 l2GasLimit = 170422 * 10;
        uint256 maxFeePerGas = 40034270938 * 20; // from ethers

        IArbitrumInbox arbitrumInbox = IArbitrumInbox(vm.envAddress("SEPOLIA_ARBITRUM_INBOX"));

        vm.startBroadcast(pk);
        uint256 maxSubmissionCost = arbitrumInbox.calculateRetryableSubmissionFee(160, l1BaseFee);
        vm.stopBroadcast();

        bytes memory gasData = abi.encode(uint256(l2GasLimit), uint256(maxFeePerGas), uint256(maxSubmissionCost));

        uint256 value = (maxSubmissionCost + l2GasLimit * maxFeePerGas) * 3;

        vm.startBroadcast(pk);
        satellite.sendParentHash{value: value}(DESTINATION_CHAIN_ID, ORIGIN_CHAIN_ID, KECCAK_HASHING_FUNCTION, BLOCK_NUMBER, gasData);
        vm.stopBroadcast();
    }
}
