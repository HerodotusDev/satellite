// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "interfaces/ISatellite.sol";
import {INativeBlockHashFetcherModule} from "interfaces/modules/block-hash-fetching/INativeBlockHashFetcherModule.sol";

/// @notice Fetches block hashes for the native chain
/// @notice for example if deployed on Ethereum, it will fetch block hashes from Ethereum
contract NativeBlockHashFetcherModule is INativeBlockHashFetcherModule {
    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");

    /// @inheritdoc INativeBlockHashFetcherModule
    function nativeFetchBlockHash(uint256 blockNumber) external {
        bytes32 blockHash = blockhash(blockNumber);
        require(blockHash != bytes32(0), "ERR_PARENT_HASH_NOT_AVAILABLE");

        ISatellite(address(this))._receiveBlockHash(block.chainid, KECCAK_HASHING_FUNCTION, blockNumber, blockHash);
    }
}
