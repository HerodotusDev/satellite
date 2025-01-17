// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "interfaces/ISatellite.sol";
import {IStarknetBlockHashFetcherModule} from "interfaces/modules/block-hash-fetching/IStarknetBlockHashFetcherModule.sol";
import {IStarknet} from "interfaces/external/IStarknet.sol";
import {AccessController} from "libraries/AccessController.sol";

/// @notice Fetches block hashes for Starknet
/// @notice if deployed on Ethereum Sepolia, it fetches block hashes from Starknet Sepolia
contract StarknetBlockHashFetcherModule is IStarknetBlockHashFetcherModule, AccessController {
    bytes32 public constant POSEIDON_HASHING_FUNCTION = keccak256("poseidon");

    // ========================= Satellite Module Storage ========================= //

    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.satellite.module.storage.starknet-block-hash-fetcher");

    function moduleStorage() internal pure returns (StarknetBlockHashFetcherModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // ========================= Core Functions ========================= //

    function initStarknetBlockHashFetcherModule(IStarknet starknetContract, uint256 chainId) external onlyOwner {
        StarknetBlockHashFetcherModuleStorage storage ms = moduleStorage();
        ms.starknetContract = starknetContract;
        ms.chainId = chainId;
    }

    function starknetFetchBlockHash() external {
        StarknetBlockHashFetcherModuleStorage storage ms = moduleStorage();

        // From the starknet core contract get the latest settled block number
        uint256 latestSettledStarknetBlock = uint256(ms.starknetContract.stateBlockNumber());
        // Extract its block hash.
        bytes32 latestSettledStarknetBlockhash = bytes32(ms.starknetContract.stateBlockHash());

        ISatellite(address(this))._receiveBlockHash(ms.chainId, POSEIDON_HASHING_FUNCTION, latestSettledStarknetBlock, latestSettledStarknetBlockhash);
    }
}
