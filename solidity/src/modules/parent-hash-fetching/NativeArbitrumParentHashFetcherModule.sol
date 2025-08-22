// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "../../interfaces/ISatellite.sol";
import {IArbSys} from "../../interfaces/external/IArbSys.sol";
import {INativeParentHashFetcherModule} from "../../interfaces/modules/parent-hash-fetching/INativeParentHashFetcherModule.sol";

/// @notice Fetches parent hashes for the native chain that is Arbitrum based.
contract NativeArbitrumParentHashFetcherModule is INativeParentHashFetcherModule {
    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");
    IArbSys public constant arbSys = IArbSys(0x0000000000000000000000000000000000000064);

    /// @inheritdoc INativeParentHashFetcherModule
    function nativeFetchParentHash(uint256 blockNumber) external {
        bytes32 parentHash = arbSys.arbBlockHash(blockNumber - 1);
        require(parentHash != bytes32(0), "ERR_PARENT_HASH_NOT_AVAILABLE");

        ISatellite(address(this))._receiveParentHash(block.chainid, KECCAK_HASHING_FUNCTION, blockNumber, parentHash);
    }
}
