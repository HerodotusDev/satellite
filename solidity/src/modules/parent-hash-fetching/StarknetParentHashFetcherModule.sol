// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "../../interfaces/ISatellite.sol";
import {IStarknetParentHashFetcherModule} from "../../interfaces/modules/parent-hash-fetching/IStarknetParentHashFetcherModule.sol";
import {IStarknet} from "../../interfaces/external/IStarknet.sol";
import {AccessController} from "../../libraries/AccessController.sol";
import {BlockHeaderReader} from "../../libraries/BlockHeaderReader.sol";
import {IEvmFactRegistryModule} from "../../interfaces/modules/IEvmFactRegistryModule.sol";

/// @notice Fetches parent hashes for Starknet
/// @notice if deployed on Ethereum Sepolia, it fetches parent hashes from Starknet Sepolia
contract StarknetParentHashFetcherModule is IStarknetParentHashFetcherModule, AccessController, BlockHeaderReader {
    bytes32 public constant POSEIDON_HASHING_FUNCTION = keccak256("poseidon");
    bytes32 internal constant STARKNET_CONTRACT_STATE_SLOT = keccak256(abi.encodePacked("STARKNET_1.0_INIT_STARKNET_STATE_STRUCT"));
    bytes32 internal constant STARKNET_CONTRACT_BLOCK_NUMBER_SLOT = bytes32(uint256(STARKNET_CONTRACT_STATE_SLOT) + 1);
    bytes32 internal constant STARKNET_CONTRACT_BLOCK_HASH_SLOT = bytes32(uint256(STARKNET_CONTRACT_STATE_SLOT) + 2);

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

    function starknetFetchParentHashAtBlock(
        bytes calldata blockHeader,
        bytes calldata accountMptProof,
        bytes calldata storageSlotMptProof1,
        bytes calldata storageSlotMptProof2
    ) external {
        StarknetParentHashFetcherModuleStorage storage ms = moduleStorage();

        bytes32[BLOCK_HEADER_FIELD_COUNT] memory fields = _readBlockHeaderFields(blockHeader);

        bytes32 blockHash = keccak256(blockHeader);
        bytes32 stateRoot = fields[uint8(IEvmFactRegistryModule.BlockHeaderField.STATE_ROOT)];
        uint256 blockNumber = uint256(fields[uint8(IEvmFactRegistryModule.BlockHeaderField.NUMBER)]);

        bytes32 trueBlockHash = blockhash(blockNumber);
        require(blockHash != bytes32(0), "BLOCK_HASH_NOT_AVAILABLE");
        require(blockHash == trueBlockHash, "BLOCK_HASH_NOT_MATCH");

        (, , , bytes32 storageRoot) = IEvmFactRegistryModule(address(this)).verifyOnlyAccount(ms.chainId, address(ms.starknetContract), stateRoot, accountMptProof);

        uint256 starknetBlockNumber = uint256(IEvmFactRegistryModule(address(this)).verifyOnlyStorage(STARKNET_CONTRACT_BLOCK_NUMBER_SLOT, storageRoot, storageSlotMptProof1));
        bytes32 starknetBlockHash = IEvmFactRegistryModule(address(this)).verifyOnlyStorage(STARKNET_CONTRACT_BLOCK_HASH_SLOT, storageRoot, storageSlotMptProof2);

        ISatellite(address(this))._receiveParentHash(ms.chainId, POSEIDON_HASHING_FUNCTION, starknetBlockNumber + 1, starknetBlockHash);
    }
}
