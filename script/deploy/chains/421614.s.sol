// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";

import {ContractsWithSelectors} from "script/helpers/ContractsWithSelectors.s.sol";
import {IDeploy} from "script/deploy/interfaces/IDeploy.sol";

import {Satellite} from "src/Satellite.sol";
import {SatelliteMaintenanceModule} from "src/modules/SatelliteMaintenanceModule.sol";
import {ISatellite} from "interfaces/ISatellite.sol";
import {ILibSatellite} from "interfaces/ISatellite.sol";
import {ISatelliteMaintenanceModule} from "interfaces/modules/ISatelliteMaintenanceModule.sol";

import {DeployOwnershipModule} from "../modules/DeployOwnershipModule.s.sol";
import {DeploySatelliteInspectorModule} from "../modules/DeploySatelliteInspectorModule.s.sol";
import {DeployMmrCoreModule} from "../modules/DeployMmrCoreModule.s.sol";
import {DeployNativeSharpMmrGrowingModule} from "../modules/growing/DeployNativeSharpMmrGrowingModule.s.sol";
import {DeployEVMFactRegistryModule} from "../modules/DeployEVMFactRegistryModule.s.sol";
import {DeployNativeParentHashFetcherModule} from "../modules/x-rollup-messaging/parent-hash-fetcher/DeployNativeParentHashFetcherModule.s.sol";
import {DeployNativeOnChainGrowingModule} from "../modules/growing/DeployNativeOnChainGrowingModule.s.sol";
import {DeployStarknetSharpMmrGrowingModule} from "../modules/growing/DeployStarknetSharpMmrGrowingModule.s.sol";
import {DeployStarknetParentHashFetcherModule} from "../modules/x-rollup-messaging/parent-hash-fetcher/DeployStarknetParentHashFetcherModule.s.sol";
import {DeployDataProcessorModule} from "../modules/DeployDataProcessorModule.s.sol";
import {DeploySatelliteConnectionRegistryModule} from "../modules/DeploySatelliteConnectionRegistryModule.s.sol";
import {DeploySimpleInboxModule} from "../modules/x-rollup-messaging/inbox/DeploySimpleInboxModule.s.sol";
import {DeployL1ToArbitrumMessagesSenderModule} from "../modules/x-rollup-messaging/outbox/DeployL1ToArbitrumMessagesSenderModule.s.sol";

uint256 constant numberOfModules = 10;

contract Deploy is Script {
    function run() external returns (address satelliteAddress) {
        //? -1 because the SatelliteMaintenanceModule is already deployed
        uint256 moduleCount = numberOfModules - 1;
        ISatellite.ModuleMaintenance[] memory maintenances = new ISatellite.ModuleMaintenance[](moduleCount);
        IDeploy[] memory deployModules = new IDeploy[](moduleCount);
        deployModules[0] = new DeployOwnershipModule();
        deployModules[1] = new DeploySatelliteInspectorModule();
        deployModules[2] = new DeployMmrCoreModule();
        // TODO: which modules should we keep?
        deployModules[3] = new DeployEVMFactRegistryModule();
        deployModules[4] = new DeployNativeParentHashFetcherModule();
        deployModules[5] = new DeployNativeOnChainGrowingModule();
        deployModules[6] = new DeployDataProcessorModule();
        deployModules[7] = new DeploySatelliteConnectionRegistryModule();
        deployModules[8] = new DeploySimpleInboxModule();

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
