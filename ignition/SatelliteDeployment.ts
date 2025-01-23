import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import hre from "hardhat";
import { ethers } from "ethers";

interface InitFunction {
  name: string;
  args: any[];
}

interface Module {
  interfaceName: string;
  moduleName: string;
  initFunction?: InitFunction;
}

function getSelector(interfaceName: string) {
  const artifacts = hre.artifacts.readArtifactSync(interfaceName);
  const selectors = artifacts.abi
    .filter((fragment) => fragment.type === "function")
    .map((fragment) => ethers.FunctionFragment.from(fragment).selector);
  return selectors;
}

const buildSatelliteDeployment = (name: string, modules: Module[]) =>
  buildModule(name, (m) => {
    const satelliteMaintenanceModule = m.contract("SatelliteMaintenanceModule");
    const satellite = m.contract("Satellite", [satelliteMaintenanceModule]);

    const maintenances = modules.map(({ moduleName, interfaceName }) => ({
      moduleAddress: m.contract(moduleName),
      action: 0, // Add
      functionSelectors: getSelector(interfaceName),
    }));

    const satelliteInterface = m.contractAt("ISatellite", satellite);

    const maintenanceFuture = m.call(
      satelliteInterface,
      "satelliteMaintenance",
      [maintenances, "0x0000000000000000000000000000000000000000", "0x"],
    );

    for (const module of modules) {
      if (module.initFunction) {
        console.log(
          "calling",
          satelliteInterface,
          module.initFunction.name,
          module.initFunction.args,
        );
        m.call(
          satelliteInterface,
          module.initFunction.name,
          module.initFunction.args,
          {
            after: [maintenanceFuture],
          },
        );
      }
    }

    // console.log(m.call(satelliteInterface, "owner", []));

    return { satellite, satelliteMaintenanceModule };
  });

export default buildSatelliteDeployment;
