// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {IAggregatorsFactory} from "src/interfaces/external/IAggregatorsFactory.sol";
import {RootForHashingFunction} from "src/interfaces/modules/IMmrCoreModule.sol";

interface ILegacyContractsInteractionModule {
    function initLegacyContractsInteractionModule(IAggregatorsFactory aggregatorsFactory) external;
    function loadLegacyEvmAggregatorMmr(uint256 legacyMmrId, uint256 newMmrId) external;

    struct LegacyContractsInteractionModuleStorage {
        IAggregatorsFactory aggregatorsFactory;
        uint256 aggregatedChainId;
    }

    event LegacyEvmAggregatorMmrLoaded(RootForHashingFunction[] rootsForHashingFunctions, uint256 size, uint256 newMmrId, uint256 legacyMmrId, uint256 aggregatedChainId);
}
