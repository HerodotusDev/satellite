// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Uint256Splitter} from "libraries/internal/Uint256Splitter.sol";
import {IFactsRegistry} from "interfaces/external/IFactsRegistry.sol";
import {ISharpMmrGrowingCommon} from "interfaces/modules/growing/ISharpMmrGrowingCommon.sol";

interface IStarknetSharpMmrGrowingModule is ISharpMmrGrowingCommon {
    // Representation of the Cairo program's output
    struct StarknetJobOutput {
        uint256 fromBlockNumberHigh;
        uint256 toBlockNumberLow;
        bytes32 blockNPlusOneParentHash;
        bytes32 blockNMinusRPlusOneParentHash;
        bytes32 mmrPreviousRootPoseidon;
        uint256 mmrPreviousSize;
        bytes32 mmrNewRootPoseidon;
        uint256 mmrNewSize;
    }

    // Event emitted when __at least__ one SHARP job is aggregated
    event StarknetSharpFactsAggregate(uint256 firstAppendedBlock, uint256 lastAppendedBlock, uint256 newMmrSize, uint256 mmrId, bytes32 newPoseidonMmrRoot, uint256 chainId);

    function createStarknetSharpMmr(uint256 newMmrId, uint256 originalMmrId, uint256 mmrSize) external;

    function aggregateStarknetSharpJobs(uint256 mmrId, StarknetJobOutput[] calldata outputs) external;
}
