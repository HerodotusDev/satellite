// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ILibSatellite} from "./ILibSatellite.sol";
import {IOwnershipModule} from "./modules/IOwnershipModule.sol";
import {ISatelliteRegistryModule} from "./modules/ISatelliteRegistryModule.sol";
import {IMmrCoreModule} from "./modules/IMmrCoreModule.sol";
import {ISatelliteInspectorModule} from "./modules/ISatelliteInspectorModule.sol";
import {ISatelliteMaintenanceModule} from "./modules/ISatelliteMaintenanceModule.sol";
import {INativeSharpMmrGrowingModule} from "./modules/growing/INativeSharpMmrGrowingModule.sol";
import {IStarknetSharpMmrGrowingModule} from "./modules/growing/IStarknetSharpMmrGrowingModule.sol";
import {IEVMFactRegistryModule} from "./modules/IEVMFactRegistryModule.sol";
import {INativeParentHashFetcherModule} from "./modules/x-rollup-messaging/parent-hash-fetcher/INativeParentHashFetcherModule.sol";
import {IStarknetParentHashFetcherModule} from "./modules/x-rollup-messaging/parent-hash-fetcher/IStarknetParentHashFetcherModule.sol";
import {IInboxModule} from "./modules/x-rollup-messaging/inbox/IInboxModule.sol";
import {INativeOnChainGrowingModule} from "./modules/growing/INativeOnChainGrowingModule.sol";
import {INativeDataProcessorModule} from "./modules/data-processor/INativeDataProcessorModule.sol";
import {IL1ToArbitrumMessagesSenderModule} from "./modules/x-rollup-messaging/outbox/IL1ToArbitrumMessagesSenderModule.sol";
import {IL1ToOptimismMessagesSenderModule} from "./modules/x-rollup-messaging/outbox/IL1ToOptimismMessagesSenderModule.sol";

interface ISatellite is
    ILibSatellite,
    IOwnershipModule,
    ISatelliteRegistryModule,
    IMmrCoreModule,
    ISatelliteInspectorModule,
    ISatelliteMaintenanceModule,
    INativeSharpMmrGrowingModule,
    IEVMFactRegistryModule,
    INativeParentHashFetcherModule,
    INativeOnChainGrowingModule,
    IStarknetSharpMmrGrowingModule,
    IInboxModule,
    IL1ToArbitrumMessagesSenderModule,
    IL1ToOptimismMessagesSenderModule,
    IStarknetParentHashFetcherModule,
    INativeDataProcessorModule
{}
