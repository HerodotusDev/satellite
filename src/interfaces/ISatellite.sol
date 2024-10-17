// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {IOwnershipModule} from "./modules/IOwnershipModule.sol";
import {ISatelliteCoreModule} from "./modules/ISatelliteCoreModule.sol";
import {ISatelliteInspectorModule} from "./modules/ISatelliteInspectorModule.sol";
import {ISatelliteMaintenanceModule} from "./modules/ISatelliteMaintenanceModule.sol";
import {INativeSharpFactsAggregatorModule} from "./modules/INativeSharpFactsAggregatorModule.sol";
import {INativeFactsRegistryModule} from "./modules/INativeFactsRegistryModule.sol";
import {INativeParentHashesFetcherModule} from "./modules/INativeParentHashesFetcherModule.sol";

interface ISatellite is
    IOwnershipModule,
    ISatelliteCoreModule,
    ISatelliteInspectorModule,
    ISatelliteMaintenanceModule,
    INativeSharpFactsAggregatorModule,
    INativeFactsRegistryModule,
    INativeParentHashesFetcherModule
{
    error MustBeSatelliteModule();
}
