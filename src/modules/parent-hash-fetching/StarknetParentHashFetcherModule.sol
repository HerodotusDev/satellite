// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "interfaces/ISatellite.sol";
import {IStarknetParentHashFetcherModule} from "interfaces/modules/parent-hash-fetching/IStarknetParentHashFetcherModule.sol";
import {IStarknet} from "interfaces/external/IStarknet.sol";

/// @notice Fetches parent hashes for Starknet
/// @notice if deployed on Ethereum Sepolia, it fetches parent hashes from Starknet Sepolia
contract StarknetParentHashFetcherModule is IStarknetParentHashFetcherModule {
    // TODO: important: DON'T USE CONSTRUCTOR HERE
    IStarknet public immutable STARKNET;
    // Either Starknet or Starknet Sepolia chain ID
    uint256 public immutable CHAIN_ID;

    bytes32 public constant POSEIDON_HASHING_FUNCTION = keccak256("poseidon");

    constructor(IStarknet starknet, uint256 chainId) {
        STARKNET = starknet;
        CHAIN_ID = chainId;
    }

    function starknetFetchParentHash() external {
        // From the starknet core contract get the latest settled block number
        uint256 latestSettledStarknetBlock = uint256(STARKNET.stateBlockNumber());
        // Extract its parent hash.
        bytes32 latestSettledStarknetBlockhash = bytes32(STARKNET.stateBlockHash());

        ISatellite(address(this))._receiveParentHash(CHAIN_ID, POSEIDON_HASHING_FUNCTION, latestSettledStarknetBlock + 1, latestSettledStarknetBlockhash);
    }
}
