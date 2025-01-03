// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ILibSatellite} from "./ILibSatellite.sol";
import {IOwnershipModule} from "./modules/IOwnershipModule.sol";
import {ISatelliteRegistryModule} from "./modules/ISatelliteRegistryModule.sol";
import {IMMRsCoreModule} from "./modules/IMMRsCoreModule.sol";
import {ISatelliteInspectorModule} from "./modules/ISatelliteInspectorModule.sol";
import {ISatelliteMaintenanceModule} from "./modules/ISatelliteMaintenanceModule.sol";
import {INativeSharpMmrGrowingModule} from "./modules/growing/INativeSharpMmrGrowingModule.sol";
import {IStarknetSharpMmrGrowingModule} from "./modules/growing/IStarknetSharpMmrGrowingModule.sol";
import {INativeFactsRegistryModule} from "./modules/INativeFactsRegistryModule.sol";
import {INativeParentHashesFetcherModule} from "./modules/x-rollup-messaging/parent-hashes-fetchers/INativeParentHashesFetcherModule.sol";
import {IStarknetParentHashesFetcherModule} from "./modules/x-rollup-messaging/parent-hashes-fetchers/IStarknetParentHashesFetcherModule.sol";
import {IInboxModule} from "./modules/x-rollup-messaging/inbox/IInboxModule.sol";
import {INativeOnChainGrowingModule} from "./modules/growing/INativeOnChainGrowingModule.sol";
import {INativeDataProcessorModule} from "./modules/data-processor/INativeDataProcessorModule.sol";
import {IL1ToArbitrumMessagesSenderModule} from "./modules/x-rollup-messaging/outbox/IL1ToArbitrumMessagesSenderModule.sol";
import {IL1ToOptimismMessagesSenderModule} from "./modules/x-rollup-messaging/outbox/IL1ToOptimismMessagesSenderModule.sol";

interface ISatellite is
    ILibSatellite,
    IOwnershipModule,
    ISatelliteRegistryModule,
    IMMRsCoreModule,
    ISatelliteInspectorModule,
    ISatelliteMaintenanceModule,
    INativeSharpMmrGrowingModule,
    INativeFactsRegistryModule,
    INativeParentHashesFetcherModule,
    INativeOnChainGrowingModule,
    IStarknetSharpMmrGrowingModule,
    IInboxModule,
    IL1ToArbitrumMessagesSenderModule,
    IL1ToOptimismMessagesSenderModule,
    IStarknetParentHashesFetcherModule,
    INativeDataProcessorModule
{}
