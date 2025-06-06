// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Uint256Splitter} from "../../../libraries/internal/Uint256Splitter.sol";
import {IFactsRegistry} from "../../../interfaces/external/IFactsRegistry.sol";
import {ISharpMmrGrowingCommon} from "../../../interfaces/modules/common/ISharpMmrGrowingCommon.sol";

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

    struct StarknetSharpMmrGrowingModuleStorage {
        IFactsRegistry factsRegistry;
        // Either Starknet or Starknet Sepolia chain ID
        uint256 aggregatedChainId;
        // Cairo program hash calculated with Poseidon (i.e., the off-chain block headers accumulator program)
        uint256 programHash;
    }

    function initStarknetSharpMmrGrowingModule(uint256 starknetChainId) external;

    function setStarknetSharpMmrGrowingModuleFactsRegistry(address factsRegistry) external;

    function setStarknetSharpMmrGrowingModuleProgramHash(uint256 programHash) external;

    function getStarknetSharpMmrGrowingModuleFactsRegistry() external view returns (address);

    function getStarknetSharpMmrGrowingModuleProgramHash() external view returns (uint256);

    function createStarknetSharpMmr(uint256 newMmrId, uint256 originalMmrId, uint256 mmrSize) external;

    function aggregateStarknetSharpJobs(uint256 mmrId, StarknetJobOutput[] calldata outputs) external;
}
