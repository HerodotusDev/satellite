// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatelliteMaintenanceModule} from "interfaces/modules/ISatelliteMaintenanceModule.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";
import {ISatellite} from "interfaces/ISatellite.sol";
import {AccessController} from "libraries/AccessController.sol";

contract SatelliteMaintenanceModule is ISatelliteMaintenanceModule, AccessController {
    /// @notice Add/replace/remove any number of functions and optionally exemaintenancee
    ///         a function with delegatecall
    /// @param _satelliteMaintenance Contains the module addresses and function selectors
    /// @param _init The address of the contract or module to exemaintenancee _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is exemaintenanceed with delegatecall on _init
    function satelliteMaintenance(ISatellite.ModuleMaintenance[] calldata _satelliteMaintenance, address _init, bytes calldata _calldata) external override onlyOwner {
        LibSatellite.satelliteMaintenance(_satelliteMaintenance, _init, _calldata);
    }
}
