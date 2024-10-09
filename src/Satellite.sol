// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibSatellite} from "./libraries/LibSatellite.sol";
import {ISatelliteMaintenance} from "./interfaces/ISatelliteMaintenance.sol";

/// @dev Shines like a Diamond
contract Satellite {
    constructor(address _contractOwner, address _satelliteMaintenanceModule) payable {
        LibSatellite.setContractOwner(_contractOwner);

        // Add the satelliteMaintenance external function from the satelliteMaintenanceModule
        ISatelliteMaintenance.ModuleMaintenance[] memory maintenance = new ISatelliteMaintenance.ModuleMaintenance[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = ISatelliteMaintenance.satelliteMaintenance.selector;
        maintenance[0] = ISatelliteMaintenance.ModuleMaintenance({
            moduleAddress: _satelliteMaintenanceModule,
            action: ISatelliteMaintenance.ModuleMaintenanceAction.Add,
            functionSelectors: functionSelectors
        });
        LibSatellite.satelliteMaintenance(maintenance, address(0), "");
    }

    // Find module for function that is called and execute the
    // function if a module is found and return any value.
    fallback() external payable {
        LibSatellite.SatelliteStorage storage s;
        bytes32 position = LibSatellite.DIAMOND_STORAGE_POSITION;
        // get satellite storage
        assembly {
            s.slot := position
        }
        // get module from function selector
        address module = s.selectorToModuleAndPosition[msg.sig].moduleAddress;
        require(module != address(0), "Satellite: Function does not exist");
        // Execute external function from module using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the module
            let result := delegatecall(gas(), module, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
