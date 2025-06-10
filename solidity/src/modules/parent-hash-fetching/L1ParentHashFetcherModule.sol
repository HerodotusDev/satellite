// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "../../interfaces/ISatellite.sol";
import {IL1ParentHashFetcherModule} from "../../interfaces/modules/parent-hash-fetching/IL1ParentHashFetcherModule.sol";
import {AccessController} from "../../libraries/AccessController.sol";

/// @notice Fetches parent hashes for the L1 chain.
/// @notice For example if deployed on Apechain, it will fetch parent hashes from Ethereum.
/// @notice Works only on Arbitrum and Apechain, because they return L1 block hash from blockhash() function
contract L1ParentHashFetcherModule is IL1ParentHashFetcherModule, AccessController {
    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");

    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.satellite.module.storage.l1-parent-hash-fetcher");

    function moduleStorage() internal pure returns (L1ParentHashFetcherModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    /// @inheritdoc IL1ParentHashFetcherModule
    function l1FetchParentHash(uint256 blockNumber) external {
        bytes32 parentHash = blockhash(blockNumber - 1);
        require(parentHash != bytes32(0), "ERR_PARENT_HASH_NOT_AVAILABLE");

        ISatellite(address(this))._receiveParentHash(block.chainid, KECCAK_HASHING_FUNCTION, blockNumber, parentHash);
    }

    /// @inheritdoc IL1ParentHashFetcherModule
    function initL1ParentHashFetcherModule(uint256 l1ChainId) external onlyOwner {
        L1ParentHashFetcherModuleStorage storage s = moduleStorage();
        s.l1ChainId = l1ChainId;
    }
}
