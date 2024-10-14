// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {LibSatellite} from "libraries/LibSatellite.sol";
import {ISatelliteInspectorModule} from "interfaces/modules/ISatelliteInspectorModule.sol";

contract SatelliteInspectorModule is ISatelliteInspectorModule {
    /// @notice Gets all modules and their selectors.
    /// @return modules_ Module
    function modules() external view override returns (Module[] memory modules_) {
        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        uint256 numModules = s.moduleAddresses.length;
        modules_ = new Module[](numModules);
        for (uint256 i; i < numModules; i++) {
            address moduleAddress_ = s.moduleAddresses[i];
            modules_[i].moduleAddress = moduleAddress_;
            modules_[i].functionSelectors = s.moduleFunctionSelectors[moduleAddress_].functionSelectors;
        }
    }

    /// @notice Gets all the function selectors provided by a module.
    /// @param _module The module address.
    /// @return moduleFunctionSelectors_
    function moduleFunctionSelectors(address _module) external view override returns (bytes4[] memory moduleFunctionSelectors_) {
        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        moduleFunctionSelectors_ = s.moduleFunctionSelectors[_module].functionSelectors;
    }

    /// @notice Get all the module addresses used by a satellite.
    /// @return moduleAddresses_
    function moduleAddresses() external view override returns (address[] memory moduleAddresses_) {
        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        moduleAddresses_ = s.moduleAddresses;
    }

    /// @notice Gets the module that supports the given selector.
    /// @dev If module is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return moduleAddress_ The module address.
    function moduleAddress(bytes4 _functionSelector) external view override returns (address moduleAddress_) {
        LibSatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        moduleAddress_ = s.selectorToModuleAndPosition[_functionSelector].moduleAddress;
    }
}
