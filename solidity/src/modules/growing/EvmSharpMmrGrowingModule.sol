// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Uint256Splitter} from "../../libraries/internal/Uint256Splitter.sol";
import {IEvmSharpMmrGrowingModule} from "../../interfaces/modules/growing/IEvmSharpMmrGrowingModule.sol";
import {ICairoFactRegistryModule} from "../../interfaces/modules/ICairoFactRegistryModule.sol";
import {ISatellite} from "../../interfaces/ISatellite.sol";
import {LibSatellite} from "../../libraries/LibSatellite.sol";
import {IMmrCoreModule, RootForHashingFunction, GrownBy} from "../../interfaces/modules/IMmrCoreModule.sol";
import {AccessController} from "../../libraries/AccessController.sol";
import {IEvmFactRegistryModule} from "../../interfaces/modules/IEvmFactRegistryModule.sol";

contract EvmSharpMmrGrowingModule is IEvmSharpMmrGrowingModule, AccessController {
    // Using inline library for efficient splitting and joining of uint256 values
    using Uint256Splitter for uint256;

    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");
    bytes32 public constant POSEIDON_HASHING_FUNCTION = keccak256("poseidon");

    // Default roots for new aggregators:
    // poseidon_hash(1, "brave new world")
    bytes32 public constant POSEIDON_MMR_INITIAL_ROOT = 0x06759138078831011e3bc0b4a135af21c008dda64586363531697207fb5a2bae;

    // keccak_hash(1, "brave new world")
    bytes32 public constant KECCAK_MMR_INITIAL_ROOT = 0x5d8d23518dd388daa16925ff9475c5d1c06430d21e0422520d6a56402f42937b;

    // ========================= Satellite Module Storage ========================= //

    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.satellite.module.storage.evm-sharp-mmr-growing");

    function moduleStorage() internal pure returns (EvmSharpMmrGrowingModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // ========================= Core Functions ========================= //

    function enableChainIdForEvmSharpMmrGrowingModule(uint256 chainId) external onlyOwner {
        EvmSharpMmrGrowingModuleStorage storage ms = moduleStorage();
        ms.chainIds[chainId] = true;
        emit ChainIdEnabledForEvmSharpMmrGrowingModule(chainId);
    }

    // Cairo program hash calculated with Poseidon (i.e., the off-chain block headers accumulator program)
    function setEvmSharpMmrGrowingModuleProgramHash(uint256 programHash) external onlyOwner {
        EvmSharpMmrGrowingModuleStorage storage ms = moduleStorage();
        ms.programHash = programHash;
    }

    function getEvmSharpMmrGrowingModuleProgramHash() external view returns (uint256) {
        EvmSharpMmrGrowingModuleStorage storage ms = moduleStorage();
        return ms.programHash;
    }

    function createEvmSharpMmr(uint256 chainId, uint256 newMmrId, uint256 originalMmrId, uint256 mmrSize) external {
        EvmSharpMmrGrowingModuleStorage storage ms = moduleStorage();
        require(ms.chainIds[chainId], "Chain ID not supported");

        bytes32[] memory hashingFunctions = new bytes32[](2);
        hashingFunctions[0] = KECCAK_HASHING_FUNCTION;
        hashingFunctions[1] = POSEIDON_HASHING_FUNCTION;

        ISatellite(address(this)).createMmrFromDomestic(newMmrId, originalMmrId, chainId, mmrSize, hashingFunctions, true);
    }

    function aggregateEvmSharpJobs(uint256 chainId, uint256 mmrId, IEvmSharpMmrGrowingModule.JobOutputPacked[] calldata outputs) external {
        EvmSharpMmrGrowingModuleStorage storage ms = moduleStorage();
        require(ms.chainIds[chainId], "Chain ID not supported");

        // Ensuring at least one job output is provided
        if (outputs.length < 1) {
            revert NotEnoughJobs();
        }

        JobOutputPacked calldata firstOutput = outputs[0];
        (uint256 fromBlock, ) = firstOutput.blockNumbersPacked.split128();

        // Ensure the first job is continuable
        _validateOutput(chainId, mmrId, fromBlock, firstOutput);

        uint256 limit = outputs.length - 1;

        // Iterate over the jobs outputs (aside from the last one)
        // and ensure jobs are correctly linked and valid
        for (uint256 i = 0; i < limit; ++i) {
            JobOutputPacked calldata curOutput = outputs[i];
            JobOutputPacked calldata nextOutput = outputs[i + 1];

            _ensureValidFact(curOutput);
            _ensureConsecutiveJobs(curOutput, nextOutput);
        }

        JobOutputPacked calldata lastOutput = outputs[limit];
        _ensureValidFact(lastOutput);

        (, uint256 mmrNewSize) = lastOutput.mmrSizesPacked.split128();

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();

        s.mmrs[chainId][mmrId][POSEIDON_HASHING_FUNCTION].mmrSizeToRoot[mmrNewSize] = lastOutput.mmrNewRootPoseidon;
        s.mmrs[chainId][mmrId][POSEIDON_HASHING_FUNCTION].latestSize = mmrNewSize;
        s.mmrs[chainId][mmrId][POSEIDON_HASHING_FUNCTION].isOffchainGrown = true;

        s.mmrs[chainId][mmrId][KECCAK_HASHING_FUNCTION].mmrSizeToRoot[mmrNewSize] = lastOutput.mmrNewRootKeccak;
        s.mmrs[chainId][mmrId][KECCAK_HASHING_FUNCTION].latestSize = mmrNewSize;
        s.mmrs[chainId][mmrId][KECCAK_HASHING_FUNCTION].isOffchainGrown = true;

        (, uint256 toBlock) = lastOutput.blockNumbersPacked.split128();

        ISatellite(address(this))._receiveParentHash(chainId, KECCAK_HASHING_FUNCTION, toBlock, lastOutput.blockNMinusRPlusOneParentHash);

        RootForHashingFunction[] memory rootsForHashingFunctions = new RootForHashingFunction[](2);
        rootsForHashingFunctions[0].root = lastOutput.mmrNewRootPoseidon;
        rootsForHashingFunctions[0].hashingFunction = POSEIDON_HASHING_FUNCTION;
        rootsForHashingFunctions[1].root = lastOutput.mmrNewRootKeccak;
        rootsForHashingFunctions[1].hashingFunction = KECCAK_HASHING_FUNCTION;

        emit IMmrCoreModule.GrownMmr(fromBlock, toBlock, rootsForHashingFunctions, mmrNewSize, mmrId, chainId, GrownBy.EVM_SHARP_GROWER);
    }

    /// @notice Allows the contract to continue from a given block, the block must be in an MMR already.
    /// @param headerProof The block header proof to verify and continue from
    function allowContinueEvmSharpGrowingFrom(uint256 chainId, ISatellite.BlockHeaderProof calldata headerProof) external {
        EvmSharpMmrGrowingModuleStorage storage ms = moduleStorage();
        require(ms.chainIds[chainId], "Chain ID not supported");

        ISatellite satellite = ISatellite(address(this));

        bytes32[15] memory fields = satellite.verifyHeader(chainId, headerProof);

        bytes32 parentHash = fields[uint8(IEvmFactRegistryModule.BlockHeaderField.PARENT_HASH)];
        uint256 blockNumber = uint256(fields[uint8(IEvmFactRegistryModule.BlockHeaderField.NUMBER)]);

        satellite._receiveParentHash(chainId, KECCAK_HASHING_FUNCTION, blockNumber, parentHash);
    }

    /// @notice Ensures the job output is cryptographically sound to continue from
    /// @param mmrId The MMR ID to validate the output for
    /// @param fromBlockNumber The parent hash of the block to start from
    /// @param firstOutput The job output to check
    function _validateOutput(uint256 chainId, uint256 mmrId, uint256 fromBlockNumber, IEvmSharpMmrGrowingModule.JobOutputPacked memory firstOutput) internal view {
        (uint256 mmrPreviousSize, ) = firstOutput.mmrSizesPacked.split128();

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        // Retrieve from cache the parent hash of the block to start from
        bytes32 fromBlockPlusOneParentHash = s.receivedParentHashes[chainId][KECCAK_HASHING_FUNCTION][fromBlockNumber + 1];
        uint256 actualMmrSizePoseidon = s.mmrs[chainId][mmrId][POSEIDON_HASHING_FUNCTION].latestSize;
        uint256 actualMmrSizeKeccak = s.mmrs[chainId][mmrId][KECCAK_HASHING_FUNCTION].latestSize;

        // Check that the job's previous MMR size is the same as the one stored in the contract state
        if (mmrPreviousSize != actualMmrSizePoseidon || mmrPreviousSize != actualMmrSizeKeccak) {
            revert AggregationError("MMR size mismatch");
        }

        if (s.mmrs[chainId][mmrId][POSEIDON_HASHING_FUNCTION].isOffchainGrown != true) {
            revert AggregationError("Poseidon MMR is not offchain grown");
        }

        if (s.mmrs[chainId][mmrId][KECCAK_HASHING_FUNCTION].isOffchainGrown != true) {
            revert AggregationError("Keccak MMR is not offchain grown");
        }

        // Check that the job's previous Poseidon MMR root is the same as the one stored in the contract state
        if (firstOutput.mmrPreviousRootPoseidon != s.mmrs[chainId][mmrId][POSEIDON_HASHING_FUNCTION].mmrSizeToRoot[mmrPreviousSize])
            revert AggregationError("Poseidon root mismatch");

        // Check that the job's previous Keccak MMR root is the same as the one stored in the contract state
        if (firstOutput.mmrPreviousRootKeccak != s.mmrs[chainId][mmrId][KECCAK_HASHING_FUNCTION].mmrSizeToRoot[mmrPreviousSize]) revert AggregationError("Keccak root mismatch");

        // If not present in the cache, hash is not authenticated and we cannot continue from it
        if (fromBlockPlusOneParentHash == bytes32(0)) {
            revert UnknownParentHash();
        }

        // we check that the job's `blockN + 1 parent hash` is matching with a previously stored parent hash
        if (firstOutput.blockNPlusOneParentHash != fromBlockPlusOneParentHash) {
            revert AggregationError("Parent hash mismatch: ensureContinuable");
        }
    }

    /// @notice Ensures the fact is regisfirstOutputon SHARP Facts Registry
    /// @param output SHARP job output (packed for Solidity)
    function _ensureValidFact(JobOutputPacked memory output) internal view {
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

        EvmSharpMmrGrowingModuleStorage storage ms = moduleStorage();

        // We compute the deterministic fact bytes32 value
        bytes32 fact = keccak256(abi.encode(ms.programHash, outputHash));

        // We ensure this fact has been registered on SHARP Facts Registry
        if (!ICairoFactRegistryModule(address(this)).isCairoFactValidForInternal(fact)) {
            revert InvalidFact();
        }
    }

    /// @notice Ensures the job outputs are correctly linked
    /// @param output The job output to check
    /// @param nextOutput The next job output to check
    function _ensureConsecutiveJobs(JobOutputPacked memory output, JobOutputPacked memory nextOutput) internal pure {
        (, uint256 toBlock) = output.blockNumbersPacked.split128();

        // We cannot aggregate further past the genesis block
        if (toBlock == 0) {
            revert GenesisBlockReached();
        }

        (uint256 nextFromBlock, ) = nextOutput.blockNumbersPacked.split128();

        // We check that the next job's `from block` is the same as the previous job's `to block + 1`
        if (toBlock - 1 != nextFromBlock) revert AggregationBlockMismatch("ensureConsecutiveJobs");

        (, uint256 outputMmrNewSize) = output.mmrSizesPacked.split128();
        (uint256 nextOutputMmrPreviousSize, ) = nextOutput.mmrSizesPacked.split128();

        // We check that the previous job's new Poseidon MMR root matches the next job's previous Poseidon MMR root
        if (output.mmrNewRootPoseidon != nextOutput.mmrPreviousRootPoseidon) revert AggregationError("Poseidon root mismatch");

        // We check that the previous job's new Keccak MMR root matches the next job's previous Keccak MMR root
        if (output.mmrNewRootKeccak != nextOutput.mmrPreviousRootKeccak) revert AggregationError("Keccak root mismatch");

        // We check that the previous job's new MMR size matches the next job's previous MMR size
        if (outputMmrNewSize != nextOutputMmrPreviousSize) revert AggregationError("MMR size mismatch");

        // We check that the previous job's lowest block hash matches the next job's highest block hash
        if (output.blockNMinusRPlusOneParentHash != nextOutput.blockNPlusOneParentHash) revert AggregationError("Parent hash mismatch: ensureConsecutiveJobs");
    }
}
