import hre from "hardhat";
import fs from "fs";

async function main() {
  const chains = fs
    .readdirSync("ignition/modules")
    .filter((f) => /^\d+\.ts$/.test(f));

  for (const chain of chains) {
    const modules = require(`../ignition/modules/${chain}`).modules;
    modules.push("SatelliteMaintenanceModule");
    const outFile = `abi/${chain.replace(".ts", "")}.json`;

    const mergedAbi = [];
    for (const module of modules) {
      const abi = hre.artifacts.readArtifactSync(module).abi;
      mergedAbi.push(...abi);
    }

    const dedupedAbi = [];
    const nameToJsonString = new Map<string, string>();
    for (const abi of mergedAbi) {
      const abiJsonString = JSON.stringify(abi);
      if (nameToJsonString.has(abi.name)) {
        if (nameToJsonString.get(abi.name) !== abiJsonString) {
          throw new Error(
            `Duplicate function ${abi.name} with different parameters`,
          );
        } else {
          continue;
        }
      }
      nameToJsonString.set(abi.name, abiJsonString);
      dedupedAbi.push(abi);
    }

    fs.writeFileSync(outFile, JSON.stringify(dedupedAbi, null, 2));
  }
}

main();
