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
}
