// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Lib_RLPReader as RLPReader} from "@optimism/libraries/rlp/Lib_RLPReader.sol";
import {StatelessMmr} from "@solidity-mmr/lib/StatelessMmr.sol";

interface INativeOnChainGrowingModule {
    // ========================= Types ========================= //

    struct MMRGrowResult {
        uint256 firstAppendedBlock;
        uint256 lastAppendedBlock;
        uint256 newMMRSize;
        bytes32 newMMRRoot;
    }

    // ========================= Functions ========================= //

    function onchainNativeAppendBlocksBatch(
        uint256 accumulatedChainId,
        uint256 mmrId,
        bool processFromReceivedBlockHash,
        bytes calldata ctx,
        bytes[] calldata headersSerialized
    ) external;

    // ========================= Events ========================= //

    /// @notice emitted when a batch of blocks is appended to the MMR
    /// @param result MMRGrowResult struct containing firstAppendedBlock, lastAppendedBlock, newMMRSize, newMMRRoot
    /// @param mmrId the ID of the MMR that was updated
    /// @dev hashingFunction is a 32 byte keccak hash of the hashing function name, eg: keccak256("keccak256"), keccak256("poseidon")
    /// @param hashingFunction the hashing function used to calculate the MMR
    /// @param accumulatedChainId the ID of the chain that the MMR accumulates
    event NativeOnChainGrowMMR(MMRGrowResult result, uint256 mmrId, bytes32 hashingFunction, uint256 accumulatedChainId);
}
