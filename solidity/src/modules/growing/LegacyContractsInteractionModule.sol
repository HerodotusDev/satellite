// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ILegacyContractsInteractionModule} from "src/interfaces/modules/growing/ILegacyContractsInteractionModule.sol";
import {IAggregatorsFactory} from "src/interfaces/external/IAggregatorsFactory.sol";
import {AccessController} from "src/libraries/AccessController.sol";
import {ISharpFactsAggregator} from "src/interfaces/external/ISharpFactsAggregator.sol";
import {ISatellite} from "src/interfaces/ISatellite.sol";
import {LibSatellite} from "src/libraries/LibSatellite.sol";
import {RootForHashingFunction} from "src/interfaces/modules/IMmrCoreModule.sol";

contract LegacyContractsInteractionModule is ILegacyContractsInteractionModule, AccessController {
    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");
    bytes32 public constant POSEIDON_HASHING_FUNCTION = keccak256("poseidon");

    // ========================= Core Functions ========================= //

    //? Use this for Ethereum Sepolia: 0x70c61dd17b7207b450cb7dedc92c1707a07a1213
    //? Use this for Ethereum Mainnet: 0x5C189aEdEcBc07830B64Ec8CAE51ce38E4365286
    function loadLegacyEvmAggregatorMmr(IAggregatorsFactory aggregatorsFactory, uint256 aggregatedChainId, uint256 legacyMmrId, uint256 newMmrId) external onlyOwner {
        address sharpFactsAggregatorAddress = aggregatorsFactory.aggregatorsById(legacyMmrId);
        ISharpFactsAggregator sharpFactsAggregator = ISharpFactsAggregator(sharpFactsAggregatorAddress);

        bytes32 keccakRoot = sharpFactsAggregator.getMMRKeccakRoot();
        bytes32 poseidonRoot = sharpFactsAggregator.getMMRPoseidonRoot();
        uint256 size = sharpFactsAggregator.getMMRSize();

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();

        s.mmrs[aggregatedChainId][newMmrId][POSEIDON_HASHING_FUNCTION].mmrSizeToRoot[size] = poseidonRoot;
        s.mmrs[aggregatedChainId][newMmrId][POSEIDON_HASHING_FUNCTION].latestSize = size;
        s.mmrs[aggregatedChainId][newMmrId][POSEIDON_HASHING_FUNCTION].isOffchainGrown = true;

        s.mmrs[aggregatedChainId][newMmrId][KECCAK_HASHING_FUNCTION].mmrSizeToRoot[size] = keccakRoot;
        s.mmrs[aggregatedChainId][newMmrId][KECCAK_HASHING_FUNCTION].latestSize = size;
        s.mmrs[aggregatedChainId][newMmrId][KECCAK_HASHING_FUNCTION].isOffchainGrown = true;

        RootForHashingFunction[] memory rootsForHashingFunctions = new RootForHashingFunction[](2);
        rootsForHashingFunctions[0].root = poseidonRoot;
        rootsForHashingFunctions[0].hashingFunction = POSEIDON_HASHING_FUNCTION;
        rootsForHashingFunctions[1].root = keccakRoot;
        rootsForHashingFunctions[1].hashingFunction = KECCAK_HASHING_FUNCTION;

        emit LegacyEvmAggregatorMmrLoadedV2(rootsForHashingFunctions, size, newMmrId, legacyMmrId, aggregatedChainId, sharpFactsAggregatorAddress);
    }

    function loadLegacyStarknetAggregatorMmr(IAggregatorsFactory aggregatorsFactory, uint256 aggregatedChainId, uint256 legacyMmrId, uint256 newMmrId) external onlyOwner {
        address sharpFactsAggregatorAddress = aggregatorsFactory.aggregatorsById(legacyMmrId);
        ISharpFactsAggregator sharpFactsAggregator = ISharpFactsAggregator(sharpFactsAggregatorAddress);

        bytes32 poseidonRoot = sharpFactsAggregator.getMMRPoseidonRoot();
        uint256 size = sharpFactsAggregator.getMMRSize();

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();

        mapping(bytes32 => ISatellite.MmrInfo) storage mmrs = s.mmrs[aggregatedChainId][newMmrId];
        require(
            mmrs[POSEIDON_HASHING_FUNCTION].latestSize == LibSatellite.NO_MMR_SIZE && mmrs[KECCAK_HASHING_FUNCTION].latestSize == LibSatellite.NO_MMR_SIZE,
            "MMR_ALREADY_EXISTS"
        );

        ISatellite.MmrInfo storage mmr = mmrs[POSEIDON_HASHING_FUNCTION];
        mmr.mmrSizeToRoot[size] = poseidonRoot;
        mmr.latestSize = size;
        mmr.isOffchainGrown = true;

        RootForHashingFunction[] memory rootsForHashingFunctions = new RootForHashingFunction[](1);
        rootsForHashingFunctions[0].root = poseidonRoot;
        rootsForHashingFunctions[0].hashingFunction = POSEIDON_HASHING_FUNCTION;

        emit LegacyEvmAggregatorMmrLoadedV2(rootsForHashingFunctions, size, newMmrId, legacyMmrId, aggregatedChainId, sharpFactsAggregatorAddress);
    }
}
