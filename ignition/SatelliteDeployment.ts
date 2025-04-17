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

export type ModuleName = keyof ReturnType<typeof moduleList>;

const buildSatelliteDeployment = (
  chainId: keyof typeof settings,
  modules: ModuleName[],
) =>
  buildModule("Satellite_" + chainId, (m) => {
    const satelliteMaintenanceModule = m.contract("SatelliteMaintenanceModule");
    const satellite = m.contract("Satellite", [satelliteMaintenanceModule]);

    const maintenances = [];
    for (const moduleName of modules) {
      const moduleData = moduleList(chainId)[moduleName];
      // If this error is unexpectedly thrown, it might be misconfiguration in settings.json.
      // Namely, variable used in ignition/modules.ts is not defined in settings.json.
      if (!moduleData)
        throw new Error(`Module ${moduleName} is not supported on ${chainId}`);

      if (!("isExternal" in moduleData && moduleData?.isExternal)) {
        maintenances.push({
          moduleAddress: m.contract(moduleName),
          action: 0, // Add
          functionSelectors: getSelector(moduleData.interfaceName),
        });
      } else {
        m.contract(moduleName);
      }
    }

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
