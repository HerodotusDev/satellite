// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Lib_RLPReader as RLPReader} from "@optimism/libraries/rlp/Lib_RLPReader.sol";
import {StatelessMmr} from "@solidity-mmr/lib/StatelessMmr.sol";

struct RootForHashingFunction {
    bytes32 root;
    bytes32 hashingFunction;
}

enum GrownBy {
    /// @dev GrownBy.EVM_ON_CHAIN_GROWER - appended by NativeOnChainGrowingModule
    EVM_ON_CHAIN_GROWER,
    /// @dev GrownBy.EVM_SHARP_GROWER - appended by NativeSharpGrowingModule
    EVM_SHARP_GROWER,
    /// @dev GrownBy.STARKNET_SHARP_GROWER - appended by StarknetSharpMmrGrowingModule
    STARKNET_SHARP_GROWER,
    EVM_TIMESTAMP_REMAPPER
}

enum CreatedFrom {
    FOREIGN,
    DOMESTIC
}

interface IMmrCoreModule {
    // ========================= Other Satellite Modules Only Functions ========================= //

    /// @notice Receiving a recent parent hash obtained on-chain directly on this chain or sent in a message from another one (eg. L1 -> L2)
    /// @dev saves the parent hash of the block number (from a given chain) in the contract storage
    function _receiveParentHash(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes32 parentHash) external;

    /// @notice Creates a new branch from message sent from satellite on another chain
    /// @param newMmrId the ID of the MMR to create
    /// @param rootsForHashingFunctions the roots of the MMR -> ABI encoded hashing function => MMR root
    /// @param mmrSize the size of the MMR
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates (where block is?)
    /// @param originChainId the ID of the chain from which the new MMR will be created (who is sending msg?)
    /// @param originalMmrId the ID of the MMR from which the new MMR will be created
    /// @param isSiblingSynced whether the MMR is sibling synced
    function _createMmrFromForeign(
        uint256 newMmrId,
        RootForHashingFunction[] calldata rootsForHashingFunctions,
        uint256 mmrSize,
        uint256 accumulatedChainId,
        uint256 originChainId,
        uint256 originalMmrId,
        bool isSiblingSynced
    ) external;

    // ========================= Core Functions ========================= //

    /// @notice Creates a new MMR that is a clone of an already existing MMR or an empty MMR if originalMmrId is 0 (in that case mmrSize is ignored)
    /// @param newMmrId the ID of the new MMR
    /// @param originalMmrId the ID of the MMR from which the new MMR will be created - if 0 it means an empty MMR will be created
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param mmrSize size at which the MMR will be copied
    /// @param hashingFunctions the hashing functions used in the MMR - if more than one, the MMR will be sibling synced and require being a satellite module to call
    function createMmrFromDomestic(uint256 newMmrId, uint256 originalMmrId, uint256 accumulatedChainId, uint256 mmrSize, bytes32[] calldata hashingFunctions) external;

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
    /// @param createdFrom enum representing the source of the MMR creation - DOMESTIC or FOREIGN
    event CreatedMmr(
        uint256 newMmrId,
        uint256 mmrSize,
        uint256 accumulatedChainId,
        uint256 originalMmrId,
        RootForHashingFunction[] rootsForHashingFunctions,
        uint256 originChainId,
        CreatedFrom createdFrom
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
