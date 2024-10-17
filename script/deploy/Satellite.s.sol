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
import {ILibSatellite} from "interfaces/ISatellite.sol";
import {ISatelliteMaintenanceModule} from "interfaces/modules/ISatelliteMaintenanceModule.sol";

import {DeployOwnershipModule} from "./modules/DeployOwnershipModule.s.sol";
import {DeploySatelliteInspectorModule} from "./modules/DeploySatelliteInspectorModule.s.sol";
import {DeployMMRsCoreModule} from "./modules/DeployMMRsCoreModule.s.sol";
import {DeployNativeSharpMmrGrowingModule} from "./modules/DeployNativeSharpMmrGrowingModule.s.sol";
import {DeployNativeFactsRegistryModule} from "./modules/DeployNativeFactsRegistryModule.s.sol";
import {DeployNativeParentHashesFetcherModule} from "./modules/DeployNativeParentHashesFetcherModule.s.sol";

contract Deploy is Script {
    function run() external returns (address satelliteAddress) {
        //? -1 because the SatelliteMaintenanceModule is already deployed
        uint256 moduleCount = 7 - 1;
        ISatellite.ModuleMaintenance[] memory maintenances = new ISatellite.ModuleMaintenance[](moduleCount);
        IDeployModule[] memory deployModules = new IDeployModule[](moduleCount);
        deployModules[0] = new DeployOwnershipModule();
        deployModules[1] = new DeploySatelliteInspectorModule();
        deployModules[2] = new DeployMMRsCoreModule();
        deployModules[3] = new DeployNativeSharpMmrGrowingModule();
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

        satelliteAddress = address(satelliteDeployment);
        ISatellite satellite = ISatellite(satelliteAddress);
        console.log("Satellite:", address(satellite));

        for (uint256 i = 0; i < moduleCount; i++) {
            maintenances[i] = deployModules[i].deployAndPlanMaintenance(ILibSatellite.ModuleMaintenanceAction.Add);
        }

        vm.startBroadcast(deployerPrivateKey);
        satellite.satelliteMaintenance(maintenances, address(0), "");
        vm.stopBroadcast();
    }
}
