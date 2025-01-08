// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "interfaces/ISatellite.sol";
import {INativeParentHashFetcherModule} from "interfaces/modules/x-rollup-messaging/parent-hash-fetcher/INativeParentHashFetcherModule.sol";

/// @title NativeParentHashFetcher
/// @notice Fetches parent hashes for the native chain
/// @notice for example if deployed on Ethereum, it will fetch parent hashes from Ethereum
contract NativeParentHashFetcherModule is INativeParentHashFetcherModule {
    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");

    function nativeFetchParentHash(uint256 blockNumber) external {
        bytes32 parentHash = blockhash(blockNumber - 1);
        require(parentHash != bytes32(0), "ERR_PARENT_HASH_NOT_AVAILABLE");

        ISatellite(address(this))._receiveBlockHash(block.chainid, KECCAK_HASHING_FUNCTION, blockNumber, parentHash);
    }
}
