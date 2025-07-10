// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Uint256Splitter} from "../../libraries/internal/Uint256Splitter.sol";
import {ICairoFactRegistryModule} from "../../interfaces/modules/ICairoFactRegistryModule.sol";
import {IStarknetSharpMmrGrowingModule} from "../../interfaces/modules/growing/IStarknetSharpMmrGrowingModule.sol";
import {ISatellite} from "../../interfaces/ISatellite.sol";
import {LibSatellite} from "../../libraries/LibSatellite.sol";
import {IMmrCoreModule, RootForHashingFunction, GrownBy} from "../../interfaces/modules/IMmrCoreModule.sol";
import {AccessController} from "../../libraries/AccessController.sol";

contract StarknetSharpMmrGrowingModule is IStarknetSharpMmrGrowingModule, AccessController {
    bytes32 public constant POSEIDON_HASHING_FUNCTION = keccak256("poseidon");

    // Default roots for new aggregators:
    // poseidon_hash(1, "brave new world")
    bytes32 public constant POSEIDON_MMR_INITIAL_ROOT = 0x06759138078831011e3bc0b4a135af21c008dda64586363531697207fb5a2bae;

    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");

    // ========================= Satellite Module Storage ========================= //

    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.satellite.module.storage.starknet-sharp-mmr-growing");

    function moduleStorage() internal pure returns (StarknetSharpMmrGrowingModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function initStarknetSharpMmrGrowingModule(uint256 starknetChainId) external onlyOwner {
        StarknetSharpMmrGrowingModuleStorage storage ms = moduleStorage();
        ms.aggregatedChainId = starknetChainId;
    }

    // Cairo program hash calculated with Poseidon (i.e., the off-chain block headers accumulator program)
    function setStarknetSharpMmrGrowingModuleProgramHash(uint256 programHash) external onlyOwner {
        StarknetSharpMmrGrowingModuleStorage storage ms = moduleStorage();
        ms.programHash = programHash;
    }

    function getStarknetSharpMmrGrowingModuleProgramHash() external view returns (uint256) {
        StarknetSharpMmrGrowingModuleStorage storage ms = moduleStorage();
        return ms.programHash;
    }

    function createStarknetSharpMmr(uint256 newMmrId, uint256 originalMmrId, uint256 mmrSize) external {
        bytes32[] memory hashingFunctions = new bytes32[](1);
        hashingFunctions[0] = POSEIDON_HASHING_FUNCTION;

        StarknetSharpMmrGrowingModuleStorage storage ms = moduleStorage();

        ISatellite(address(this)).createMmrFromDomestic(newMmrId, originalMmrId, ms.aggregatedChainId, mmrSize, hashingFunctions, true);
    }

    function aggregateStarknetSharpJobs(uint256 mmrId, StarknetJobOutput[] calldata outputs) external {
        // Ensuring at least one job output is provided
        if (outputs.length < 1) {
            revert NotEnoughJobs();
        }

        StarknetJobOutput calldata firstOutput = outputs[0];
        uint256 fromBlock = firstOutput.fromBlockNumberHigh;

        // Ensure the first job is continuable
        _validateOutput(mmrId, fromBlock, firstOutput);

        uint256 limit = outputs.length - 1;

        // Iterate over the jobs outputs (aside from the last one)
        // and ensure jobs are correctly linked and valid
        for (uint256 i = 0; i < limit; ++i) {
            StarknetJobOutput calldata curOutput = outputs[i];
            StarknetJobOutput calldata nextOutput = outputs[i + 1];

            _ensureValidFact(curOutput);
            _ensureConsecutiveJobs(curOutput, nextOutput);
        }

        StarknetJobOutput calldata lastOutput = outputs[limit];
        _ensureValidFact(lastOutput);

        uint256 mmrNewSize = lastOutput.mmrNewSize;

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        StarknetSharpMmrGrowingModuleStorage storage ms = moduleStorage();

        s.mmrs[ms.aggregatedChainId][mmrId][POSEIDON_HASHING_FUNCTION].mmrSizeToRoot[mmrNewSize] = lastOutput.mmrNewRootPoseidon;
        s.mmrs[ms.aggregatedChainId][mmrId][POSEIDON_HASHING_FUNCTION].latestSize = mmrNewSize;
        s.mmrs[ms.aggregatedChainId][mmrId][POSEIDON_HASHING_FUNCTION].isOffchainGrown = true;

        uint256 toBlock = lastOutput.toBlockNumberLow;

        ISatellite(address(this))._receiveParentHash(ms.aggregatedChainId, POSEIDON_HASHING_FUNCTION, toBlock, lastOutput.blockNMinusRPlusOneParentHash);

        RootForHashingFunction[] memory rootsForHashingFunctions = new RootForHashingFunction[](1);
        rootsForHashingFunctions[0].root = lastOutput.mmrNewRootPoseidon;
        rootsForHashingFunctions[0].hashingFunction = POSEIDON_HASHING_FUNCTION;

        emit IMmrCoreModule.GrownMmr(fromBlock, toBlock, rootsForHashingFunctions, mmrNewSize, mmrId, ms.aggregatedChainId, GrownBy.STARKNET_SHARP_GROWER);
    }

    /// @notice Ensures the job output is cryptographically sound to continue from
    /// @param mmrId The MMR ID to validate the output for
    /// @param fromBlockNumber The parent hash of the block to start from
    /// @param firstOutput The job output to check
    function _validateOutput(uint256 mmrId, uint256 fromBlockNumber, StarknetJobOutput memory firstOutput) internal view {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        StarknetSharpMmrGrowingModuleStorage storage ms = moduleStorage();

        // Retrieve from cache the parent hash of the block to start from
        bytes32 fromBlockPlusOneParentHash = s.receivedParentHashes[ms.aggregatedChainId][POSEIDON_HASHING_FUNCTION][fromBlockNumber + 1];
        mapping(bytes32 => ISatellite.MmrInfo) storage mmrs = s.mmrs[ms.aggregatedChainId][mmrId];
        uint256 actualMmrSizePoseidon = mmrs[POSEIDON_HASHING_FUNCTION].latestSize;
        if (actualMmrSizePoseidon == LibSatellite.NO_MMR_SIZE) {
            revert AggregationError("Mmr does not exist");
        }

        if (mmrs[KECCAK_HASHING_FUNCTION].latestSize != LibSatellite.NO_MMR_SIZE) {
            revert AggregationError("Mmr has keccak hashing function");
        }

        if (s.mmrs[ms.aggregatedChainId][mmrId][POSEIDON_HASHING_FUNCTION].isOffchainGrown != true) {
            revert AggregationError("Mmr is not offchain grown");
        }

        // Check that the job's previous MMR size is the same as the one stored in the contract state
        if (firstOutput.mmrPreviousSize != actualMmrSizePoseidon) revert AggregationError("MMR size mismatch");

        // Check that the job's previous Poseidon MMR root is the same as the one stored in the contract state
        if (firstOutput.mmrPreviousRootPoseidon != s.mmrs[ms.aggregatedChainId][mmrId][POSEIDON_HASHING_FUNCTION].mmrSizeToRoot[firstOutput.mmrPreviousSize])
            revert AggregationError("Poseidon root mismatch");

        // If not present in the cache, hash is not authenticated and we cannot continue from it
        if (fromBlockPlusOneParentHash == bytes32(0)) revert UnknownParentHash();

        // we check that the job's `blockN + 1 parent hash` is matching with a previously stored parent hash
        if (firstOutput.blockNPlusOneParentHash != fromBlockPlusOneParentHash) revert AggregationError("Parent hash mismatch: ensureContinuable");
    }

    /// @notice Ensures the fact is regisfirstOutputon SHARP Facts Registry
    /// @param output SHARP job output (packed for Solidity)
    function _ensureValidFact(StarknetJobOutput memory output) internal view {
        // We assemble the outputs in a uint256 array
        uint256[] memory outputs = new uint256[](8);
        outputs[0] = uint256(output.fromBlockNumberHigh);
        outputs[1] = uint256(output.toBlockNumberLow);
        outputs[2] = uint256(output.blockNPlusOneParentHash);
        outputs[3] = uint256(output.blockNMinusRPlusOneParentHash);
        outputs[4] = uint256(output.mmrPreviousRootPoseidon);
        outputs[5] = uint256(output.mmrPreviousSize);
        outputs[6] = uint256(output.mmrNewRootPoseidon);
        outputs[7] = uint256(output.mmrNewSize);

        // We hash the outputs
        bytes32 outputHash = keccak256(abi.encodePacked(outputs));

        StarknetSharpMmrGrowingModuleStorage storage ms = moduleStorage();

        // We compute the deterministic fact bytes32 value
        bytes32 fact = keccak256(abi.encode(ms.programHash, outputHash));

        // We ensure this fact has been registered on SHARP Facts Registry
        if (!ICairoFactRegistryModule(address(this)).isCairoFactValidForInternal(fact)) revert InvalidFact();
    }

    /// @notice Ensures the job outputs are correctly linked
    /// @param output The job output to check
    /// @param nextOutput The next job output to check
    function _ensureConsecutiveJobs(StarknetJobOutput memory output, StarknetJobOutput memory nextOutput) internal pure {
        // We cannot aggregate further past the genesis block
        if (output.toBlockNumberLow == 0) revert GenesisBlockReached();
        // We check that the next job's `from block` is the same as the previous job's `to block + 1`
        if (output.toBlockNumberLow - 1 != nextOutput.fromBlockNumberHigh) revert AggregationBlockMismatch("ensureConsecutiveJobs");
        // We check that the previous job's new Poseidon MMR root matches the next job's previous Poseidon MMR root
        if (output.mmrNewRootPoseidon != nextOutput.mmrPreviousRootPoseidon) revert AggregationError("Poseidon root mismatch");
        // We check that the previous job's new MMR size matches the next job's previous MMR size
        if (output.mmrNewSize != nextOutput.mmrPreviousSize) revert AggregationError("MMR size mismatch");
        // We check that the previous job's lowest block hash matches the next job's highest block hash
        if (output.blockNMinusRPlusOneParentHash != nextOutput.blockNPlusOneParentHash) revert AggregationError("Parent hash mismatch: ensureConsecutiveJobs");
    }
}
