// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Uint256Splitter} from "src/libraries/internal/Uint256Splitter.sol";
import {IFactsRegistry} from "src/interfaces/external/IFactsRegistry.sol";
import {ISharpMmrGrowingCommon} from "src/interfaces/modules/common/ISharpMmrGrowingCommon.sol";

interface IEvmSharpMmrGrowingModule is ISharpMmrGrowingCommon {
    // Representation of the Cairo program's output (raw unpacked)
    struct EvmJobOutput {
        uint256 fromBlockNumberHigh;
        uint256 toBlockNumberLow;
        bytes32 blockNPlusOneParentHashLow;
        bytes32 blockNPlusOneParentHashHigh;
        bytes32 blockNMinusRPlusOneParentHashLow;
        bytes32 blockNMinusRPlusOneParentHashHigh;
        bytes32 mmrPreviousRootPoseidon;
        bytes32 mmrPreviousRootKeccakLow;
        bytes32 mmrPreviousRootKeccakHigh;
        uint256 mmrPreviousSize;
        bytes32 mmrNewRootPoseidon;
        bytes32 mmrNewRootKeccakLow;
        bytes32 mmrNewRootKeccakHigh;
        uint256 mmrNewSize;
    }

    // Packed representation of the Cairo program's output (for gas efficiency)
    struct JobOutputPacked {
        uint256 blockNumbersPacked;
        bytes32 blockNPlusOneParentHash;
        bytes32 blockNMinusRPlusOneParentHash;
        bytes32 mmrPreviousRootPoseidon;
        bytes32 mmrPreviousRootKeccak;
        bytes32 mmrNewRootPoseidon;
        bytes32 mmrNewRootKeccak;
        uint256 mmrSizesPacked;
    }

    struct EvmSharpMmrGrowingModuleStorage {
        IFactsRegistry factsRegistry;
        uint256 aggregatedChainId;
    }

    function initEvmSharpMmrGrowingModule(IFactsRegistry factsRegistry) external;

    function createEvmSharpMmr(uint256 newMmrId, uint256 originalMmrId, uint256 mmrSize) external;

    function aggregateEvmSharpJobs(uint256 mmrId, JobOutputPacked[] calldata outputs) external;
}
