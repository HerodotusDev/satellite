// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Lib_RLPReader as RLPReader} from "@optimism/libraries/rlp/Lib_RLPReader.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";

contract SatelliteCore is Ownable {
    // ========================= Types ========================= //
    using RLPReader for RLPReader.RLPItem;

    /// @notice This struct represents a Merkle Mountain Range accumulating provably valid block hashes
    /// @dev each MMR is mapped to a unique ID also referred to as mmrId
    struct MMRInfo {
        /// @notice latestSize represents the latest size of the MMR
        uint256 latestSize;
        /// @notice mmrSizeToRoot maps the  MMR size => the MMR root, that way we have automatic versioning
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
    /// @dev mapping of ChainId => MMR ID => hashing function => MMR info
    /// @dev hashingFunction is a 32 byte keccak hash of the hashing function name, eg: keccak256("keccak256"), keccak256("poseidon")
    mapping(uint256 => mapping(uint256 => mapping(bytes32 => MMRInfo))) public mmrs;

    /// @notice mapping of ChainId => hashing function => block number => block parent hash
    mapping(uint256 => mapping(bytes32 => mapping(uint256 => bytes32))) public receivedParentHashes;

    // ========================= Events ========================= //
    /// @notice emitted when a block hash is received
    /// @param chainId the ID of the chain that the block hash is from
    /// @param blockNumber the block number
    /// @param parentHash the parent hash of the block number
    event HashReceived(uint256 chainId, uint256 blockNumber, bytes32 parentHash, bytes23 hashingFunction);
    /// @notice emitted when a new MMR is created from a foreign source (eg. from another chain, or off-chain computation proven on-chain)
    /// @param newMmrId the ID of the new MMR
    /// @param mmrSize the size of the MMR
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param originChainId the ID of the chain from which the new MMR comes from
    /// @param originalMmrId the ID of the MMR from which the new MMR is created
    /// @dev hashingFunction is a 32 byte keccak hash of the hashing function name, eg: keccak256("keccak256"), keccak256("poseidon")
    /// @param mmrRoots the roots of the MMR -> abi endoded hashing function => MMR root
    event MmrCreatedFromForeign(uint256 newMmrId, uint256 mmrSize, uint256 accumulatedChainId, uint256 originChainId, uint256 originalMmrId, bytes mmrRoots);
    /// @notice emitted when a new MMR is created from a domestic source (from another MMR, or a standalone new empty MMR)
    /// @param newMmrId the ID of the new MMR
    /// @param mmrSize the size of the MMR
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param originalMmrId the ID of the MMR from which the new MMR is created - if 0, it means an new empty MMR was created
    /// @dev hashingFunction is a 32 byte keccak hash of the hashing function name, eg: keccak256("keccak256"), keccak256("poseidon")
    /// @param mmrRoots the roots of the MMR -> abi endoded hashing function => MMR root
    event MmrCreatedFromDomestic(uint256 newMmrId, uint256 mmrSize, uint256 accumulatedChainId, uint256 originalMmrId, bytes mmrRoots);
    /// @notice emitted when a batch of blocks is appended to the MMR
    /// @param firstAppendedBlock the block number of the first block appended - the highest block number in the batch
    /// @param lastAppendedBlock the block number of the last block appended - the lowest block number in the batch
    /// @param newMMRSize the new size of the MMR after the batch is appended
    /// @param mmrId the ID of the MMR that was updated
    /// @param newMMRRoot the root of the MMR
    /// @dev hashingFunction is a 32 byte keccak hash of the hashing function name, eg: keccak256("keccak256"), keccak256("poseidon")
    /// @param hashingFunction the hashing function used to calculate the MMR
    event OnchainAppendedBlocksBatch(uint256 firstAppendedBlock, uint256 lastAppendedBlock, uint256 newMMRSize, uint256 mmrId, bytes32 newMMRRoot, bytes32 hashingFunction);

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
    function receiveBlockHash(uint256 chainId, uint256 blockNumber, bytes32 parentHash, bytes23 hashingFunction) external onlySatelliteDish {
        receivedParentHashes[chainId][hashingFunction][blockNumber] = parentHash;
        emit HashReceived(chainId, blockNumber, parentHash, hashingFunction);
    }

    /// @notice Creates a new branch from an L1 message, the sent MMR info comes from an L1 aggregator
    /// @param newMmrId the ID of the MMR to create
    /// @param mmrRoots the roots of the MMR -> abi endoded hashing function => MMR root
    /// @param mmrSize the size of the MMR
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param originChainId the ID of the chain from which the new MMR will be created
    /// @param originalMmrId the ID of the MMR from which the new MMR will be created
    function createMmrFromForeign(
        uint256 newMmrId,
        bytes calldata mmrRoots,
        uint256 mmrSize,
        uint256 accumulatedChainId,
        uint256 originChainId,
        uint256 originalMmrId
    ) external onlySatelliteDish {
        require(newMmrId != EMPTY_MMR_ID, "NEW_MMR_ID_0_NOT_ALLOWED");

        (bytes32[] memory hashingFunctions, bytes32[] memory roots) = abi.decode(mmrRoots, (bytes32[], bytes32[]));
        require(roots.length >= 1, "INVALID_ROOTS_LENGTH");
        require(hashingFunctions.length == roots.length, "ROOTS_FUNCTIONS_LENGTH_MISMATCH");

        // Ensure the given ID is not already taken

        // Create a new MMR
        for (uint256 i = 0; i < hashingFunctions.length; i++) {
            require(roots[i] != NO_MMR_ROOT, "ROOT_0_NOT_ALLOWED");
            require(mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].latestSize == NO_MMR_SIZE, "NEW_MMR_ALREADY_EXISTS");
            mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].latestSize = mmrSize;
            mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].mmrSizeToRoot[mmrSize] = roots[i];
        }

        // Emit the event
        emit MmrCreatedFromForeign(newMmrId, mmrSize, accumulatedChainId, originChainId, originalMmrId, mmrRoots);
    }

    /// @notice Creates a new MMR that is a clone of an already existing MMR or an empty MMR if mmrId is 0 (in that case mmrSize is ignored)
    /// @param newMmrId the ID of the new MMR
    /// @param originalMmrId the ID of the MMR from which the new MMR will be created
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    /// @param mmrSize size at which the MMR will be copied
    function createMmrFromDomestic(uint256 newMmrId, uint256 originalMmrId, uint256 accumulatedChainId, uint256 mmrSize, bytes32[] calldata hashingFunctions) external {
        require(newMmrId != EMPTY_MMR_ID, "NEW_MMR_ID_0_NOT_ALLOWED");
        require(hashingFunctions.length >= 1, "INVALID_HASHING_FUNCTIONS_LENGTH");

        bytes32[] memory roots;

        for (uint256 i = 0; i < hashingFunctions.length; i++) {
            require(mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].latestSize == NO_MMR_SIZE, "NEW_MMR_ALREADY_EXISTS");

            bytes32 mmrRoot;
            if (originalMmrId == EMPTY_MMR_ID) {
                // Create an empty MMR
                mmrRoot = EMPTY_MMR_ROOT;
                mmrSize = EMPTY_MMR_SIZE;
            } else {
                // Load existing MMR data
                mmrRoot = mmrs[accumulatedChainId][originalMmrId][hashingFunctions[i]].mmrSizeToRoot[mmrSize];
                // Ensure the given MMR exists
                require(mmrRoot != NO_MMR_ROOT, "SRC_MMR_NOT_FOUND");
            }

            // Copy the MMR data to the new MMR
            mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].latestSize = mmrSize;
            mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].mmrSizeToRoot[mmrSize] = mmrRoot;
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
        require(mmrs[accumulatedChainId][mmrId][hashingFunction].latestSize != NO_MMR_SIZE, "ERR_MMR_DOES_NOT_EXIST");

        uint256 firstAppendedBlock;
        uint256 newMMRSize;
        bytes32 newMMRRoot;

        if (processFromReceivedBlockHash) {
            (firstAppendedBlock, newMMRSize, newMMRRoot) = _processBatchFromReceivedBlockHash(mmrId, ctx, headersSerialized, accumulatedChainId, hashingFunction);
        } else {
            (firstAppendedBlock, newMMRSize, newMMRRoot) = _processBatchFromAccumulated(mmrId, ctx, headersSerialized, accumulatedChainId, hashingFunction);
        }

        emit OnchainAppendedBlocksBatch(firstAppendedBlock, firstAppendedBlock - headersSerialized.length + 1, newMMRSize, mmrId, newMMRRoot, hashingFunction);
    }

    /// ========================= Internal functions ========================= //

    function _processBatchFromAccumulated(
        uint256 treeId,
        bytes memory ctx,
        bytes[] memory headersSerialized,
        uint256 accumulatedChainId,
        bytes32 hashingFunction
    ) internal returns (uint256 firstAppendedBlock, uint256 newMMRSize, bytes32 newMMRRoot) {
        (uint256 referenceProofLeafIndex, bytes32[] memory referenceProof, bytes32[] memory mmrPeaks, bytes memory referenceHeaderSerialized) = abi.decode(
            ctx,
            (uint256, bytes32[], bytes32[], bytes)
        );

        _validateParentBlockAndProveIntegrity(treeId, referenceProofLeafIndex, referenceProof, mmrPeaks, referenceHeaderSerialized, accumulatedChainId, hashingFunction);

        bytes32 decodedParentHash = _decodeParentHash(referenceHeaderSerialized);

        require(decodedParentHash == keccak256(headersSerialized[0]), "ERR_NON_CONSECUTIVE_ELEMENT");

        bytes32[] memory headersHashes = new bytes32[](headersSerialized.length);
        headersHashes[0] = decodedParentHash;
        for (uint256 i = 1; i < headersSerialized.length; ++i) {
            bytes32 parentHash = _decodeParentHash(headersSerialized[i - 1]);
            require(_isHeaderValid(parentHash, headersSerialized[i]), "ERR_INVALID_CHAIN_ELEMENT");
            headersHashes[i] = parentHash;
        }
        (newMMRSize, newMMRRoot) = _appendMultipleBlockhashesToMMR(headersHashes, mmrPeaks, treeId, accumulatedChainId, hashingFunction);
        firstAppendedBlock = _decodeBlockNumber(headersSerialized[0]);
    }

    function _processBatchFromReceivedBlockHash(
        uint256 treeId,
        bytes memory ctx,
        bytes[] memory headersSerialized,
        uint256 accumulatedChainId,
        bytes32 hashingFunction
    ) internal returns (uint256 firstAppendedBlock, uint256 newMMRSize, bytes32 newMMRRoot) {
        (uint256 blockNumber, bytes32[] memory mmrPeaks) = abi.decode(ctx, (uint256, bytes32[]));

        bytes32 expectedHash = receivedParentHashes[accumulatedChainId][hashingFunction][blockNumber + 1];
        require(expectedHash != bytes32(0), "ERR_NO_REFERENCE_HASH");

        bytes32[] memory headersHashes = new bytes32[](headersSerialized.length);
        for (uint256 i = 0; i < headersSerialized.length; i++) {
            require(_isHeaderValid(expectedHash, headersSerialized[i]), "ERR_INVALID_CHAIN_ELEMENT");
            headersHashes[i] = expectedHash;
            expectedHash = _decodeParentHash(headersSerialized[i]);
        }

        (newMMRSize, newMMRRoot) = _appendMultipleBlockhashesToMMR(headersHashes, mmrPeaks, treeId, accumulatedChainId, hashingFunction);
        firstAppendedBlock = blockNumber;
    }

    function _appendMultipleBlockhashesToMMR(
        bytes32[] memory blockhashes,
        bytes32[] memory lastPeaks,
        uint256 mmrId,
        uint256 accumulatedChainId,
        bytes32 hashingFunction
    ) internal returns (uint256 newSize, bytes32 newRoot) {
        // Getting current mmr state for the treeId
        newSize = mmrs[accumulatedChainId][mmrId][hashingFunction].latestSize;
        newRoot = mmrs[accumulatedChainId][mmrId][hashingFunction].mmrSizeToRoot[newSize];

        // Allocate temporary memory for the next peaks
        bytes32[] memory nextPeaks = lastPeaks;

        for (uint256 i = 0; i < blockhashes.length; ++i) {
            (newSize, newRoot, nextPeaks) = StatelessMmr.appendWithPeaksRetrieval(blockhashes[i], nextPeaks, newSize, newRoot);
        }

        // Update the contract storage
        mmrs[accumulatedChainId][mmrId][hashingFunction].mmrSizeToRoot[newSize] = newRoot;
        mmrs[accumulatedChainId][mmrId][hashingFunction].latestSize = newSize;
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
        // Verify the reference block is in the MMR and the proof is valid
        uint256 mmrSize = mmrs[accumulatedChainId][mmrId][hashingFunction].latestSize;
        bytes32 root = mmrs[accumulatedChainId][mmrId][hashingFunction].mmrSizeToRoot[mmrSize];
        StatelessMmr.verifyProof(referenceProofLeafIndex, keccak256(referenceHeaderSerialized), referenceProof, mmrPeaks, mmrSize, root);
    }

    // ========================= View functions ========================= //

    function getMMRRoot(uint256 mmrId, uint256 mmrSize, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (bytes32) {
        return mmrs[accumulatedChainId][mmrId][hashingFunction].mmrSizeToRoot[mmrSize];
    }

    function getLatestMMRRoot(uint256 mmrId, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (bytes32) {
        uint256 latestSize = mmrs[accumulatedChainId][mmrId][hashingFunction].latestSize;
        return mmrs[accumulatedChainId][mmrId][hashingFunction].mmrSizeToRoot[latestSize];
    }

    function getLatestMMRSize(uint256 mmrId, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (uint256) {
        return mmrs[accumulatedChainId][mmrId][hashingFunction].latestSize;
    }
}
