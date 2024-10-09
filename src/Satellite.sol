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

    // Find module for function; delegate call and return result
    fallback() external payable {
        LibSatellite.SatelliteStorage storage s;
        bytes32 position = LibSatellite.DIAMOND_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
        address module = s.selectorToModuleAndPosition[msg.sig].moduleAddress;
        require(module != address(0), "Satellite: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), module, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
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
