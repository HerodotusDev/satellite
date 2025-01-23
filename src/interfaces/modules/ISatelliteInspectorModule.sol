// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ILibSatellite} from "src/interfaces/ILibSatellite.sol";

interface ISatelliteInspectorModule {
    /// @notice Gets all module addresses and their four byte function selectors.
    /// @return modules_ Modules
    function modules() external view returns (ILibSatellite.Module[] memory modules_);

    /// @notice Gets all the function selectors supported by a specific module.
    /// @param _module The module address.
    /// @return moduleFunctionSelectors_
    function moduleFunctionSelectors(address _module) external view returns (bytes4[] memory moduleFunctionSelectors_);

    /// @notice Get all the module addresses used by a satellite.
    /// @return moduleAddresses_
    function moduleAddresses() external view returns (address[] memory moduleAddresses_);

    /// @notice Gets the module that supports the given selector.
    /// @dev If module is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return moduleAddress_ The module address.
    function moduleAddress(bytes4 _functionSelector) external view returns (address moduleAddress_);

    // Facet versions for compatibility

    function facets() external view returns (ILibSatellite.Module[] memory facets_);
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);
    function facetAddresses() external view returns (address[] memory facetAddresses_);
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}
