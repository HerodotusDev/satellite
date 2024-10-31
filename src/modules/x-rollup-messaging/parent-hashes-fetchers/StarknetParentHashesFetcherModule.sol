// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "interfaces/ISatellite.sol";
import {IStarknetParentHashesFetcherModule} from "interfaces/modules/x-rollup-messaging/parent-hashes-fetchers/IStarknetParentHashesFetcherModule.sol";
import {IStarknet} from "interfaces/external/IStarknet.sol";

/// @title NativeParentHashesFetcher
/// @notice Fetches parent hashes for the native chain
/// @notice for example if deployed on Ethereum, it will fetch parent hashes from Ethereum
contract StarknetParentHashesFetcherModule is IStarknetParentHashesFetcherModule {
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

        ISatellite(address(this))._receiveBlockHash(CHAIN_ID, POSEIDON_HASHING_FUNCTION, latestSettledStarknetBlock + 1, latestSettledStarknetBlockhash);
    }
}
