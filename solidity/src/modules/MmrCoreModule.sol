// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {LibSatellite} from "../libraries/LibSatellite.sol";
import {RootForHashingFunction, IMmrCoreModule, CreatedFrom} from "../interfaces/modules/IMmrCoreModule.sol";
import {ISatellite} from "../interfaces/ISatellite.sol";
import {AccessController} from "../libraries/AccessController.sol";

// Rules about MMRs:
// isOffchainGrown = false (onchain grown MMRs) -> can have only one hashing function
// so when we branch onchain from offchain, we enforce branching only one hashing function at a time,
// isOffchainGrown = true (offchain grown MMRs) -> must have all hashing functions in sync (same elements, same size)
// so when we branch offchain from offchain, we just need to check that all sizes are the same,
// when growing offchain, we need to make sure those and only those hashing functions that are grown are present in the MMR
// if we are branching offchain from onchain, we know that the result has only one hashing function

// Invariants:
// For offchain grown MMRs, all existing MMRs (with latestSize > 0) must have the same isOffchainGrown and latestSize,
// as well as mmrSizeToRoot[latestSize] have to correspond to MMR with the same blocks accumulated but with different hashing functions.
// For onchain grown MMRs, there can only be one hashing function for which the MMR exists (i.e. latestSize > 0)

contract MmrCoreModule is IMmrCoreModule, AccessController {
    // ========================= Constants ========================= //

    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");
    bytes32 public constant POSEIDON_HASHING_FUNCTION = keccak256("poseidon");

    // Default roots for new aggregators:
    // poseidon_hash(1, "brave new world")
    bytes32 public constant POSEIDON_MMR_INITIAL_ROOT = 0x06759138078831011e3bc0b4a135af21c008dda64586363531697207fb5a2bae;

    // keccak_hash(1, "brave new world")
    bytes32 public constant KECCAK_MMR_INITIAL_ROOT = 0x5d8d23518dd388daa16925ff9475c5d1c06430d21e0422520d6a56402f42937b;

    // ========================= Other Satellite Modules Only Functions ========================= //

    /// @inheritdoc IMmrCoreModule
    function _receiveParentHash(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes32 parentHash) external onlyModule {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        s.receivedParentHashes[chainId][hashingFunction][blockNumber] = parentHash;
        emit ReceivedParentHash(chainId, blockNumber, parentHash, hashingFunction);
    }

    /// @inheritdoc IMmrCoreModule
    /// @dev Caller is trusted to provide correct values, i.e. rootsForHashingFunction contain only supported hashing functions.
    function _createMmrFromForeign(
        uint256 newMmrId,
        RootForHashingFunction[] calldata rootsForHashingFunctions,
        uint256 mmrSize,
        uint256 accumulatedChainId,
        uint256 originChainId,
        uint256 originalMmrId,
        bool isOffchainGrown
    ) external onlyModule {
        require(newMmrId != LibSatellite.EMPTY_MMR_ID, "NEW_MMR_ID_0_NOT_ALLOWED");
        require(rootsForHashingFunctions.length > 0, "INVALID_ROOTS_LENGTH");
        if (isOffchainGrown == false) {
            // Onchain grown MMRs can have only one hashing function
            require(rootsForHashingFunctions.length == 1, "INVALID_ROOTS_LENGTH");
        }

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        require(_doesMmrExist(s.mmrs[accumulatedChainId][newMmrId]) == false, "NEW_MMR_ALREADY_EXISTS");

        // Create a new MMR
        for (uint256 i = 0; i < rootsForHashingFunctions.length; i++) {
            bytes32 root = rootsForHashingFunctions[i].root;
            bytes32 hashingFunction = rootsForHashingFunctions[i].hashingFunction;

            // Roots for all hashing functions must be provided
            require(root != LibSatellite.NO_MMR_ROOT, "ROOT_0_NOT_ALLOWED");

            s.mmrs[accumulatedChainId][newMmrId][hashingFunction].latestSize = mmrSize;
            s.mmrs[accumulatedChainId][newMmrId][hashingFunction].mmrSizeToRoot[mmrSize] = root;
            s.mmrs[accumulatedChainId][newMmrId][hashingFunction].isOffchainGrown = isOffchainGrown;
        }

        emit CreatedMmr(newMmrId, mmrSize, accumulatedChainId, originalMmrId, rootsForHashingFunctions, originChainId, CreatedFrom.FOREIGN, isOffchainGrown);
    }

    // ========================= Core Functions ========================= //

    /// @inheritdoc IMmrCoreModule
    function createMmrFromDomestic(
        uint256 newMmrId,
        uint256 originalMmrId,
        uint256 accumulatedChainId,
        uint256 mmrSize,
        bytes32[] calldata hashingFunctions,
        bool isOffchainGrown
    ) external {
        require(newMmrId != LibSatellite.EMPTY_MMR_ID, "NEW_MMR_ID_0_NOT_ALLOWED");
        require(hashingFunctions.length > 0, "INVALID_HASHING_FUNCTIONS_LENGTH");
        if (isOffchainGrown == false) {
            // Onchain grown MMRs can have only one hashing function
            require(hashingFunctions.length == 1, "INVALID_HASHING_FUNCTIONS_LENGTH");
        }
        if (originalMmrId == LibSatellite.EMPTY_MMR_ID) {
            mmrSize = LibSatellite.EMPTY_MMR_SIZE;
        }

        RootForHashingFunction[] memory rootsForHashingFunctions = new RootForHashingFunction[](hashingFunctions.length);
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        require(_doesMmrExist(s.mmrs[accumulatedChainId][newMmrId]) == false, "NEW_MMR_ALREADY_EXISTS");

        bool commonIsOffchainGrown = s.mmrs[accumulatedChainId][originalMmrId][hashingFunctions[0]].isOffchainGrown;
        for (uint256 i = 0; i < hashingFunctions.length; i++) {
            bytes32 mmrRoot;
            if (originalMmrId == LibSatellite.EMPTY_MMR_ID) {
                // Create an empty MMR
                mmrRoot = _getInitialMmrRoot(hashingFunctions[i]);
            } else {
                // Load existing MMR data
                mmrRoot = s.mmrs[accumulatedChainId][originalMmrId][hashingFunctions[i]].mmrSizeToRoot[mmrSize];
                // Ensure the given MMR exists
                require(mmrRoot != LibSatellite.NO_MMR_ROOT, "SRC_MMR_NOT_FOUND");
                // Ensure the given MMR has the same isOffchainGrown value
                require(s.mmrs[accumulatedChainId][originalMmrId][hashingFunctions[i]].isOffchainGrown == commonIsOffchainGrown, "isOffchainGrown mismatch");
            }

            // Copy the MMR data to the new MMR
            s.mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].latestSize = mmrSize;
            s.mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].mmrSizeToRoot[mmrSize] = mmrRoot;
            s.mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].isOffchainGrown = isOffchainGrown;

            rootsForHashingFunctions[i] = RootForHashingFunction({hashingFunction: hashingFunctions[i], root: mmrRoot});
        }

        emit CreatedMmr(newMmrId, mmrSize, accumulatedChainId, originalMmrId, rootsForHashingFunctions, block.chainid, CreatedFrom.DOMESTIC, isOffchainGrown);
    }

    /// ========================= Internal functions ========================= //

    // Important: Both functions below need to work only for supported hashing functions.
    // Also _validateOutput of Starknet

    function _getInitialMmrRoot(bytes32 hashingFunction) internal pure returns (bytes32) {
        if (hashingFunction == KECCAK_HASHING_FUNCTION) {
            return KECCAK_MMR_INITIAL_ROOT;
        } else if (hashingFunction == POSEIDON_HASHING_FUNCTION) {
            return POSEIDON_MMR_INITIAL_ROOT;
        } else {
            revert("NOT_SUPPORTED_HASHING_FUNCTION");
        }
    }

    function _doesMmrExist(mapping(bytes32 => ISatellite.MmrInfo) storage mmrs) internal view returns (bool) {
        return mmrs[KECCAK_HASHING_FUNCTION].latestSize > 0 || mmrs[POSEIDON_HASHING_FUNCTION].latestSize > 0;
    }

    // ========================= View functions ========================= //

    function getMmrAtSize(uint256 chainId, uint256 mmrId, bytes32 hashingFunction, uint256 mmrSize) external view returns (bytes32, bool) {
        ISatellite.MmrInfo storage mmr = LibSatellite.satelliteStorage().mmrs[chainId][mmrId][hashingFunction];
        return (mmr.mmrSizeToRoot[mmrSize], mmr.isOffchainGrown);
    }

    function getLatestMmr(uint256 chainId, uint256 mmrId, bytes32 hashingFunction) external view returns (uint256, bytes32, bool) {
        ISatellite.MmrInfo storage mmr = LibSatellite.satelliteStorage().mmrs[chainId][mmrId][hashingFunction];
        return (mmr.latestSize, mmr.mmrSizeToRoot[mmr.latestSize], mmr.isOffchainGrown);
    }

    function getReceivedParentHash(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber) external view returns (bytes32) {
        return LibSatellite.satelliteStorage().receivedParentHashes[chainId][hashingFunction][blockNumber];
    }
}
