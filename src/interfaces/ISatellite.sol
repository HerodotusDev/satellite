// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ILibSatellite} from "./ILibSatellite.sol";
import {IOwnershipModule} from "./modules/IOwnershipModule.sol";
import {ISatelliteRegistry} from "./modules/ISatelliteRegistry.sol";
import {IMMRsCoreModule} from "./modules/IMMRsCoreModule.sol";
import {ISatelliteInspectorModule} from "./modules/ISatelliteInspectorModule.sol";
import {ISatelliteMaintenanceModule} from "./modules/ISatelliteMaintenanceModule.sol";
import {INativeSharpMmrGrowingModule} from "./modules/growing/INativeSharpMmrGrowingModule.sol";
import {IStarknetSharpMmrGrowingModule} from "./modules/growing/IStarknetSharpMmrGrowingModule.sol";
import {INativeFactsRegistryModule} from "./modules/INativeFactsRegistryModule.sol";
import {INativeParentHashesFetcherModule} from "./modules/x-rollup-messaging/parent-hashes-fetchers/INativeParentHashesFetcherModule.sol";
import {IStarknetParentHashesFetcherModule} from "./modules/x-rollup-messaging/parent-hashes-fetchers/IStarknetParentHashesFetcherModule.sol";
import {INativeOnChainGrowingModule} from "./modules/growing/INativeOnChainGrowingModule.sol";
import {INativeDataProcessorModule} from "./modules/data-processor/INativeDataProcessorModule.sol";

interface ISatellite is
    ILibSatellite,
    IOwnershipModule,
    ISatelliteRegistry,
    IMMRsCoreModule,
    ISatelliteInspectorModule,
    ISatelliteMaintenanceModule,
    INativeSharpMmrGrowingModule,
    INativeFactsRegistryModule,
    INativeParentHashesFetcherModule,
    INativeOnChainGrowingModule,
    IStarknetSharpMmrGrowingModule,
    IStarknetParentHashesFetcherModule,
    INativeDataProcessorModule
{}
