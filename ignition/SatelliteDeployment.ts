import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import hre from "hardhat";
import { ethers } from "ethers";
import { Module, modules as moduleList } from "./modules";
import settings from "../settings.json";

export function getSelector(interfaceName: string) {
  const artifacts = hre.artifacts.readArtifactSync(interfaceName);
  const selectors = artifacts.abi
    .filter((fragment) => fragment.type === "function")
    .map((fragment) => ethers.FunctionFragment.from(fragment).selector);
  return selectors;
}

const buildSatelliteDeployment = (
  chainId: keyof typeof settings,
  modules: (keyof ReturnType<typeof moduleList>)[],
) =>
  buildModule("Satellite_" + chainId, (m) => {
    const satelliteMaintenanceModule = m.contract("SatelliteMaintenanceModule");
    const satellite = m.contract("Satellite", [satelliteMaintenanceModule]);

    const maintenances = modules.map((moduleName) => ({
      moduleAddress: m.contract(moduleName),
      action: 0, // Add
      functionSelectors: getSelector(
        moduleList(chainId)[moduleName].interfaceName,
      ),
    }));

    const satelliteInterface = m.contractAt("ISatellite", satellite);

    const maintenanceFuture = m.call(
      satelliteInterface,
      "satelliteMaintenance",
      [maintenances, "0x0000000000000000000000000000000000000000", "0x"],
    );

    for (const moduleName of modules) {
      const funcs = (moduleList(chainId)[moduleName] as Module).initFunctions;
      if (!funcs) continue;
      for (const func of funcs) {
        m.call(satelliteInterface, func.name, func.args, {
          after: [maintenanceFuture],
        });
      }
    }

    return { satellite, satelliteMaintenanceModule };
  });

export default buildSatelliteDeployment;
