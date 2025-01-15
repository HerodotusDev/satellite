// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Lib_RLPReader as RLPReader} from "@optimism/libraries/rlp/Lib_RLPReader.sol";
import {StatelessMmr} from "@solidity-mmr/lib/StatelessMmr.sol";

struct RootForHashingFunction {
    bytes32 root;
    bytes32 hashingFunction;
}

enum GrownBy {
    NATIVE_ON_CHAIN_GROWER,
    NATIVE_SHARP_GROWER,
    STARKNET_SHARP_GROWER,
    TIMESTAMP_REMAPPER
}

interface IMmrCoreModule {
    // ========================= Other Satellite Modules Only Functions ========================= //

    function _receiveBlockHash(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes32 parentHash) external;

    function _createMmrFromForeign(
        uint256 newMmrId,
        RootForHashingFunction[] calldata rootsForHashingFunctions,
        uint256 mmrSize,
        uint256 accumulatedChainId,
        uint256 originChainId,
        uint256 originalMmrId,
        bool isSiblingSynced,
        //! Note: two new fields, might need adding in different places
        bool isTimestampRemapper,
        uint256 firstTimestampsBlock
    ) external;

    // ========================= Core Functions ========================= //

    function createMmrFromDomestic(
        uint256 newMmrId,
        uint256 originalMmrId,
        uint256 accumulatedChainId,
        uint256 mmrSize,
        bytes32[] calldata hashingFunctions,
        //! Note: two new fields, might need adding in different places
        bool isTimestampRemapper,
        uint256 firstTimestampsBlock
    ) external;

    // ========================= View functions ========================= //

    function POSEIDON_HASHING_FUNCTION() external view returns (bytes32);

    function KECCAK_HASHING_FUNCTION() external view returns (bytes32);

    function POSEIDON_MMR_INITIAL_ROOT() external view returns (bytes32);

    function KECCAK_MMR_INITIAL_ROOT() external view returns (bytes32);

    function getMmrRoot(uint256 mmrId, uint256 mmrSize, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (bytes32);

    function getLatestMmrRoot(uint256 mmrId, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (bytes32);

    function getLatestMmrSize(uint256 mmrId, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (uint256);

    function getReceivedParentHash(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber) external view returns (bytes32);

    // ========================= Events ========================= //

    /// @notice emitted when a block hash is received
    /// @param chainId the ID of the chain that the block hash is from
    /// @param blockNumber the block number
    /// @param parentHash the parent hash of the block number
    /// @param hashingFunction the hashing function use to hash the block, e.g. Keccak on Ethereum and Poseidon on Starknet
    /// @dev hashingFunction is a 32 byte keccak hash of the hashing function name, eg: keccak256("keccak256"), keccak256("poseidon")
    event ReceivedParentHash(uint256 chainId, uint256 blockNumber, bytes32 parentHash, bytes32 hashingFunction);

    /// @notice emitted when a new MMR is created from a domestic or foreign source
    /// @notice - foreign source - sent from another chain, or off-chain computation proven on-chain
    /// @notice - domestic source - created from another MMR on the same chain, or a standalone new empty MMR
    /// @param newMmrId the ID of the new MMR
    /// @param mmrSize the size of the MMR
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param originalMmrId the ID of the MMR from which the new MMR is created - if 0, it means an new empty MMR was created
    /// @param rootsForHashingFunctions list of pairs (mmrRoot, hashingFunction) representing mmr roots for each hashing function
    /// @dev every hashingFunction should occur at most once in the list
    /// @dev hashingFunction is a 32 byte keccak hash of the hashing function name, eg: keccak256("keccak256"), keccak256("poseidon")
    /// @param originChainId the ID of the chain from which the new MMR comes from
    /// @dev if originChainId equal to accumulatedChainId, it means the MMR is created from domestic source, otherwise it is created from foreign source
    event CreatedMmr(
        uint256 newMmrId,
        uint256 mmrSize,
        uint256 accumulatedChainId,
        uint256 originalMmrId,
        RootForHashingFunction[] rootsForHashingFunctions,
        uint256 originChainId,
        bool isTimestampRemapper,
        uint256 firstTimestampsBlock
    );

    /// @notice emitted when a batch of blocks is appended to the MMR
    /// @param firstAppendedBlock the block number of the first block appended
    /// @param lastAppendedBlock the block number of the last block appended
    /// @param rootsForHashingFunctions list of pairs (mmrRoot, hashingFunction) representing mmr roots for each hashing function
    /// @dev every hashingFunction should occur at most once in the list
    /// @param mmrSize the size of the MMR after the batch of blocks is appended
    /// @param mmrId the ID of the MMR that was grown
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param grownBy enum representing which growing module appended blocks to MMR
    /// @dev GrownBy.NATIVE_ON_CHAIN_GROWER - appended by NativeOnChainGrowingModule
    /// @dev GrownBy.NATIVE_SHARP_GROWER - appended by NativeSharpGrowingModule
    /// @dev GrownBy.STARKNET_SHARP_GROWER - appended by StarknetSharpMmrGrowingModule
    event GrownMmr(
        uint256 firstAppendedBlock,
        uint256 lastAppendedBlock,
        RootForHashingFunction[] rootsForHashingFunctions,
        uint256 mmrSize,
        uint256 mmrId,
        uint256 accumulatedChainId,
        GrownBy grownBy
    );
}
