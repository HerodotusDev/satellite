// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface ISatelliteMaintenanceModule {
    /// @dev Add=0, Replace=1, Remove=2
    enum ModuleMaintenanceAction {
        Add,
        Replace,
        Remove
    }

    struct ModuleMaintenance {
        address moduleAddress;
        ModuleMaintenanceAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally exemaintenancee
    ///         a function with delegatecall
    /// @param _satelliteMaintenance Contains the module addresses and function selectors
    /// @param _init The address of the contract or module to exemaintenancee _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is exemaintenanceed with delegatecall on _init
    function satelliteMaintenance(ModuleMaintenance[] calldata _satelliteMaintenance, address _init, bytes calldata _calldata) external;

    event SatelliteMaintenance(ModuleMaintenance[] _satelliteMaintenance, address _init, bytes _calldata);
}
