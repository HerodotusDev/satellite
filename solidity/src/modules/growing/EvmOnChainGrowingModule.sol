// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Lib_RLPReader as RLPReader} from "../../libraries/external/optimism/rlp/Lib_RLPReader.sol";
import {StatelessMmr} from "@HerodotusDev/solidity-mmr/src/lib/StatelessMmr.sol";
import {LibSatellite} from "../../libraries/LibSatellite.sol";
import {IEvmOnChainGrowingModule} from "../../interfaces/modules/growing/IEvmOnChainGrowingModule.sol";
import {ISatellite} from "../../interfaces/ISatellite.sol";
import {IMmrCoreModule, RootForHashingFunction, GrownBy} from "../../interfaces/modules/IMmrCoreModule.sol";

contract EvmOnChainGrowingModule is IEvmOnChainGrowingModule {
    // ========================= Types ========================= //

    using RLPReader for RLPReader.RLPItem;

    // ========================= Constants ========================= //

    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");

    // ========================= Functions ========================= //

    /// @notice Processes & appends a batch of blocks
    /// @dev We sometimes refer to appending blocks as "processing" or "accumulating" them
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param growMmrId the ID of the MMR to update
    /// @param processFromReceivedBlockHash whether processing should start from the received block hash or look for the reference header in the MMR
    /// @param ctx the context of the batch, encoded as bytes.
    ///    If the reference header is accumulated, the context contains the MMR proof and peaks.
    ///    If the reference header is not accumulated, the context contains the block number of the reference header and the MMR peaks.
    /// @param headersSerialized the serialized headers of the batch
    function onchainEvmAppendBlocksBatch(
        uint256 accumulatedChainId,
        uint256 growMmrId,
        bytes32[] calldata growMmrPeaks,
        bool processFromReceivedBlockHash,
        bytes calldata ctx,
        bytes[] calldata headersSerialized
    ) external {
        require(headersSerialized.length > 0, "ERR_EMPTY_BATCH");
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        // Onchain grown mmrs are guaranteed to have only one hashing function
        require(s.mmrs[accumulatedChainId][growMmrId][KECCAK_HASHING_FUNCTION].isOffchainGrown == false, "ERR_MMR_IS_SHARP_GROWN");
        require(s.mmrs[accumulatedChainId][growMmrId][KECCAK_HASHING_FUNCTION].latestSize != LibSatellite.NO_MMR_SIZE, "ERR_MMR_DOES_NOT_EXIST");

        MMRGrowResult memory result;

        if (processFromReceivedBlockHash) {
            result = _processBatchFromReceivedBlockHash(growMmrId, growMmrPeaks, ctx, headersSerialized, accumulatedChainId, KECCAK_HASHING_FUNCTION);
        } else {
            result = _processBatchFromAccumulated(growMmrId, growMmrPeaks, ctx, headersSerialized, accumulatedChainId, KECCAK_HASHING_FUNCTION);
        }

        RootForHashingFunction[] memory rootsForHashingFunctions = new RootForHashingFunction[](1);
        rootsForHashingFunctions[0].root = result.newMMRRoot;
        rootsForHashingFunctions[0].hashingFunction = KECCAK_HASHING_FUNCTION;

        emit IMmrCoreModule.GrownMmr(
            result.firstAppendedBlock,
            result.lastAppendedBlock,
            rootsForHashingFunctions,
            result.newMMRSize,
            growMmrId,
            accumulatedChainId,
            GrownBy.EVM_ON_CHAIN_GROWER
        );
    }

    /// ========================= Internal functions ========================= //

    function _processBatchFromAccumulated(
        uint256 grownMmrId,
        bytes32[] memory growMmrPeaks,
        bytes memory ctx,
        bytes[] memory headersSerialized,
        uint256 accumulatedChainId,
        bytes32 hashingFunction
    ) internal returns (MMRGrowResult memory result) {
        (uint256 proofMmrId, uint256 referenceProofLeafIndex, bytes32[] memory referenceProof, bytes32[] memory referencePeaks, bytes memory referenceHeaderSerialized) = abi
            .decode(ctx, (uint256, uint256, bytes32[], bytes32[], bytes));

        _validateParentBlockAndProveIntegrity(proofMmrId, referenceProofLeafIndex, referenceProof, referencePeaks, referenceHeaderSerialized, accumulatedChainId, hashingFunction);

        bytes32[] memory headersHashes = new bytes32[](headersSerialized.length);
        headersHashes[0] = _decodeParentHash(referenceHeaderSerialized);

        require(headersHashes[0] == keccak256(headersSerialized[0]), "ERR_NON_CONSECUTIVE_ELEMENT");

        for (uint256 i = 1; i < headersSerialized.length; ++i) {
            headersHashes[i] = _decodeParentHash(headersSerialized[i - 1]);
            require(_isHeaderValid(headersHashes[i], headersSerialized[i]), "ERR_INVALID_CHAIN_ELEMENT");
        }
        (result.newMMRSize, result.newMMRRoot) = _appendMultipleBlockhashesToMMR(headersHashes, growMmrPeaks, grownMmrId, accumulatedChainId, hashingFunction);
        result.firstAppendedBlock = _decodeBlockNumber(headersSerialized[0]);
        result.lastAppendedBlock = result.firstAppendedBlock - headersSerialized.length + 1;
    }

    function _processBatchFromReceivedBlockHash(
        uint256 growMmrId,
        bytes32[] memory growMmrPeaks,
        bytes memory ctx,
        bytes[] memory headersSerialized,
        uint256 accumulatedChainId,
        bytes32 hashingFunction
    ) internal returns (MMRGrowResult memory result) {
        uint256 blockNumber = abi.decode(ctx, (uint256)); // First appended block (reference block - 1)
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();

        bytes32 expectedHash = s.receivedParentHashes[accumulatedChainId][hashingFunction][blockNumber + 1];
        require(expectedHash != bytes32(0), "ERR_NO_REFERENCE_HASH");

        bytes32[] memory headersHashes = new bytes32[](headersSerialized.length);
        for (uint256 i = 0; i < headersSerialized.length; i++) {
            require(_isHeaderValid(expectedHash, headersSerialized[i]), "ERR_INVALID_CHAIN_ELEMENT");
            headersHashes[i] = expectedHash;
            expectedHash = _decodeParentHash(headersSerialized[i]);
        }

        (result.newMMRSize, result.newMMRRoot) = _appendMultipleBlockhashesToMMR(headersHashes, growMmrPeaks, growMmrId, accumulatedChainId, hashingFunction);
        result.firstAppendedBlock = blockNumber;
        result.lastAppendedBlock = result.firstAppendedBlock - headersSerialized.length + 1;
    }

    function _appendMultipleBlockhashesToMMR(
        bytes32[] memory blockhashes,
        bytes32[] memory lastPeaks,
        uint256 mmrId,
        uint256 accumulatedChainId,
        bytes32 hashingFunction
    ) internal returns (uint256 newSize, bytes32 newRoot) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();

        // Getting current mmr state for the treeId
        newSize = s.mmrs[accumulatedChainId][mmrId][hashingFunction].latestSize;
        newRoot = s.mmrs[accumulatedChainId][mmrId][hashingFunction].mmrSizeToRoot[newSize];

        // Allocate temporary memory for the next peaks
        bytes32[] memory nextPeaks = lastPeaks;

        for (uint256 i = 0; i < blockhashes.length; ++i) {
            (newSize, newRoot, nextPeaks) = StatelessMmr.appendWithPeaksRetrieval(blockhashes[i], nextPeaks, newSize, newRoot);
        }

        // Update the contract storage
        s.mmrs[accumulatedChainId][mmrId][hashingFunction].mmrSizeToRoot[newSize] = newRoot;
        s.mmrs[accumulatedChainId][mmrId][hashingFunction].latestSize = newSize;
        s.mmrs[accumulatedChainId][mmrId][hashingFunction].isOffchainGrown = false;
    }

    function _isHeaderValid(bytes32 hash, bytes memory headerRlp) internal pure returns (bool) {
        return keccak256(headerRlp) == hash;
    }

    function _decodeParentHash(bytes memory headerRlp) internal pure returns (bytes32) {
        return RLPReader.toRLPItem(headerRlp).readList()[0].readBytes32();
    }

    function _decodeBlockNumber(bytes memory headerRlp) internal pure returns (uint256) {
        return RLPReader.toRLPItem(headerRlp).readList()[8].readUint256();
    }

    function _validateParentBlockAndProveIntegrity(
        uint256 mmrId,
        uint256 referenceProofLeafIndex,
        bytes32[] memory referenceProof,
        bytes32[] memory mmrPeaks,
        bytes memory referenceHeaderSerialized,
        uint256 accumulatedChainId,
        bytes32 hashingFunction
    ) internal view {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        // Verify the reference block is in the MMR and the proof is valid
        uint256 mmrSize = s.mmrs[accumulatedChainId][mmrId][hashingFunction].latestSize;
        bytes32 root = s.mmrs[accumulatedChainId][mmrId][hashingFunction].mmrSizeToRoot[mmrSize];
        StatelessMmr.verifyProof(referenceProofLeafIndex, keccak256(referenceHeaderSerialized), referenceProof, mmrPeaks, mmrSize, root);
    }
}
