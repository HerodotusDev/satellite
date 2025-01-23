// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {LibSatellite} from "src/libraries/LibSatellite.sol";
import {RootForHashingFunction, IMmrCoreModule, CreatedFrom} from "src/interfaces/modules/IMmrCoreModule.sol";
import {ISatellite} from "src/interfaces/ISatellite.sol";
import {AccessController} from "src/libraries/AccessController.sol";

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
    function _createMmrFromForeign(
        uint256 newMmrId,
        RootForHashingFunction[] calldata rootsForHashingFunctions,
        uint256 mmrSize,
        uint256 accumulatedChainId,
        uint256 originChainId,
        uint256 originalMmrId,
        bool isSiblingSynced
    ) external onlyModule {
        require(newMmrId != LibSatellite.EMPTY_MMR_ID, "NEW_MMR_ID_0_NOT_ALLOWED");
        require(rootsForHashingFunctions.length > 0, "INVALID_ROOTS_LENGTH");

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();

        // Create a new MMR
        for (uint256 i = 0; i < rootsForHashingFunctions.length; i++) {
            bytes32 root = rootsForHashingFunctions[i].root;
            bytes32 hashingFunction = rootsForHashingFunctions[i].hashingFunction;

            require(root != LibSatellite.NO_MMR_ROOT, "ROOT_0_NOT_ALLOWED");
            require(s.mmrs[accumulatedChainId][newMmrId][hashingFunction].latestSize == LibSatellite.NO_MMR_SIZE, "NEW_MMR_ALREADY_EXISTS");
            s.mmrs[accumulatedChainId][newMmrId][hashingFunction].latestSize = mmrSize;
            s.mmrs[accumulatedChainId][newMmrId][hashingFunction].mmrSizeToRoot[mmrSize] = root;
            s.mmrs[accumulatedChainId][newMmrId][hashingFunction].isSiblingSynced = isSiblingSynced;
        }

        // Emit the event
        emit CreatedMmr(newMmrId, mmrSize, accumulatedChainId, originChainId, rootsForHashingFunctions, originalMmrId, CreatedFrom.FOREIGN);
    }

    // ========================= Core Functions ========================= //

    function createMmrFromDomestic(uint256 newMmrId, uint256 originalMmrId, uint256 accumulatedChainId, uint256 mmrSize, bytes32[] calldata hashingFunctions) external {
        require(newMmrId != LibSatellite.EMPTY_MMR_ID, "NEW_MMR_ID_0_NOT_ALLOWED");
        require(hashingFunctions.length > 0, "INVALID_HASHING_FUNCTIONS_LENGTH");

        bool isSiblingSynced = hashingFunctions.length > 1;

        if (isSiblingSynced) {
            LibSatellite.enforceIsSatelliteModule();
        }

        RootForHashingFunction[] memory rootsForHashingFunctions = new RootForHashingFunction[](hashingFunctions.length);
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();

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

                if (isSiblingSynced) {
                    require(s.mmrs[accumulatedChainId][originalMmrId][hashingFunctions[i]].isSiblingSynced == isSiblingSynced, "ORIGINAL_MMR_NOT_SIBLING_SYNCED");
                }
            }

            // Copy the MMR data to the new MMR
            s.mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].latestSize = mmrSize;
            s.mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].mmrSizeToRoot[mmrSize] = mmrRoot;
            s.mmrs[accumulatedChainId][newMmrId][hashingFunctions[i]].isSiblingSynced = isSiblingSynced;

            rootsForHashingFunctions[i] = RootForHashingFunction({hashingFunction: hashingFunctions[i], root: mmrRoot});
        }

        emit CreatedMmr(newMmrId, mmrSize, accumulatedChainId, originalMmrId, rootsForHashingFunctions, accumulatedChainId, CreatedFrom.DOMESTIC);
    }

    /// ========================= Internal functions ========================= //

    function _getInitialMmrRoot(bytes32 hashingFunction) internal pure returns (bytes32) {
        if (hashingFunction == KECCAK_HASHING_FUNCTION) {
            return KECCAK_MMR_INITIAL_ROOT;
        } else if (hashingFunction == POSEIDON_HASHING_FUNCTION) {
            return POSEIDON_MMR_INITIAL_ROOT;
        } else {
            revert("NOT_SUPPORTED_HASHING_FUNCTION");
        }
    }

    // ========================= View functions ========================= //

    function getMmrRoot(uint256 mmrId, uint256 mmrSize, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (bytes32) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.mmrs[accumulatedChainId][mmrId][hashingFunction].mmrSizeToRoot[mmrSize];
    }

    function getLatestMmrRoot(uint256 mmrId, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (bytes32) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        uint256 latestSize = s.mmrs[accumulatedChainId][mmrId][hashingFunction].latestSize;
        return s.mmrs[accumulatedChainId][mmrId][hashingFunction].mmrSizeToRoot[latestSize];
    }

    function getLatestMmrSize(uint256 mmrId, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (uint256) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.mmrs[accumulatedChainId][mmrId][hashingFunction].latestSize;
    }

    function isMMRSiblingSynced(uint256 mmrId, uint256 accumulatedChainId, bytes32 hashingFunction) external view returns (bool) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.mmrs[accumulatedChainId][mmrId][hashingFunction].isSiblingSynced;
    }

    function getReceivedParentHash(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber) external view returns (bytes32) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        return s.receivedParentHashes[chainId][hashingFunction][blockNumber];
    }

    // TODO: reconsider view functions, maybe add one to view the whole MMRInfo struct?
}
