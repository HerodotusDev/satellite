// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Lib_RLPReader as RLPReader} from "@optimism/libraries/rlp/Lib_RLPReader.sol";
import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";
import {ISatelliteCoreModule} from "interfaces/modules/ISatelliteCoreModule.sol";

contract SatelliteCoreModule is ISatelliteCoreModule {
    // ========================= Types ========================= //

    using RLPReader for RLPReader.RLPItem;

    // ========================= Constants ========================= //

    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");
    bytes32 public constant POSEIDON_HASHING_FUNCTION = keccak256("poseidon");

    // Default roots for new aggregators:
    // poseidon_hash(1, "brave new world")
    bytes32 public constant POSEIDON_MMR_INITIAL_ROOT = 0x06759138078831011e3bc0b4a135af21c008dda64586363531697207fb5a2bae;

    // keccak_hash(1, "brave new world")
    bytes32 public constant KECCAK_MMR_INITIAL_ROOT = 0x5d8d23518dd388daa16925ff9475c5d1c06430d21e0422520d6a56402f42937b;

    // ========================= Other Satellite Modules Only Functions ========================= //

    /// @notice Receiving a recent block hash obtained on-chain directly on this chain or sent in a message from another one (eg. L1 -> L2)
    /// @notice saves the parent hash of the block number (from a given chain) in the contract storage
    function _receiveBlockHash(uint256 chainId, uint256 blockNumber, bytes32 parentHash, bytes32 hashingFunction) external {
        LibSatellite.enforceIsSatelliteModule();
        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        s.receivedParentHashes[chainId][hashingFunction][blockNumber] = parentHash;
        emit HashReceived(chainId, blockNumber, parentHash, hashingFunction);
    }

    /// @notice Creates a new branch from an L1 message, the sent MMR info comes from an L1 aggregator
    /// @param newMmrId the ID of the MMR to create
    /// @param mmrRoots the roots of the MMR -> abi endoded hashing function => MMR root
    /// @param mmrSize the size of the MMR
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param originChainId the ID of the chain from which the new MMR will be created
    /// @param originalMmrId the ID of the MMR from which the new MMR will be created
    function _createMmrFromForeign(uint256 newMmrId, bytes calldata mmrRoots, uint256 mmrSize, uint256 accumulatedChainId, uint256 originChainId, uint256 originalMmrId) external {
        LibSatellite.enforceIsSatelliteModule();
        require(newMmrId != LibSatellite.EMPTY_MMR_ID, "NEW_MMR_ID_0_NOT_ALLOWED");

        (bytes32[] memory hashingFunctions, bytes32[] memory roots) = abi.decode(mmrRoots, (bytes32[], bytes32[]));
        require(roots.length >= 1, "INVALID_ROOTS_LENGTH");
        require(hashingFunctions.length == roots.length, "ROOTS_FUNCTIONS_LENGTH_MISMATCH");

        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();

        // Create a new MMR
        for (uint256 i = 0; i < hashingFunctions.length; i++) {
            require(roots[i] != LibSatellite.NO_MMR_ROOT, "ROOT_0_NOT_ALLOWED");
            require(s.mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].latestSize == LibSatellite.NO_MMR_SIZE, "NEW_MMR_ALREADY_EXISTS");
            s.mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].latestSize = mmrSize;
            s.mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].mmrSizeToRoot[mmrSize] = roots[i];
        }

        // Emit the event
        emit MmrCreatedFromForeign(newMmrId, mmrSize, accumulatedChainId, originChainId, originalMmrId, mmrRoots);
    }

    // ========================= Core Functions ========================= //

    /// @notice Creates a new MMR that is a clone of an already existing MMR or an empty MMR if originalMmrId is 0 (in that case mmrSize is ignored)
    /// @param newMmrId the ID of the new MMR
    /// @param originalMmrId the ID of the MMR from which the new MMR will be created - if 0 it means an empty MMR will be created
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param mmrSize size at which the MMR will be copied
    function createMmrFromDomestic(uint256 newMmrId, uint256 originalMmrId, uint256 accumulatedChainId, uint256 mmrSize, bytes32[] calldata hashingFunctions) external {
        require(newMmrId != LibSatellite.EMPTY_MMR_ID, "NEW_MMR_ID_0_NOT_ALLOWED");
        require(hashingFunctions.length >= 1, "INVALID_HASHING_FUNCTIONS_LENGTH");

        bytes32[] memory roots;
        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();

        for (uint256 i = 0; i < hashingFunctions.length; i++) {
            require(s.mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].latestSize == LibSatellite.NO_MMR_SIZE, "NEW_MMR_ALREADY_EXISTS");

            bytes32 mmrRoot;
            if (originalMmrId == LibSatellite.EMPTY_MMR_ID) {
                // Create an empty MMR
                mmrRoot = _getInitialMmrRoot(hashingFunctions[i]);
                mmrSize = LibSatellite.EMPTY_MMR_SIZE;
            } else {
                // Load existing MMR data
                mmrRoot = s.mmrs[accumulatedChainId][originalMmrId][hashingFunctions[i]].mmrSizeToRoot[mmrSize];
                // Ensure the given MMR exists
                require(mmrRoot != LibSatellite.NO_MMR_ROOT, "SRC_MMR_NOT_FOUND");
            }

            // Copy the MMR data to the new MMR
            s.mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].latestSize = mmrSize;
            s.mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].mmrSizeToRoot[mmrSize] = mmrRoot;
            roots[i] = mmrRoot;
        }

        // Emit the event
        emit MmrCreatedFromDomestic(newMmrId, mmrSize, accumulatedChainId, originalMmrId, abi.encode(hashingFunctions, roots));
    }

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
    ) external {
        require(headersSerialized.length > 0, "ERR_EMPTY_BATCH");
        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        require(s.mmrs[accumulatedChainId][mmrId][hashingFunction].latestSize != LibSatellite.NO_MMR_SIZE, "ERR_MMR_DOES_NOT_EXIST");
        require(s.mmrs[accumulatedChainId][mmrId][hashingFunction].isSiblingSynced == true, "ERR_MMR_IS_SIBLING_SYNCED");

        MMRUpdateResult memory result;

        if (processFromReceivedBlockHash) {
            result = _processBatchFromReceivedBlockHash(mmrId, ctx, headersSerialized, accumulatedChainId, hashingFunction);
        } else {
            result = _processBatchFromAccumulated(mmrId, ctx, headersSerialized, accumulatedChainId, hashingFunction);
        }

        emit OnchainAppendedBlocksBatch(result, mmrId, hashingFunction, accumulatedChainId);
    }

    /// ========================= Internal functions ========================= //

    function _processBatchFromAccumulated(
        uint256 treeId,
        bytes memory ctx,
        bytes[] memory headersSerialized,
        uint256 accumulatedChainId,
        bytes32 hashingFunction
    ) internal returns (MMRUpdateResult memory result) {
        (uint256 referenceProofLeafIndex, bytes32[] memory referenceProof, bytes32[] memory mmrPeaks, bytes memory referenceHeaderSerialized) = abi.decode(
            ctx,
            (uint256, bytes32[], bytes32[], bytes)
        );

        _validateParentBlockAndProveIntegrity(treeId, referenceProofLeafIndex, referenceProof, mmrPeaks, referenceHeaderSerialized, accumulatedChainId, hashingFunction);

        bytes32[] memory headersHashes = new bytes32[](headersSerialized.length);
        headersHashes[0] = _decodeParentHash(referenceHeaderSerialized);

        require(headersHashes[0] == keccak256(headersSerialized[0]), "ERR_NON_CONSECUTIVE_ELEMENT");

        for (uint256 i = 1; i < headersSerialized.length; ++i) {
            headersHashes[i] = _decodeParentHash(headersSerialized[i - 1]);
            require(_isHeaderValid(headersHashes[i], headersSerialized[i]), "ERR_INVALID_CHAIN_ELEMENT");
        }
        (result.newMMRSize, result.newMMRRoot) = _appendMultipleBlockhashesToMMR(headersHashes, mmrPeaks, treeId, accumulatedChainId, hashingFunction);
        result.firstAppendedBlock = _decodeBlockNumber(headersSerialized[0]);
        result.lastAppendedBlock = result.firstAppendedBlock - headersSerialized.length + 1;
    }

    function _processBatchFromReceivedBlockHash(
        uint256 treeId,
        bytes memory ctx,
        bytes[] memory headersSerialized,
        uint256 accumulatedChainId,
        bytes32 hashingFunction
    ) internal returns (MMRUpdateResult memory result) {
        (uint256 blockNumber, bytes32[] memory mmrPeaks) = abi.decode(ctx, (uint256, bytes32[]));
        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();

        bytes32 expectedHash = s.receivedParentHashes[accumulatedChainId][hashingFunction][blockNumber + 1];
        require(expectedHash != bytes32(0), "ERR_NO_REFERENCE_HASH");

        bytes32[] memory headersHashes = new bytes32[](headersSerialized.length);
        for (uint256 i = 0; i < headersSerialized.length; i++) {
            require(_isHeaderValid(expectedHash, headersSerialized[i]), "ERR_INVALID_CHAIN_ELEMENT");
            headersHashes[i] = expectedHash;
            expectedHash = _decodeParentHash(headersSerialized[i]);
        }

        (result.newMMRSize, result.newMMRRoot) = _appendMultipleBlockhashesToMMR(headersHashes, mmrPeaks, treeId, accumulatedChainId, hashingFunction);
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
        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();

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
        s.mmrs[accumulatedChainId][mmrId][hashingFunction].isSiblingSynced = false;
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
        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        // Verify the reference block is in the MMR and the proof is valid
        uint256 mmrSize = s.mmrs[accumulatedChainId][mmrId][hashingFunction].latestSize;
        bytes32 root = s.mmrs[accumulatedChainId][mmrId][hashingFunction].mmrSizeToRoot[mmrSize];
        StatelessMmr.verifyProof(referenceProofLeafIndex, keccak256(referenceHeaderSerialized), referenceProof, mmrPeaks, mmrSize, root);
    }

    function _getInitialMmrRoot(bytes32 hashingFunction) internal pure returns (bytes32) {
        if (hashingFunction == KECCAK_HASHING_FUNCTION) {
            return KECCAK_MMR_INITIAL_ROOT;
        } else if (hashingFunction == POSEIDON_HASHING_FUNCTION) {
            return POSEIDON_MMR_INITIAL_ROOT;
        } else {
            revert("INVALID_HASHING_FUNCTION");
        }
    }

    // ========================= View functions ========================= //

    function getMMRRoot(uint256 mmrId, uint256 mmrSize, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (bytes32) {
        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.mmrs[accumulatedChainId][mmrId][hashingFunction].mmrSizeToRoot[mmrSize];
    }

    function getLatestMMRRoot(uint256 mmrId, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (bytes32) {
        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        uint256 latestSize = s.mmrs[accumulatedChainId][mmrId][hashingFunction].latestSize;
        return s.mmrs[accumulatedChainId][mmrId][hashingFunction].mmrSizeToRoot[latestSize];
    }

    function getLatestMMRSize(uint256 mmrId, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (uint256) {
        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.mmrs[accumulatedChainId][mmrId][hashingFunction].latestSize;
    }

    function isMMRSiblingSynced(uint256 mmrId, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (bool) {
        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.mmrs[accumulatedChainId][mmrId][hashingFunction].isSiblingSynced;
    }

    function getReceivedParentHash(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber) external view returns (bytes32) {
        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.receivedParentHashes[chainId][hashingFunction][blockNumber];
    }
}
