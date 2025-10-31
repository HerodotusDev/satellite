// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatellite} from "../../interfaces/ISatellite.sol";
import {IOptimismParentHashFetcherModule, OptimismFetcherChainInfo, OptimismParentHashFetcherModuleStorage, IDisputeGameFactory, IFaultDisputeGame} from "../../interfaces/modules/parent-hash-fetching/IOptimismParentHashFetcherModule.sol";
import {AccessController} from "../../libraries/AccessController.sol";
import {Lib_RLPReader as RLPReader} from "../../libraries/external/optimism/rlp/Lib_RLPReader.sol";

// Mainnet: 0xe5965Ab5962eDc7477C8520243A95517CD252fA9

/// @notice Fetches parent hashes for Optimism-like chains
/// @notice if deployed on Ethereum Sepolia, it fetches parent hashes from Optimism Sepolia
contract OptimismParentHashFetcherModule is IOptimismParentHashFetcherModule, AccessController {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");

    // ========================= Satellite Module Storage ========================= //

    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.satellite.module.storage.optimism-parent-hash-fetcher");

    function moduleStorage() internal pure returns (OptimismParentHashFetcherModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // ========================= Core Functions ========================= //

    function addOptimismParentHashFetcher(uint256 chainId, address disputeGameFactory, address trustedGameProposer) external onlyOwner {
        OptimismFetcherChainInfo storage chainInfo = moduleStorage().chainInfo[chainId];
        chainInfo.disputeGameFactory = IDisputeGameFactory(disputeGameFactory);
        chainInfo.trustedGameProposer = trustedGameProposer;

        emit OptimismParentHashFetcherInitialized(chainId, disputeGameFactory, trustedGameProposer);
    }

    function optimismFetchParentHash(uint256 chainId, uint256 gameIndex, bytes32 versionByte, bytes32 stateRoot, bytes32 withdrawalStorageRoot, bytes memory blockHeader) external {
        OptimismFetcherChainInfo storage chainInfo = moduleStorage().chainInfo[chainId];
        require(chainInfo.disputeGameFactory != IDisputeGameFactory(address(0)), "ERR_CHAIN_NOT_SUPPORTED_FOR_OPTIMISM");

        (, , address proxy) = chainInfo.disputeGameFactory.gameAtIndex(gameIndex);
        require(proxy != address(0), "ERR_GAME_NOT_FOUND");

        IFaultDisputeGame game = IFaultDisputeGame(proxy);
        uint8 status = game.status();

        if (status == 1) {
            revert("ERR_GAME_FAILED");
        } else if (status == 0) {
            // On sepolia trustedGameProposer should not be checked and then it is set to 0x0
            require(chainInfo.trustedGameProposer == address(0) || game.gameCreator() == chainInfo.trustedGameProposer, "ERR_UNFINISHED_GAME_NOT_TRUSTED");
        } else if (status != 2) {
            revert("ERR_UNKNOWN_GAME_STATUS");
        }

        bytes32 rootClaim = game.rootClaim();

        bytes32 blockHash = keccak256(blockHeader);
        bytes memory payload = abi.encode(stateRoot, withdrawalStorageRoot, blockHash);
        bytes memory fullInput = bytes.concat(bytes32(versionByte), payload);
        bytes32 calculatedRoot = keccak256(fullInput);

        require(rootClaim == calculatedRoot, "ERR_ROOT_CLAIM_MISMATCH");

        uint256 blockNumber = _decodeBlockNumber(blockHeader);

        ISatellite(address(this))._receiveParentHash(chainId, KECCAK_HASHING_FUNCTION, blockNumber + 1, blockHash);
    }

    // ========================= Helper Functions ========================= //

    function _decodeBlockNumber(bytes memory headerRlp) internal pure returns (uint256) {
        return RLPReader.toRLPItem(headerRlp).readList()[8].readUint256();
    }
}
