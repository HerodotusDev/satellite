// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {IERC173} from "./modules/IERC173.sol";
import {ISatelliteCoreModule} from "./modules/ISatelliteCoreModule.sol";
import {ISatelliteInspectorModule} from "./modules/ISatelliteInspectorModule.sol";
import {ISatelliteMaintenanceModule} from "./modules/ISatelliteMaintenanceModule.sol";
import {ISharpFactsAggregatorModule} from "./modules/ISharpFactsAggregatorModule.sol";
import {IL1FactsRegistryModule} from "./modules/IL1FactsRegistryModule.sol";

interface ISatellite is IERC173, ISatelliteCoreModule, ISatelliteInspectorModule, ISatelliteMaintenanceModule, ISharpFactsAggregatorModule, IL1FactsRegistryModule {}
