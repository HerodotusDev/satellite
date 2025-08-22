// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "../../interfaces/ISatellite.sol";
import {IArbitrumParentHashFetcherModule, IERC20Outbox} from "../../interfaces/modules/parent-hash-fetching/IArbitrumParentHashFetcherModule.sol";
import {AccessController} from "../../libraries/AccessController.sol";
import {Lib_RLPReader as RLPReader} from "../../libraries/external/optimism/rlp/Lib_RLPReader.sol";

/// @notice Fetches parent hashes for Arbitrum-like chains
/// @notice if deployed on Ethereum Sepolia, it fetches parent hashes from Arbitrum Sepolia
/// @notice if deployed on Arbitrum Sepolia, it fetches parent hashes from ApeChain Sepolia (Curtis)
contract ArbitrumParentHashFetcherModule is IArbitrumParentHashFetcherModule, AccessController {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");

    // ========================= Satellite Module Storage ========================= //

    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.satellite.module.storage.arbitrum-parent-hash-fetcher");

    function moduleStorage() internal pure returns (ArbitrumParentHashFetcherModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // ========================= Core Functions ========================= //

    function initArbitrumParentHashFetcherModule(address outboxAddress, uint256 chainId) external onlyOwner {
        ArbitrumParentHashFetcherModuleStorage storage ms = moduleStorage();
        ms.outboxContract = IERC20Outbox(outboxAddress);
        ms.chainId = chainId;
    }

    /// @param rootHash Root hash that is key of the mapping `roots` of `ERC20Outbox` contract
    function arbitrumFetchParentHash(bytes32 rootHash, bytes memory blockHeader) external {
        ArbitrumParentHashFetcherModuleStorage storage ms = moduleStorage();

        bytes32 knownBlockHash = ms.outboxContract.roots(rootHash);
        require(knownBlockHash != bytes32(0), "ERR_EMPTY_ROOT_HASH");

        bytes32 blockHash = keccak256(blockHeader);
        require(blockHash == knownBlockHash, "ERR_BLOCK_HASH_MISMATCH");

        uint256 blockNumber = _decodeBlockNumber(blockHeader);

        ISatellite(address(this))._receiveParentHash(ms.chainId, KECCAK_HASHING_FUNCTION, blockNumber + 1, blockHash);
    }

    // ========================= Helper Functions ========================= //

    function _decodeBlockNumber(bytes memory headerRlp) internal pure returns (uint256) {
        return RLPReader.toRLPItem(headerRlp).readList()[8].readUint256();
    }
}
