// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC173} from "./modules/IERC173.sol";
import {ISatelliteCoreModule} from "./modules/ISatelliteCoreModule.sol";
import {ISatelliteInspectorModule} from "./modules/ISatelliteInspectorModule.sol";
import {ISatelliteMaintenanceModule} from "./modules/ISatelliteMaintenanceModule.sol";
import {ISharpFactsAggregatorModule} from "./modules/ISharpFactsAggregatorModule.sol";

interface ISatellite is IERC173, ISatelliteCoreModule, ISatelliteInspectorModule, ISatelliteMaintenanceModule, ISharpFactsAggregatorModule {}
