// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Lib_RLPReader as RLPReader} from "@optimism/libraries/rlp/Lib_RLPReader.sol";
import {StatelessMmr} from "@solidity-mmr/lib/StatelessMmr.sol";

struct RootForHashingFunction {
    bytes32 root;
    bytes32 hashingFunction;
}

interface IMMRsCoreModule {
    // ========================= Other Satellite Modules Only Functions ========================= //

    function _receiveBlockHash(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes32 parentHash) external;

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

    function createMmrFromDomestic(uint256 newMmrId, uint256 originalMmrId, uint256 accumulatedChainId, uint256 mmrSize, bytes32[] calldata hashingFunctions) external;

    // ========================= View functions ========================= //

    function POSEIDON_HASHING_FUNCTION() external view returns (bytes32);

    function KECCAK_HASHING_FUNCTION() external view returns (bytes32);

    function POSEIDON_MMR_INITIAL_ROOT() external view returns (bytes32);

    function KECCAK_MMR_INITIAL_ROOT() external view returns (bytes32);

    function getMMRRoot(uint256 mmrId, uint256 mmrSize, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (bytes32);

    function getLatestMMRRoot(uint256 mmrId, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (bytes32);

    function getLatestMMRSize(uint256 mmrId, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (uint256);

    function getReceivedParentHash(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber) external view returns (bytes32);

    // ========================= Events ========================= //

    /// @notice emitted when a block hash is received
    /// @param chainId the ID of the chain that the block hash is from
    /// @param blockNumber the block number
    /// @param parentHash the parent hash of the block number
    event ParentHashReceived(uint256 chainId, uint256 blockNumber, bytes32 parentHash, bytes32 hashingFunction);

    /// @notice emitted when a new MMR is created from a domestic source (from another MMR, or a standalone new empty MMR)
    /// @param newMmrId the ID of the new MMR
    /// @param mmrSize the size of the MMR
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param originalMmrId the ID of the MMR from which the new MMR is created - if 0, it means an new empty MMR was created
    /// @dev hashingFunction is a 32 byte keccak hash of the hashing function name, eg: keccak256("keccak256"), keccak256("poseidon")
    /// @param rootsForHashingFunctions the roots of the MMR -> hashing function => MMR root
    /// @param originChainId the ID of the chain from which the new MMR comes from
    event MmrCreation(uint256 newMmrId, uint256 mmrSize, uint256 accumulatedChainId, uint256 originalMmrId, RootForHashingFunction[] rootsForHashingFunctions, uint256 originChainId);

    // event MmrUpdate(uint256 firstAppendedBlock, uint256 lastAppendedBlock, );
}
