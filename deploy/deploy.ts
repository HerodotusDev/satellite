import { deployContract, getWallet } from "./utils";
import hre from "hardhat";
import { modules } from "../ignition/modules/300";
import { getSelector } from "../ignition/SatelliteDeployment";
import { Module, modules as moduleList } from "../ignition/modules";

const chainId = "300";

export default async function () {
  const satelliteMaintenance = await (
    await deployContract("SatelliteMaintenanceModule", [])
  ).getAddress();

  const satellite = await (
    await deployContract("Satellite", [satelliteMaintenance])
  ).getAddress();

  console.log("Satellite", satellite);

  const satelliteContract = new hre.ethers.Contract(
    satellite,
    hre.artifacts.readArtifactSync("ISatellite").abi,
    getWallet(),
  );

  const maintenances = [];
  for (const moduleName of modules) {
    const moduleAddress = (await deployContract(moduleName, [])).getAddress();

    maintenances.push({
      moduleAddress,
      action: 0, // Add
      functionSelectors: getSelector(
        (moduleList(chainId)[moduleName] as Module).interfaceName,
      ),
    });
  }

  await satelliteContract.satelliteMaintenance(
    maintenances,
    "0x0000000000000000000000000000000000000000",
    "0x",
  );

  for (const moduleName of modules) {
    const funcs = (moduleList(chainId)[moduleName] as Module).initFunctions;
    if (!funcs) continue;
    for (const func of funcs) {
      await satelliteContract[func.name](...func.args);
    }
  }
}
