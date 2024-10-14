// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Lib_RLPReader as RLPReader} from "@optimism/libraries/rlp/Lib_RLPReader.sol";
import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";

interface ISatelliteCoreModule {
    // ========================= Other Satellite Modules Only Functions ========================= //

    /// @notice Receiving a recent block hash obtained on-chain directly on this chain or sent in a message from another one (eg. L1 -> L2)
    /// @notice saves the parent hash of the block number (from a given chain) in the contract storage
    function _receiveBlockHash(uint256 chainId, uint256 blockNumber, bytes32 parentHash, bytes32 hashingFunction) external;

    /// @notice Creates a new branch from an L1 message, the sent MMR info comes from an L1 aggregator
    /// @param newMmrId the ID of the MMR to create
    /// @param mmrRoots the roots of the MMR -> abi endoded hashing function => MMR root
    /// @param mmrSize the size of the MMR
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param originChainId the ID of the chain from which the new MMR will be created
    /// @param originalMmrId the ID of the MMR from which the new MMR will be created
    function _createMmrFromForeign(uint256 newMmrId, bytes calldata mmrRoots, uint256 mmrSize, uint256 accumulatedChainId, uint256 originChainId, uint256 originalMmrId) external;

    // ========================= Core Functions ========================= //

    /// @notice Creates a new MMR that is a clone of an already existing MMR or an empty MMR if mmrId is 0 (in that case mmrSize is ignored)
    /// @param newMmrId the ID of the new MMR
    /// @param originalMmrId the ID of the MMR from which the new MMR will be created
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param mmrSize size at which the MMR will be copied
    function createMmrFromDomestic(uint256 newMmrId, uint256 originalMmrId, uint256 accumulatedChainId, uint256 mmrSize, bytes32[] calldata hashingFunctions) external;

    /// @notice Processes & appends a batch of blocks
    /// @dev We sometimes refer to appending blocks as "processing" or "accumulating" them
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param mmrId the ID of the MMR to update
    /// @param processFromReceivedBlockHash whether processing should start from the received block hash or look for the reference header in the MMR
    /// @param ctx the context of the batch, encoded as bytes.
    ///    If the reference header is accumulated, the context contains the MMR proof and peaks.
    ///    If the reference header is not accumulated, the context contains the block number of the reference header and the MMR peaks.
    /// @param headersSerialized the serialized headers of the batch
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
}
