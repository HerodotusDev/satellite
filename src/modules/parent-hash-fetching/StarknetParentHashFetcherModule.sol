// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "interfaces/ISatellite.sol";
import {IStarknetParentHashFetcherModule} from "interfaces/modules/parent-hash-fetching/IStarknetParentHashFetcherModule.sol";
import {IStarknet} from "interfaces/external/IStarknet.sol";
import {AccessController} from "libraries/AccessController.sol";

/// @notice Fetches parent hashes for Starknet
/// @notice if deployed on Ethereum Sepolia, it fetches parent hashes from Starknet Sepolia
contract StarknetParentHashFetcherModule is IStarknetParentHashFetcherModule, AccessController {
    bytes32 public constant POSEIDON_HASHING_FUNCTION = keccak256("poseidon");

    // ========================= Satellite Module Storage ========================= //

    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.satellite.module.storage.starknet-parent-hash-fetcher");

    function moduleStorage() internal pure returns (StarknetParentHashFetcherModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // ========================= Core Functions ========================= //

    function initStarknetParentHashFetcherModule(IStarknet starknetContract, uint256 chainId) external onlyOwner {
        StarknetParentHashFetcherModuleStorage storage ms = moduleStorage();
        ms.starknetContract = starknetContract;
        ms.chainId = chainId;
    }

    function starknetFetchParentHash() external {
        StarknetParentHashFetcherModuleStorage storage ms = moduleStorage();

        // From the starknet core contract get the latest settled block number
        uint256 latestSettledStarknetBlock = uint256(ms.starknetContract.stateBlockNumber());
        // Extract its parent hash.
        bytes32 latestSettledStarknetBlockhash = bytes32(ms.starknetContract.stateBlockHash());

        ISatellite(address(this))._receiveParentHash(ms.chainId, POSEIDON_HASHING_FUNCTION, latestSettledStarknetBlock + 1, latestSettledStarknetBlockhash);
    }
}
