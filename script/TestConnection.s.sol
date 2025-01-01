// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";

import {ISatellite} from "interfaces/ISatellite.sol";
import {IArbitrumInbox} from "interfaces/external/IArbitrumInbox.sol";

bytes32 constant KECCAK_HASHING_FUNCTION = keccak256("keccak");
uint256 constant ORIGIN_CHAIN_ID = 11155111;
uint256 constant BLOCK_NUMBER = 7392000;

contract TestConnection is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        ISatellite satellite = ISatellite(address(0x77133dE818eFC2DC2351924737B58B4335c73776)); // l1
        // ISatellite satellite = ISatellite(address(0x798E0eE46B18C1FC3862D1B73a1088A2bFa3B34F)); // arbitrum

        // // register my address as message sender
        // address otherSatelliteAddress = address(0xA2981531d8d7bB7C17e1674E53F844a96BFf51b5);
        // address aliasedAddress = address(uint160(otherSatelliteAddress) + uint160(0x1111000000000000000000000000000000001111));
        // console.log(otherSatelliteAddress);
        // console.log(aliasedAddress);
        // satellite.registerSatellite(ORIGIN_CHAIN_ID, otherSatelliteAddress, aliasedAddress);

        // // fetch parent hash
        // satellite.nativeFetchParentHash(BLOCK_NUMBER);

        // send parent hash to Arbitrum
        uint256 l1BaseFee = 6*1000000000; // 2 Gwei
        uint256 l2GasLimit = 170422*2;
        uint256 maxFeePerGas = 40034270938*2; // from ethers

        IArbitrumInbox arbitrumInbox = IArbitrumInbox(address(0xaAe29B0366299461418F5324a79Afc425BE5ae21));

        vm.startBroadcast(pk);
        uint256 maxSubmitionCost = arbitrumInbox.calculateRetryableSubmissionFee(160, l1BaseFee);
        vm.stopBroadcast();

        bytes memory gasData = abi.encode(uint256(l2GasLimit), uint256(maxFeePerGas), uint256(maxSubmitionCost));

        // console.log(maxSubmitionCost); // 74672000000000

        uint256 value = (maxSubmitionCost + l2GasLimit * maxFeePerGas) * 2;

        // console.log(value); // 11184953281400000

        vm.startBroadcast(pk);
        satellite.sendParentHashL1ToArbitrum{value: value}(ORIGIN_CHAIN_ID, KECCAK_HASHING_FUNCTION, BLOCK_NUMBER, gasData);
        vm.stopBroadcast();
    }
}
