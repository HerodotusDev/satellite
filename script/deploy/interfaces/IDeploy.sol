// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {ISatellite} from "interfaces/ISatellite.sol";
import {ILibSatellite} from "interfaces/ILibSatellite.sol";

import {ISatelliteMaintenanceModule} from "interfaces/modules/ISatelliteMaintenanceModule.sol";
import {ContractsWithSelectors} from "script/helpers/ContractsWithSelectors.s.sol";

abstract contract IDeploy is Script {
    uint256 constant MAINNET = 1;
    uint256 constant SEPOLIA = 11155111;
    uint256 SN_MAINNET = 0x534e5f4d41494e;
    uint256 SN_SEPOLIA = 0x534e5f5345504f4c4941;

    function deploy() internal virtual returns (address moduleAddress);

    function deployAndPlanMaintenance(ISatellite.ModuleMaintenanceAction action) public returns (ISatellite.ModuleMaintenance memory maintenance) {
        ContractsWithSelectors contractsWithSelectors = new ContractsWithSelectors();
        address moduleAddress = deploy();
        console.log("%s:", getContractName(), moduleAddress);
        bytes4[] memory functionSelectors = contractsWithSelectors.getSelectors(getContractName());

        maintenance = ILibSatellite.ModuleMaintenance({moduleAddress: moduleAddress, action: action, functionSelectors: functionSelectors});
    }

    function run() external {
        address satelliteAddress = vm.envAddress("DEPLOYED_SATELLITE_ADDRESS");
        require(satelliteAddress != address(0), "Satellite address is not set");
        console.log("Maintenance on deployed Satellite:", satelliteAddress);

        ISatellite satellite = ISatellite(satelliteAddress);
        ISatellite.ModuleMaintenance[] memory maintenances = new ISatellite.ModuleMaintenance[](1);
        maintenances[0] = deployAndPlanMaintenance(ILibSatellite.ModuleMaintenanceAction.Replace);

        vm.startBroadcast(getPrivateKey());
        satellite.satelliteMaintenance(maintenances, address(0), "");
        vm.stopBroadcast();
    }

    function getContractName() public view virtual returns (string memory);

    function getPrivateKey() internal view returns (uint256 privateKey) {
        privateKey = vm.envUint("PRIVATE_KEY");
    }

    function getStarknetChainId() internal view returns (uint256 chainId) {
        if (block.chainid == MAINNET) chainId = SN_MAINNET;
        else if (block.chainid == SEPOLIA) chainId = SN_SEPOLIA;
        else revert("StarknetSharpMmrGrowingModule doesnt support this chainId");
    }
}
