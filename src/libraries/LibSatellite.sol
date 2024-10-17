// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";
import {ISatellite} from "interfaces/ISatellite.sol";
import {ILibSatellite} from "interfaces/ILibSatellite.sol";

library LibSatellite {
    // ========================= Constants ========================= //
    /// @notice non existent MMR size
    uint256 constant NO_MMR_SIZE = 0;
    /// @notice non existent MMR root
    bytes32 constant NO_MMR_ROOT = 0;
    /// @notice non existent MMR id
    uint256 constant EMPTY_MMR_ID = 0;
    /// @notice empty MMR size
    uint256 constant EMPTY_MMR_SIZE = 1;
    /// @notice diamond storage position
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.satellite.storage");

    function satelliteStorage() internal pure returns (ILibSatellite.SatelliteStorage storage s) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function setContractOwner(address _newOwner) internal {
        ILibSatellite.SatelliteStorage storage s = satelliteStorage();
        address previousOwner = s.contractOwner;
        s.contractOwner = _newOwner;
        emit ILibSatellite.OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = satelliteStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == satelliteStorage().contractOwner, "LibSatellite: Must be contract owner");
    }

    function enforceIsSatelliteModule() internal view {
        if (msg.sender != address(this)) {
            revert ILibSatellite.MustBeSatelliteModule();
        }
    }

    event SatelliteMaintenance(ILibSatellite.ModuleMaintenance[] _satelliteMaintenance, address _init, bytes _calldata);

    function satelliteMaintenance(ILibSatellite.ModuleMaintenance[] memory _satelliteMaintenance, address _init, bytes memory _calldata) internal {
        for (uint256 moduleIndex; moduleIndex < _satelliteMaintenance.length; moduleIndex++) {
            ILibSatellite.ModuleMaintenance memory moduleMaintenance = _satelliteMaintenance[moduleIndex];
            ILibSatellite.ModuleMaintenanceAction action = moduleMaintenance.action;
            if (action == ILibSatellite.ModuleMaintenanceAction.Add) {
                addFunctions(moduleMaintenance.moduleAddress, moduleMaintenance.functionSelectors);
            } else if (action == ILibSatellite.ModuleMaintenanceAction.Replace) {
                replaceFunctions(moduleMaintenance.moduleAddress, moduleMaintenance.functionSelectors);
            } else if (action == ILibSatellite.ModuleMaintenanceAction.Remove) {
                removeFunctions(moduleMaintenance.moduleAddress, moduleMaintenance.functionSelectors);
            } else {
                revert("LibSatelliteMaintenance: Incorrect ILibSatellite.ModuleMaintenanceAction");
            }
        }
        emit SatelliteMaintenance(_satelliteMaintenance, _init, _calldata);
        initializeSatelliteMaintenance(_init, _calldata);
    }

    function addFunctions(address _moduleAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibSatelliteMaintenance: No selectors in module to maintenance");
        ILibSatellite.SatelliteStorage storage s = satelliteStorage();
        require(_moduleAddress != address(0), "LibSatelliteMaintenance: Add module can't be address(0)");
        uint96 selectorPosition = uint96(s.moduleFunctionSelectors[_moduleAddress].functionSelectors.length);
        /// @dev add new module address if it does not exist
        if (selectorPosition == 0) {
            addModule(s, _moduleAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldModuleAddress = s.selectorToModuleAndPosition[selector].moduleAddress;
            require(oldModuleAddress == address(0), "LibSatelliteMaintenance: Can't add function that already exists");
            addFunction(s, selector, selectorPosition, _moduleAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _moduleAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibSatelliteMaintenance: No selectors in module to maintenance");
        ILibSatellite.SatelliteStorage storage s = satelliteStorage();
        require(_moduleAddress != address(0), "LibSatelliteMaintenance: Add module can't be address(0)");
        uint96 selectorPosition = uint96(s.moduleFunctionSelectors[_moduleAddress].functionSelectors.length);
        /// @dev add new module address if it does not exist
        if (selectorPosition == 0) {
            addModule(s, _moduleAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldModuleAddress = s.selectorToModuleAndPosition[selector].moduleAddress;
            require(oldModuleAddress != _moduleAddress, "LibSatelliteMaintenance: Can't replace function with same function");
            removeFunction(s, oldModuleAddress, selector);
            addFunction(s, selector, selectorPosition, _moduleAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _moduleAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibSatelliteMaintenance: No selectors in module to maintenance");
        ILibSatellite.SatelliteStorage storage s = satelliteStorage();
        /// @dev if function does not exist then do nothing and return
        require(_moduleAddress == address(0), "LibSatelliteMaintenance: Remove module address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldModuleAddress = s.selectorToModuleAndPosition[selector].moduleAddress;
            removeFunction(s, oldModuleAddress, selector);
        }
    }

    function addModule(ILibSatellite.SatelliteStorage storage s, address _moduleAddress) internal {
        enforceHasContractCode(_moduleAddress, "LibSatelliteMaintenance: New module has no code");
        s.moduleFunctionSelectors[_moduleAddress].moduleAddressPosition = s.moduleAddresses.length;
        s.moduleAddresses.push(_moduleAddress);
    }

    function addFunction(ILibSatellite.SatelliteStorage storage s, bytes4 _selector, uint96 _selectorPosition, address _moduleAddress) internal {
        s.selectorToModuleAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        s.moduleFunctionSelectors[_moduleAddress].functionSelectors.push(_selector);
        s.selectorToModuleAndPosition[_selector].moduleAddress = _moduleAddress;
    }

    function removeFunction(ILibSatellite.SatelliteStorage storage s, address _moduleAddress, bytes4 _selector) internal {
        require(_moduleAddress != address(0), "LibSatelliteMaintenance: Can't remove function that doesn't exist");
        /// @dev an immutable function is a function defined directly in a satellite
        require(_moduleAddress != address(this), "LibSatelliteMaintenance: Can't remove immutable function");
        uint256 selectorPosition = s.selectorToModuleAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = s.moduleFunctionSelectors[_moduleAddress].functionSelectors.length - 1;
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = s.moduleFunctionSelectors[_moduleAddress].functionSelectors[lastSelectorPosition];
            s.moduleFunctionSelectors[_moduleAddress].functionSelectors[selectorPosition] = lastSelector;
            s.selectorToModuleAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        s.moduleFunctionSelectors[_moduleAddress].functionSelectors.pop();
        delete s.selectorToModuleAndPosition[_selector];

        /// @dev if no more selectors for module address then delete the module address
        if (lastSelectorPosition == 0) {
            uint256 lastModuleAddressPosition = s.moduleAddresses.length - 1;
            uint256 moduleAddressPosition = s.moduleFunctionSelectors[_moduleAddress].moduleAddressPosition;
            if (moduleAddressPosition != lastModuleAddressPosition) {
                address lastModuleAddress = s.moduleAddresses[lastModuleAddressPosition];
                s.moduleAddresses[moduleAddressPosition] = lastModuleAddress;
                s.moduleFunctionSelectors[lastModuleAddress].moduleAddressPosition = moduleAddressPosition;
            }
            s.moduleAddresses.pop();
            delete s.moduleFunctionSelectors[_moduleAddress].moduleAddressPosition;
        }
    }

    function initializeSatelliteMaintenance(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibSatelliteMaintenance: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibSatelliteMaintenance: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibSatelliteMaintenance: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    revert(string(error));
                } else {
                    revert("LibSatelliteMaintenance: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}
