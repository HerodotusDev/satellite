// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {Deploy} from "script/deploy/Satellite.s.sol";
import {ISatellite} from "interfaces/ISatellite.sol";
import {console} from "forge-std/console.sol";

contract Satellite is Test {
    ISatellite satellite;
    uint256 blockNumber;
    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");

    constructor() {
        string memory SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
        vm.createSelectFork(SEPOLIA_RPC_URL);
        address satelliteAddress = new Deploy().run();
        satellite = ISatellite(satelliteAddress);
        blockNumber = block.number - 20;
    }

    function test_have_n_facets() external view {
        uint256 n = 7;
        assertEq(satellite.moduleAddresses().length, n);
    }

    function test_native_parent_hashes_fetcher() external {
        satellite.nativeFetchParentHash(blockNumber);
        bytes32 parentHash = satellite.getReceivedParentHash(block.chainid, KECCAK_HASHING_FUNCTION, blockNumber);

        assertNotEq(parentHash, bytes32(0));
    }

    function test_enforce_is_satellite_module() external {
        bytes32 parentHash = blockhash(blockNumber - 1);
        vm.expectRevert(ISatellite.MustBeSatelliteModule.selector);
        satellite._receiveBlockHash(block.chainid, KECCAK_HASHING_FUNCTION, blockNumber, parentHash);
    }
}
