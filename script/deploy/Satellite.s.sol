// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";

import {ContractsWithSelectors} from "script/helpers/ContractsWithSelectors.s.sol";
import {IDeployModule} from "script/deploy/interfaces/IDeployModule.sol";

import {Satellite} from "src/Satellite.sol";
import {SatelliteMaintenanceModule} from "src/modules/SatelliteMaintenanceModule.sol";
import {ISatellite} from "interfaces/ISatellite.sol";
import {ISatelliteMaintenanceModule} from "interfaces/modules/ISatelliteMaintenanceModule.sol";

import {DeployOwnershipModule} from "./modules/DeployOwnershipModule.s.sol";
import {DeploySatelliteInspectorModule} from "./modules/DeploySatelliteInspectorModule.s.sol";
import {DeploySatelliteCoreModule} from "./modules/DeploySatelliteCoreModule.s.sol";
import {DeploySharpFactsAggregatorModule} from "./modules/DeploySharpFactsAggregatorModule.s.sol";
import {DeployNativeFactsRegistryModule} from "./modules/DeployNativeFactsRegistryModule.s.sol";
import {DeployNativeParentHashesFetcherModule} from "./modules/DeployNativeParentHashesFetcherModule.s.sol";

contract Deploy is Script {
    function run() external {
        //? -1 because the SatelliteMaintenanceModule is already deployed
        uint256 moduleCount = 7 - 1;
        ISatelliteMaintenanceModule.ModuleMaintenance[] memory maintenances = new ISatelliteMaintenanceModule.ModuleMaintenance[](moduleCount);
        IDeployModule[] memory deployModules = new IDeployModule[](moduleCount);
        deployModules[0] = new DeployOwnershipModule();
        deployModules[1] = new DeploySatelliteInspectorModule();
        deployModules[2] = new DeploySatelliteCoreModule();
        deployModules[3] = new DeploySharpFactsAggregatorModule();
        deployModules[4] = new DeployNativeFactsRegistryModule();
        deployModules[5] = new DeployNativeParentHashesFetcherModule();

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        SatelliteMaintenanceModule satelliteMaintenanceModule = new SatelliteMaintenanceModule();
        vm.stopBroadcast();
        address satelliteMaintenanceModuleAddress = address(satelliteMaintenanceModule);
        console.log("SatelliteMaintenanceModule:", address(satelliteMaintenanceModuleAddress));
        vm.startBroadcast(deployerPrivateKey);
        Satellite satelliteDeployment = new Satellite(satelliteMaintenanceModuleAddress);
        vm.stopBroadcast();

        ISatellite satellite = ISatellite(address(satelliteDeployment));
        console.log("Satellite:", address(satellite));

        for (uint256 i = 0; i < moduleCount; i++) {
            maintenances[i] = deployModules[i].deployAndPlanMaintenance(ISatelliteMaintenanceModule.ModuleMaintenanceAction.Add);
        }

        vm.startBroadcast(deployerPrivateKey);
        satellite.satelliteMaintenance(maintenances, address(0), "");
        vm.stopBroadcast();
    }
}
