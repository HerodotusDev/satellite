// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Lib_RLPReader as RLPReader} from "@optimism/libraries/rlp/Lib_RLPReader.sol";
import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";

interface ISatelliteCoreModule {
    // ========================= Types ========================= //

    struct MMRUpdateResult {
        uint256 firstAppendedBlock;
        uint256 lastAppendedBlock;
        uint256 newMMRSize;
        bytes32 newMMRRoot;
    }

    struct RootsForHashingFunctions {
        bytes32[] roots;
        bytes32[] hashingFunctions;
    }

    // ========================= Other Satellite Modules Only Functions ========================= //

    function _receiveBlockHash(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes32 parentHash) external;

    function _createMmrFromForeign(
        uint256 newMmrId,
        RootsForHashingFunctions calldata rootsForHashingFunctions,
        uint256 mmrSize,
        uint256 accumulatedChainId,
        uint256 originChainId,
        uint256 originalMmrId
    ) external;

    // ========================= Core Functions ========================= //

    function createMmrFromDomestic(uint256 newMmrId, uint256 originalMmrId, uint256 accumulatedChainId, uint256 mmrSize, bytes32[] calldata hashingFunctions) external;

    function onchainAppendBlocksBatch(
        uint256 accumulatedChainId,
        uint256 mmrId,
        bool processFromReceivedBlockHash,
        bytes32 hashingFunction,
        bytes calldata ctx,
        bytes[] calldata headersSerialized
    ) external;

    // ========================= View functions ========================= //

    function getMMRRoot(uint256 mmrId, uint256 mmrSize, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (bytes32);

    function getLatestMMRRoot(uint256 mmrId, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (bytes32);

    function getLatestMMRSize(uint256 mmrId, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (uint256);

    function getReceivedParentHash(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber) external view returns (bytes32);

    // ========================= Events ========================= //

    /// @notice emitted when a block hash is received
    /// @param chainId the ID of the chain that the block hash is from
    /// @param blockNumber the block number
    /// @param parentHash the parent hash of the block number
    event HashReceived(uint256 chainId, uint256 blockNumber, bytes32 parentHash, bytes32 hashingFunction);
    /// @notice emitted when a new MMR is created from a foreign source (eg. from another chain, or off-chain computation proven on-chain)
    /// @param newMmrId the ID of the new MMR
    /// @param mmrSize the size of the MMR
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param originChainId the ID of the chain from which the new MMR comes from
    /// @param originalMmrId the ID of the MMR from which the new MMR is created
    /// @dev hashingFunction is a 32 byte keccak hash of the hashing function name, eg: keccak256("keccak256"), keccak256("poseidon")
    /// @param rootsForHashingFunctions the roots of the MMR -> hashing function => MMR root
    event MmrCreatedFromForeign(
        uint256 newMmrId,
        uint256 mmrSize,
        uint256 accumulatedChainId,
        uint256 originChainId,
        uint256 originalMmrId,
        RootsForHashingFunctions rootsForHashingFunctions
    );
    /// @notice emitted when a new MMR is created from a domestic source (from another MMR, or a standalone new empty MMR)
    /// @param newMmrId the ID of the new MMR
    /// @param mmrSize the size of the MMR
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param originalMmrId the ID of the MMR from which the new MMR is created - if 0, it means an new empty MMR was created
    /// @dev hashingFunction is a 32 byte keccak hash of the hashing function name, eg: keccak256("keccak256"), keccak256("poseidon")
    /// @param mmrRoots the roots of the MMR -> abi endoded hashing function => MMR root
    event MmrCreatedFromDomestic(uint256 newMmrId, uint256 mmrSize, uint256 accumulatedChainId, uint256 originalMmrId, bytes mmrRoots);
    /// @notice emitted when a batch of blocks is appended to the MMR
    /// @param result MMRUpdateResult struct containing firstAppendedBlock, lastAppendedBlock, newMMRSize, newMMRRoot
    /// @param mmrId the ID of the MMR that was updated
    /// @dev hashingFunction is a 32 byte keccak hash of the hashing function name, eg: keccak256("keccak256"), keccak256("poseidon")
    /// @param hashingFunction the hashing function used to calculate the MMR
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    event OnchainAppendedBlocksBatch(MMRUpdateResult result, uint256 mmrId, bytes32 hashingFunction, uint256 accumulatedChainId);
}
