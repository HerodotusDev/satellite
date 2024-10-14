// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Uint256Splitter} from "libraries/Uint256Splitter.sol";
import {IFactsRegistry} from "interfaces/external/IFactsRegistry.sol";
import {ISharpFactsAggregatorModule} from "interfaces/modules/ISharpFactsAggregatorModule.sol";
import {ISatellite} from "interfaces/ISatellite.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";

contract SharpFactsAggregatorModule is ISharpFactsAggregatorModule {
    // Using inline library for efficient splitting and joining of uint256 values
    using Uint256Splitter for uint256;

    uint256 public constant MINIMUM_BLOCKS_CONFIRMATIONS = 20;
    uint256 public constant MAXIMUM_BLOCKS_CONFIRMATIONS = 255;

    IFactsRegistry public immutable FACTS_REGISTRY;
    uint256 public immutable AGGREGATED_CHAIN_ID;

    // Cairo program hash (i.e., the off-chain block headers accumulator program)
    bytes32 public constant PROGRAM_HASH = bytes32(uint256(0x01eca36d586f5356fba096edbf7414017d51cd0ed24b8fde80f78b61a9216ed2));

    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");
    bytes32 public constant POSEIDON_HASHING_FUNCTION = keccak256("poseidon");

    // Default roots for new aggregators:
    // poseidon_hash(1, "brave new world")
    bytes32 public constant POSEIDON_MMR_INITIAL_ROOT = 0x06759138078831011e3bc0b4a135af21c008dda64586363531697207fb5a2bae;

    // keccak_hash(1, "brave new world")
    bytes32 public constant KECCAK_MMR_INITIAL_ROOT = 0x5d8d23518dd388daa16925ff9475c5d1c06430d21e0422520d6a56402f42937b;

    constructor(uint256 aggregatedChainId, IFactsRegistry factsRegistry) {
        AGGREGATED_CHAIN_ID = aggregatedChainId;
        FACTS_REGISTRY = factsRegistry;
    }

    function aggregateSharpJobs(uint256 mmrId, uint256 fromBlockNumber, ISharpFactsAggregatorModule.JobOutputPacked[] calldata outputs) external {
        LibSatellite.enforceIsContractOwner();

        // Ensuring at least one job output is provided
        if (outputs.length < 1) {
            revert NotEnoughJobs();
        }

        JobOutputPacked calldata firstOutput = outputs[0];
        // Ensure the first job is continuable
        _validateOutput(mmrId, fromBlockNumber, firstOutput);

        uint256 limit = outputs.length - 1;

        // Iterate over the jobs outputs (aside from the last one)
        // and ensure jobs are correctly linked and valid
        for (uint256 i = 0; i < limit; ++i) {
            JobOutputPacked calldata curOutput = outputs[i];
            JobOutputPacked calldata nextOutput = outputs[i + 1];

            ensureValidFact(curOutput);
            ensureConsecutiveJobs(curOutput, nextOutput);
        }

        JobOutputPacked calldata lastOutput = outputs[limit];
        ensureValidFact(lastOutput);

        // We save the latest output in the contract state for future calls
        (, uint256 mmrNewSize) = lastOutput.mmrSizesPacked.split128();
        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();

        s.mmrs[AGGREGATED_CHAIN_ID][mmrId][POSEIDON_HASHING_FUNCTION].mmrSizeToRoot[mmrNewSize] = lastOutput.mmrNewRootPoseidon;
        s.mmrs[AGGREGATED_CHAIN_ID][mmrId][POSEIDON_HASHING_FUNCTION].latestSize = mmrNewSize;
        s.mmrs[AGGREGATED_CHAIN_ID][mmrId][POSEIDON_HASHING_FUNCTION].isSiblingSynced = true;

        s.mmrs[AGGREGATED_CHAIN_ID][mmrId][KECCAK_HASHING_FUNCTION].mmrSizeToRoot[mmrNewSize] = lastOutput.mmrNewRootKeccak;
        s.mmrs[AGGREGATED_CHAIN_ID][mmrId][KECCAK_HASHING_FUNCTION].latestSize = mmrNewSize;
        s.mmrs[AGGREGATED_CHAIN_ID][mmrId][KECCAK_HASHING_FUNCTION].isSiblingSynced = true;

        (uint256 fromBlock, ) = firstOutput.blockNumbersPacked.split128();
        (, uint256 toBlock) = lastOutput.blockNumbersPacked.split128();

        emit SharpFactsAggregate(fromBlock, toBlock, mmrNewSize, mmrId, lastOutput.mmrNewRootPoseidon, lastOutput.mmrNewRootKeccak, AGGREGATED_CHAIN_ID);
    }

    /// @notice Ensures the job output is cryptographically sound to continue from
    /// @param fromBlockNumber The parent hash of the block to start from
    /// @param firstOutput The job output to check
    function _validateOutput(uint256 mmrId, uint256 fromBlockNumber, ISharpFactsAggregatorModule.JobOutputPacked memory firstOutput) internal view {
        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        (uint256 mmrSize, ) = firstOutput.mmrSizesPacked.split128();

        uint256 actualMmrSizePoseidon = s.mmrs[AGGREGATED_CHAIN_ID][mmrId][POSEIDON_HASHING_FUNCTION].latestSize;
        uint256 actualMmrSizeKeccak = s.mmrs[AGGREGATED_CHAIN_ID][mmrId][KECCAK_HASHING_FUNCTION].latestSize;

        // Check that the job's previous MMR size is the same as the one stored in the contract state
        if (mmrSize != actualMmrSizePoseidon || mmrSize != actualMmrSizeKeccak) {
            revert AggregationError("MMR size mismatch");
        }

        if (s.mmrs[AGGREGATED_CHAIN_ID][mmrId][POSEIDON_HASHING_FUNCTION].isSiblingSynced == false) {
            revert AggregationError("Poseidon MMR not sibling synced");
        }

        if (s.mmrs[AGGREGATED_CHAIN_ID][mmrId][KECCAK_HASHING_FUNCTION].isSiblingSynced == false) {
            revert AggregationError("Keccak MMR not sibling synced");
        }

        // Check that the job's previous Poseidon MMR root is the same as the one stored in the contract state
        if (firstOutput.mmrPreviousRootPoseidon != s.mmrs[AGGREGATED_CHAIN_ID][mmrId][POSEIDON_HASHING_FUNCTION].mmrSizeToRoot[mmrSize])
            revert AggregationError("Poseidon root mismatch");

        // Check that the job's previous Keccak MMR root is the same as the one stored in the contract state
        if (firstOutput.mmrPreviousRootKeccak != s.mmrs[AGGREGATED_CHAIN_ID][mmrId][KECCAK_HASHING_FUNCTION].mmrSizeToRoot[mmrSize])
            revert AggregationError("Keccak root mismatch");

        bytes32 fromBlockParentHash = s.receivedParentHashes[AGGREGATED_CHAIN_ID][KECCAK_HASHING_FUNCTION][fromBlockNumber];

        // If not present in the cache, hash is not authenticated and we cannot continue from it
        if (fromBlockParentHash == bytes32(0)) {
            revert UnknownParentHash();
        }

        // If the right bound start parent hash __is__ specified,
        // we check that the job's `blockN + 1 parent hash` is matching with a previously stored parent hash
        if (firstOutput.blockNPlusOneParentHash != fromBlockParentHash) {
            revert AggregationError("Parent hash mismatch");
        }

        (uint256 fromBlockHighStart, ) = firstOutput.blockNumbersPacked.split128();
        // We check that block numbers are consecutives
        if (fromBlockHighStart != fromBlockNumber) {
            revert AggregationBlockMismatch();
        }
    }

    /// @notice Ensures the fact is registered on SHARP Facts Registry
    /// @param output SHARP job output (packed for Solidity)
    function ensureValidFact(JobOutputPacked memory output) internal view {
        (uint256 fromBlock, uint256 toBlock) = output.blockNumbersPacked.split128();

        (uint256 mmrPreviousSize, uint256 mmrNewSize) = output.mmrSizesPacked.split128();
        (uint256 blockNPlusOneParentHashLow, uint256 blockNPlusOneParentHashHigh) = uint256(output.blockNPlusOneParentHash).split128();

        (uint256 blockNMinusRPlusOneParentHashLow, uint256 blockNMinusRPlusOneParentHashHigh) = uint256(output.blockNMinusRPlusOneParentHash).split128();

        (uint256 mmrPreviousRootKeccakLow, uint256 mmrPreviousRootKeccakHigh) = uint256(output.mmrPreviousRootKeccak).split128();

        (uint256 mmrNewRootKeccakLow, uint256 mmrNewRootKeccakHigh) = uint256(output.mmrNewRootKeccak).split128();

        // We assemble the outputs in a uint256 array
        uint256[] memory outputs = new uint256[](14);
        outputs[0] = fromBlock;
        outputs[1] = toBlock;
        outputs[2] = blockNPlusOneParentHashLow;
        outputs[3] = blockNPlusOneParentHashHigh;
        outputs[4] = blockNMinusRPlusOneParentHashLow;
        outputs[5] = blockNMinusRPlusOneParentHashHigh;
        outputs[6] = uint256(output.mmrPreviousRootPoseidon);
        outputs[7] = mmrPreviousRootKeccakLow;
        outputs[8] = mmrPreviousRootKeccakHigh;
        outputs[9] = mmrPreviousSize;
        outputs[10] = uint256(output.mmrNewRootPoseidon);
        outputs[11] = mmrNewRootKeccakLow;
        outputs[12] = mmrNewRootKeccakHigh;
        outputs[13] = mmrNewSize;

        // We hash the outputs
        bytes32 outputHash = keccak256(abi.encodePacked(outputs));

        // We compute the deterministic fact bytes32 value
        bytes32 fact = keccak256(abi.encode(PROGRAM_HASH, outputHash));

        // We ensure this fact has been registered on SHARP Facts Registry
        if (!FACTS_REGISTRY.isValid(fact)) {
            revert InvalidFact();
        }
    }

    /// @notice Ensures the job outputs are correctly linked
    /// @param output The job output to check
    /// @param nextOutput The next job output to check
    function ensureConsecutiveJobs(JobOutputPacked memory output, JobOutputPacked memory nextOutput) internal pure {
        (, uint256 toBlock) = output.blockNumbersPacked.split128();

        // We cannot aggregate further past the genesis block
        if (toBlock == 0) {
            revert GenesisBlockReached();
        }

        (uint256 nextFromBlock, ) = nextOutput.blockNumbersPacked.split128();

        // We check that the next job's `from block` is the same as the previous job's `to block + 1`
        if (toBlock - 1 != nextFromBlock) revert AggregationBlockMismatch();

        (, uint256 outputMmrNewSize) = output.mmrSizesPacked.split128();
        (uint256 nextOutputMmrPreviousSize, ) = nextOutput.mmrSizesPacked.split128();

        // We check that the previous job's new Poseidon MMR root matches the next job's previous Poseidon MMR root
        if (output.mmrNewRootPoseidon != nextOutput.mmrPreviousRootPoseidon) revert AggregationError("Poseidon root mismatch");

        // We check that the previous job's new Keccak MMR root matches the next job's previous Keccak MMR root
        if (output.mmrNewRootKeccak != nextOutput.mmrPreviousRootKeccak) revert AggregationError("Keccak root mismatch");

        // We check that the previous job's new MMR size matches the next job's previous MMR size
        if (outputMmrNewSize != nextOutputMmrPreviousSize) revert AggregationError("MMR size mismatch");

        // We check that the previous job's lowest block hash matches the next job's highest block hash
        if (output.blockNMinusRPlusOneParentHash != nextOutput.blockNPlusOneParentHash) revert AggregationError("Parent hash mismatch");
    }
}
