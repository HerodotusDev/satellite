// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Lib_RLPReader as RLPReader} from "@optimism/libraries/rlp/Lib_RLPReader.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";

contract Satellite is Ownable {
    // ========================= Types ========================= //
    using RLPReader for RLPReader.RLPItem;

    /// @notice This struct represents a Merkle Mountain Range accumulating provably valid block hashes
    /// @dev each MMR is mapped to a unique ID also referred to as mmrId
    struct MMRInfo {
        /// @notice latestSize represents the latest size of the MMR
        uint256 latestSize;
        /// @notice mmrSizeToRoot maps the MMR size to the MMR root, that way we have automatic versioning
        mapping(uint256 => bytes32) mmrSizeToRoot;
    }

    // ========================= Constants ========================= //
    /// @notice non existent MMR size
    uint256 constant NO_MMR_SIZE = 0;
    /// @notice non existent MMR root
    bytes32 constant NO_MMR_ROOT = 0;
    /// @notice non existent MMR id
    uint256 constant EMPTY_MMR_ID = 0;
    /// @notice empty MMR size
    uint256 constant EMPTY_MMR_SIZE = 1;
    /// @notice empty MMR root - calculated using keccak256
    bytes32 constant EMPTY_MMR_ROOT = 0x5d8d23518dd388daa16925ff9475c5d1c06430d21e0422520d6a56402f42937b;

    // ========================= Mappings ========================= //
    /// @dev mapping of MMR ID to MMR info
    mapping(uint256 => mapping(uint256 => MMRInfo)) public mmrs;

    /// @notice mapping of block number to the block parent hash
    mapping(uint256 => mapping(uint256 => bytes32)) public receivedParentHashes;

    // ========================= Events ========================= //
    /// @notice emitted when a block hash is received
    /// @param chainId the ID of the chain that the block hash is from
    /// @param blockNumber the block number
    /// @param parentHash the parent hash of the block number
    event HashReceived(uint256 chainId, uint256 blockNumber, bytes32 parentHash);
    /// @notice emitted when a new MMR is created from a foreign source (eg. from another chain, or off-chain computation proven on-chain)
    /// @param newMmrId the ID of the new MMR
    /// @param mmrRoot the root of the MMR
    /// @param mmrSize the size of the MMR
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param originChainId the ID of the chain from which the new MMR comes from
    /// @param originalMmrId the ID of the MMR from which the new MMR is created
    event MmrCreatedFromForeign(uint256 newMmrId, bytes32 mmrRoot, uint256 mmrSize, uint256 accumulatedChainId, uint256 originChainId, uint256 originalMmrId);
    /// @notice emitted when a new MMR is created from a domestic source (from another MMR, or a standalone new empty MMR)
    /// @param newMmrId the ID of the new MMR
    /// @param mmrRoot the root of the MMR
    /// @param mmrSize the size of the MMR
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param originalMmrId the ID of the MMR from which the new MMR is created - if 0, it means an new empty MMR was created
    event MmrCreatedFromDomestic(uint256 newMmrId, bytes32 mmrRoot, uint256 mmrSize, uint256 accumulatedChainId, uint256 originalMmrId);
    /// @notice emitted when a batch of blocks is appended to the MMR
    /// @param firstAppendedBlock the block number of the first block appended - the highest block number in the batch
    /// @param lastAppendedBlock the block number of the last block appended - the lowest block number in the batch
    /// @param newMMRRoot the new root of the MMR after the batch is appended
    /// @param newMMRSize the new size of the MMR after the batch is appended
    /// @param mmrId the ID of the MMR that was updated
    event AppendedBlocksBatch(uint256 firstAppendedBlock, uint256 lastAppendedBlock, bytes32 newMMRRoot, uint256 newMMRSize, uint256 mmrId);

    // ========================= Satellite Dish ========================= //
    /// @notice address of the MessagesInbox contract allowed to forward messages to this contract
    address public satelliteDishAddr;

    function setSatelliteDishAddr(address _satelliteDishAddr) external onlyOwner {
        satelliteDishAddr = _satelliteDishAddr;
    }

    /// @notice modifier to ensure the caller is the MessagesInbox contract
    modifier onlySatelliteDish() {
        require(msg.sender == satelliteDishAddr, "ONLY_SATELLITE_DISH");
        _;
    }

    constructor(address _satelliteDishAddr) Ownable(msg.sender) {
        satelliteDishAddr = _satelliteDishAddr;
    }

    // ========================= Core Functions ========================= //
    /// @notice Receiving a recent block hash obtained on-chain directly on this chain or sent in a message from another one (eg. L1 -> L2)
    /// @notice saves the parent hash of the block number (from a given chain) in the contract storage
    function receiveBlockHash(uint256 chainId, uint256 blockNumber, bytes32 parentHash) external onlySatelliteDish {
        receivedParentHashes[chainId][blockNumber] = parentHash;
        emit HashReceived(chainId, blockNumber, parentHash);
    }

    /// @notice Creates a new branch from an L1 message, the sent MMR info comes from an L1 aggregator
    /// @param newMmrId the ID of the MMR to create
    /// @param mmrRoot the root of the MMR
    /// @param mmrSize the size of the MMR
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param originChainId the ID of the chain from which the new MMR will be created
    /// @param originalMmrId the ID of the MMR from which the new MMR will be created
    function createMmrFromForeign(
        uint256 newMmrId,
        bytes32 mmrRoot,
        uint256 mmrSize,
        uint256 accumulatedChainId,
        uint256 originChainId,
        uint256 originalMmrId
    ) external onlySatelliteDish {
        require(newMmrId != EMPTY_MMR_ID, "NEW_MMR_ID_0_NOT_ALLOWED");
        require(mmrRoot != NO_MMR_ROOT, "ROOT_0_NOT_ALLOWED");

        // Ensure the given ID is not already taken
        require(mmrs[accumulatedChainId][newMmrId].latestSize == NO_MMR_SIZE, "NEW_MMR_ALREADY_EXISTS");

        // Create a new MMR
        mmrs[accumulatedChainId][newMmrId].latestSize = mmrSize;
        mmrs[accumulatedChainId][newMmrId].mmrSizeToRoot[mmrSize] = mmrRoot;

        // Emit the event
        emit MmrCreatedFromForeign(newMmrId, mmrRoot, mmrSize, accumulatedChainId, originChainId, originalMmrId);
    }

    /// @notice Creates a new MMR that is a clone of an already existing MMR or an empty MMR if mmrId is 0 (in that case mmrSize is ignored)
    /// @param newMmrId the ID of the new MMR
    /// @param originalMmrId the ID of the MMR from which the new MMR will be created
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param mmrSize size at which the MMR will be copied
    function createMmrFromDomestic(uint256 newMmrId, uint256 originalMmrId, uint256 accumulatedChainId, uint256 mmrSize) external {
        require(newMmrId != EMPTY_MMR_ID, "NEW_MMR_ID_0_NOT_ALLOWED");
        require(mmrs[accumulatedChainId][newMmrId].latestSize == NO_MMR_SIZE, "NEW_MMR_ALREADY_EXISTS");

        bytes32 mmrRoot;
        if (originalMmrId == EMPTY_MMR_ID) {
            // Create an empty MMR
            mmrRoot = EMPTY_MMR_ROOT;
            mmrSize = EMPTY_MMR_SIZE;
        } else {
            // Load existing MMR data
            mmrRoot = mmrs[accumulatedChainId][originalMmrId].mmrSizeToRoot[mmrSize];
        }

        // Ensure the given MMR exists
        require(mmrRoot != NO_MMR_ROOT, "SRC_MMR_NOT_FOUND");

        // Copy the MMR data to the new MMR
        mmrs[accumulatedChainId][newMmrId].latestSize = mmrSize;
        mmrs[accumulatedChainId][newMmrId].mmrSizeToRoot[mmrSize] = mmrRoot;

        // Emit the event
        emit MmrCreatedFromDomestic(newMmrId, mmrRoot, mmrSize, accumulatedChainId, originalMmrId);
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
    function appendBlocksBatch(uint256 accumulatedChainId, uint256 mmrId, bool processFromReceivedBlockHash, bytes calldata ctx, bytes[] calldata headersSerialized) external {
        require(headersSerialized.length > 0, "ERR_EMPTY_BATCH");
        require(mmrs[accumulatedChainId][mmrId].latestSize != NO_MMR_SIZE, "ERR_MMR_DOES_NOT_EXIST");

        uint256 firstAppendedBlock;
        uint256 newMMRSize;
        bytes32 newMMRRoot;

        if (processFromReceivedBlockHash) {
            (firstAppendedBlock, newMMRSize, newMMRRoot) = _processBatchFromReceivedBlockHash(mmrId, ctx, headersSerialized, accumulatedChainId);
        } else {
            (firstAppendedBlock, newMMRSize, newMMRRoot) = _processBatchFromAccumulated(mmrId, ctx, headersSerialized, accumulatedChainId);
        }

        emit AppendedBlocksBatch(firstAppendedBlock, firstAppendedBlock - headersSerialized.length + 1, newMMRRoot, newMMRSize, mmrId);
    }

    /// ========================= Internal functions ========================= //

    function _processBatchFromAccumulated(
        uint256 treeId,
        bytes memory ctx,
        bytes[] memory headersSerialized,
        uint256 accumulatedChainId
    ) internal returns (uint256 firstAppendedBlock, uint256 newMMRSize, bytes32 newMMRRoot) {
        (uint256 referenceProofLeafIndex, bytes32[] memory referenceProof, bytes32[] memory mmrPeaks, bytes memory referenceHeaderSerialized) = abi.decode(
            ctx,
            (uint256, bytes32[], bytes32[], bytes)
        );

        _validateParentBlockAndProveIntegrity(treeId, referenceProofLeafIndex, referenceProof, mmrPeaks, referenceHeaderSerialized, accumulatedChainId);

        bytes32 decodedParentHash = _decodeParentHash(referenceHeaderSerialized);

        require(decodedParentHash == keccak256(headersSerialized[0]), "ERR_NON_CONSECUTIVE_ELEMENT");

        bytes32[] memory headersHashes = new bytes32[](headersSerialized.length);
        headersHashes[0] = decodedParentHash;
        for (uint256 i = 1; i < headersSerialized.length; ++i) {
            bytes32 parentHash = _decodeParentHash(headersSerialized[i - 1]);
            require(_isHeaderValid(parentHash, headersSerialized[i]), "ERR_INVALID_CHAIN_ELEMENT");
            headersHashes[i] = parentHash;
        }
        (newMMRSize, newMMRRoot) = _appendMultipleBlockhashesToMMR(headersHashes, mmrPeaks, treeId, accumulatedChainId);
        firstAppendedBlock = _decodeBlockNumber(headersSerialized[0]);
    }

    function _processBatchFromReceivedBlockHash(
        uint256 treeId,
        bytes memory ctx,
        bytes[] memory headersSerialized,
        uint256 accumulatedChainId
    ) internal returns (uint256 firstAppendedBlock, uint256 newMMRSize, bytes32 newMMRRoot) {
        (uint256 blockNumber, bytes32[] memory mmrPeaks) = abi.decode(ctx, (uint256, bytes32[]));

        bytes32 expectedHash = receivedParentHashes[accumulatedChainId][blockNumber + 1];
        require(expectedHash != bytes32(0), "ERR_NO_REFERENCE_HASH");

        bytes32[] memory headersHashes = new bytes32[](headersSerialized.length);
        for (uint256 i = 0; i < headersSerialized.length; i++) {
            require(_isHeaderValid(expectedHash, headersSerialized[i]), "ERR_INVALID_CHAIN_ELEMENT");
            headersHashes[i] = expectedHash;
            expectedHash = _decodeParentHash(headersSerialized[i]);
        }

        (newMMRSize, newMMRRoot) = _appendMultipleBlockhashesToMMR(headersHashes, mmrPeaks, treeId, accumulatedChainId);
        firstAppendedBlock = blockNumber;
    }

    function _appendMultipleBlockhashesToMMR(
        bytes32[] memory blockhashes,
        bytes32[] memory lastPeaks,
        uint256 mmrId,
        uint256 accumulatedChainId
    ) internal returns (uint256 newSize, bytes32 newRoot) {
        // Getting current mmr state for the treeId
        newSize = mmrs[accumulatedChainId][mmrId].latestSize;
        newRoot = mmrs[accumulatedChainId][mmrId].mmrSizeToRoot[newSize];

        // Allocate temporary memory for the next peaks
        bytes32[] memory nextPeaks = lastPeaks;

        for (uint256 i = 0; i < blockhashes.length; ++i) {
            (newSize, newRoot, nextPeaks) = StatelessMmr.appendWithPeaksRetrieval(blockhashes[i], nextPeaks, newSize, newRoot);
        }

        // Update the contract storage
        mmrs[accumulatedChainId][mmrId].mmrSizeToRoot[newSize] = newRoot;
        mmrs[accumulatedChainId][mmrId].latestSize = newSize;
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
        uint256 accumulatedChainId
    ) internal view {
        // Verify the reference block is in the MMR and the proof is valid
        uint256 mmrSize = mmrs[accumulatedChainId][mmrId].latestSize;
        bytes32 root = mmrs[accumulatedChainId][mmrId].mmrSizeToRoot[mmrSize];
        StatelessMmr.verifyProof(referenceProofLeafIndex, keccak256(referenceHeaderSerialized), referenceProof, mmrPeaks, mmrSize, root);
    }

    // ========================= View functions ========================= //

    function getMMRRoot(uint256 mmrId, uint256 mmrSize, uint256 accumulatedChainId) external view returns (bytes32) {
        return mmrs[accumulatedChainId][mmrId].mmrSizeToRoot[mmrSize];
    }

    function getLatestMMRRoot(uint256 mmrId, uint256 accumulatedChainId) external view returns (bytes32) {
        uint256 latestSize = mmrs[accumulatedChainId][mmrId].latestSize;
        return mmrs[accumulatedChainId][mmrId].mmrSizeToRoot[latestSize];
    }

    function getLatestMMRSize(uint256 mmrId, uint256 accumulatedChainId) external view returns (uint256) {
        return mmrs[accumulatedChainId][mmrId].latestSize;
    }
}
