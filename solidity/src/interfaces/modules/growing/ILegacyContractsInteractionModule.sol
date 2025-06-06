// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {IAggregatorsFactory} from "../../external/IAggregatorsFactory.sol";
import {RootForHashingFunction} from "../IMmrCoreModule.sol";

interface ILegacyContractsInteractionModule {
    function loadLegacyEvmAggregatorMmr(IAggregatorsFactory aggregatorsFactory, uint256 aggregatedChainId, uint256 legacyMmrId, uint256 newMmrId) external;
    function loadLegacyStarknetAggregatorMmr(IAggregatorsFactory aggregatorsFactory, uint256 aggregatedChainId, uint256 legacyMmrId, uint256 newMmrId) external;

    event LegacyEvmAggregatorMmrLoadedV2(
        RootForHashingFunction[] rootsForHashingFunctions,
        uint256 size,
        uint256 newMmrId,
        uint256 legacyMmrId,
        uint256 aggregatedChainId,
        address sharpFactsAggregatorAddress
    );
}
