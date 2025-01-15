// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {ISatellite} from "interfaces/ISatellite.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";
import {IEVMFactRegistryModule} from "interfaces/modules/IEVMFactRegistryModule.sol";

import {Lib_RLPReader as RLPReader} from "@optimism/libraries/rlp/Lib_RLPReader.sol";
import {StatelessMmr} from "@solidity-mmr/lib/StatelessMmr.sol";
import {StatelessMmrHelpers} from "@solidity-mmr/lib/StatelessMmrHelpers.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IMmrCoreModule, RootForHashingFunction, GrownBy} from "interfaces/modules/IMmrCoreModule.sol";

// TODO: this is a rough implementation, we need to validate it, it needs an interface, it needs to be renamed and a deployment script needs to be written, etc.
contract TimestampRemapper {
    // ========================= Types ========================= //

    using RLPReader for RLPReader.RLPItem;

    /// @notice struct passed as calldata, represents the binsearch path element
    struct BinsearchPathElement {
        uint256 elementIndex;
        bytes32 leafValue;
        bytes32[] inclusionProof;
    }

    // ========================= Constants ========================= //

    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");

    // ========================= Functions ========================= //

    function createTimestampRemapperMmr(uint256 accumulatedChainId, uint256 newMmrId, uint256 originalMmrId, uint256 mmrSize, uint256 firstTimestampsBlock) external {
        bytes32[] memory hashingFunctions = new bytes32[](1);
        hashingFunctions[0] = KECCAK_HASHING_FUNCTION;

        ISatellite(address(this)).createMmrFromDomestic(newMmrId, originalMmrId, accumulatedChainId, mmrSize, hashingFunctions, true, firstTimestampsBlock);
    }

    /// @notice appends a batch of headers to the remapping MMR
    /// @notice Reindexing MMRs are always grown from their latest size, thus they're frontrunnable
    /// @param remapperId the id of the mapper to which the headers are appended
    /// @param lastPeaks the peaks of the grown remapping MMR
    /// @param headersWithProofs the headers with their proofs against the MMR managed by the headers processor
    function timestampRemapBlocksBatch(
        uint256 accumulatedChainId,
        uint256 remapperId,
        bytes32[] calldata lastPeaks,
        IEVMFactRegistryModule.BlockHeaderProof[] calldata headersWithProofs
    ) external {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        // Ensure that remapper exists at the given id
        bool isTimestampRemapper = s.mmrs[accumulatedChainId][remapperId][KECCAK_HASHING_FUNCTION].isTimestampRemapper;
        require(isTimestampRemapper, "ERR_NOT_A_TIMESTAMP_REMAPPER");

        // Load remapper start block from storage
        uint256 mapperStartBlock = s.mmrs[accumulatedChainId][remapperId][KECCAK_HASHING_FUNCTION].firstTimestampsBlock;

        // Load latest remapper size and root from storage
        uint256 mapperLatestSize = s.mmrs[accumulatedChainId][remapperId][KECCAK_HASHING_FUNCTION].latestSize;
        bytes32 mapperLatestRoot = s.mmrs[accumulatedChainId][remapperId][KECCAK_HASHING_FUNCTION].mmrSizeToRoot[mapperLatestSize];

        // Calculate the remapper number of leaves(number of blocks remapped) from the latest size
        uint256 mapperLeavesCount = StatelessMmrHelpers.mmrSizeToLeafCount(mapperLatestSize);

        // Create a mutable in memory copy of the MMR state
        bytes32[] memory nextPeaks = lastPeaks;
        uint256 nextSize = mapperLatestSize;
        bytes32 nextRoot = mapperLatestRoot;

        // Create mutable in memory copy of the first block number that will be appended to the remapping MMR
        uint256 nextExpectedBlockNumber = mapperStartBlock + mapperLeavesCount;

        // Iterate over the headers with proofs
        for (uint256 i = 0; i < headersWithProofs.length; i++) {
            uint256 elementsCount = headersWithProofs[i].mmrTreeSize;
            bytes32 root = s.mmrs[accumulatedChainId][headersWithProofs[i].treeId][KECCAK_HASHING_FUNCTION].mmrSizeToRoot[elementsCount];
            require(root != bytes32(0), "ERR_INVALID_TREE_ID");

            // Verify the proof against the MMR root
            StatelessMmr.verifyProof(
                headersWithProofs[i].blockProofLeafIndex,
                keccak256(headersWithProofs[i].provenBlockHeader),
                headersWithProofs[i].mmrElementInclusionProof,
                headersWithProofs[i].mmrPeaks,
                elementsCount,
                root
            );

            // Verify that the block number of the proven header is the next expected one
            uint256 blockNumber = _decodeBlockNumber(headersWithProofs[i].provenBlockHeader);
            require(blockNumber == nextExpectedBlockNumber, "ERR_UNEXPECTED_BLOCK_NUMBER");

            // Decode the timestamp from the proven header
            uint256 timestamp = _decodeBlockTimestamp(headersWithProofs[i].provenBlockHeader);

            // Append the timestamp to the remapping MMR
            (nextSize, nextRoot, nextPeaks) = StatelessMmr.appendWithPeaksRetrieval(bytes32(timestamp), nextPeaks, nextSize, nextRoot);

            // Increment the next expected block number
            nextExpectedBlockNumber++;
        }

        // Update the remapper state
        s.mmrs[accumulatedChainId][remapperId][KECCAK_HASHING_FUNCTION].latestSize = nextSize;
        s.mmrs[accumulatedChainId][remapperId][KECCAK_HASHING_FUNCTION].mmrSizeToRoot[nextSize] = nextRoot;

        RootForHashingFunction[] memory rootsForHashingFunctions = new RootForHashingFunction[](1);
        rootsForHashingFunctions[0].root = nextRoot;
        rootsForHashingFunctions[0].hashingFunction = KECCAK_HASHING_FUNCTION;

        emit IMmrCoreModule.GrownMmr(
            mapperStartBlock + mapperLeavesCount,
            nextExpectedBlockNumber - 1,
            rootsForHashingFunctions,
            nextSize,
            remapperId,
            accumulatedChainId,
            GrownBy.TIMESTAMP_REMAPPER
        );
    }

    function binsearchBlockNumberByTimestamp(
        uint256 accumulatedChainId,
        uint256 searchedRemappingId,
        uint256 searchAtSize,
        bytes32[] calldata peaks,
        uint256 timestamp,
        BinsearchPathElement[] calldata searchPath
    ) external view returns (uint256 blockNumber) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        // Ensure that remapper exists at the given id and size
        bytes32 rootAtGivenSize = s.mmrs[accumulatedChainId][searchedRemappingId][KECCAK_HASHING_FUNCTION].mmrSizeToRoot[searchAtSize];
        require(rootAtGivenSize != bytes32(0), "ERR_EMPTY_MMR_ROOT");

        uint256 remappedBlocksAmount = StatelessMmrHelpers.mmrSizeToLeafCount(searchAtSize);
        bytes32 remappedRoot = rootAtGivenSize;

        uint256 lowerBound = 0;
        uint256 upperBound = remappedBlocksAmount;

        for (uint256 i = 0; i < searchPath.length; i++) {
            uint256 leafIndex = StatelessMmrHelpers.mmrIndexToLeafIndex(searchPath[i].elementIndex);
            uint256 currentElement = (lowerBound + upperBound) / 2;
            require(leafIndex == currentElement, "ERR_INVALID_SEARCH_PATH");

            StatelessMmr.verifyProof(searchPath[i].elementIndex, searchPath[i].leafValue, searchPath[i].inclusionProof, peaks, searchAtSize, remappedRoot);

            if (timestamp < uint256(searchPath[i].leafValue)) {
                require(currentElement >= 1, "ERR_SEARCH_BOUND_OUT_OF_RANGE");
                upperBound = currentElement - 1;
            } else {
                lowerBound = currentElement;
            }
        }

        uint256 foundBlockNumber = s.mmrs[accumulatedChainId][searchedRemappingId][KECCAK_HASHING_FUNCTION].firstTimestampsBlock + lowerBound;
        return foundBlockNumber;
    }

    // TODO: Validate if these two functions are correct - if its always the indexes for block number and timestamp in all header versions
    function _decodeBlockNumber(bytes memory headerRlp) internal pure returns (uint256) {
        return RLPReader.toRLPItem(headerRlp).readList()[8].readUint256();
    }

    function _decodeBlockTimestamp(bytes memory headerRlp) internal pure returns (uint256) {
        return RLPReader.toRLPItem(headerRlp).readList()[11].readUint256();
    }
}
