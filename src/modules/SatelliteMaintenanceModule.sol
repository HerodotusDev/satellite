// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ISatelliteMaintenance} from "../interfaces/ISatelliteMaintenance.sol";
import {LibSatellite} from "../libraries/LibSatellite.sol";

// Remember to add the loupe functions from SatelliteLoupeModule to the satellite.
// The loupe functions are required by the EIP2535 Satellites standard

contract SatelliteMaintenanceModule is ISatelliteMaintenance {
    /// @notice Add/replace/remove any number of functions and optionally exemaintenancee
    ///         a function with delegatecall
    /// @param _satelliteMaintenance Contains the module addresses and function selectors
    /// @param _init The address of the contract or module to exemaintenancee _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is exemaintenanceed with delegatecall on _init
    function satelliteMaintenance(ModuleMaintenance[] calldata _satelliteMaintenance, address _init, bytes calldata _calldata) external override {
        LibSatellite.enforceIsContractOwner();
        LibSatellite.satelliteMaintenance(_satelliteMaintenance, _init, _calldata);
    }
}
