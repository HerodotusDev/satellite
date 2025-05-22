import { $ } from "bun";
import hre from "hardhat";
import fs from "fs";
import {
  getDeployedSatellites,
  writeDeployedSatellites,
} from "./satelliteDeploymentsManager";

async function main() {
  if (Bun.argv.length != 3) {
    console.error("Usage: bun satellite:deploy <chainId>");
    process.exit(1);
  }

  const chainId = Bun.argv[2];
  const chainConfigs = Object.entries(hre.config.networks).filter(
    ([_, chainData]) => chainData.chainId == parseInt(chainId),
  );
  if (chainConfigs.length == 0) {
    console.error(`Chain ${chainId} not found in hardhat config`);
    process.exit(1);
  }
  if (chainConfigs.length > 1) {
    console.error(`Multiple chains found for ${chainId} in hardhat config`);
    process.exit(1);
  }

  const deployedSatellites = await getDeployedSatellites();

  const [chainName, chainConfig] = chainConfigs[0];

  if (
    (deployedSatellites.satellites as any[]).find((s) => s.chainId == chainId)
  ) {
    console.error(
      `Satellite ${chainId} already deployed\nHint: you may use "bun satellite:remove ${chainId}" or change the active environment with "bun env:change"`,
    );
    process.exit(1);
  }

  let output: string;
  let regex: RegExp;
  if (chainConfig.zksync) {
    output = (
      await $`bun run compile:zksync && bun hardhat deploy-zksync --script deploy.ts --network ${chainName}`
    ).text();
    regex = /^Satellite (\w+)$/;
  } else if (chainName == "hardhat") {
    output = (
      await $`bun run compile && bun hardhat ignition deploy ./ignition/modules/${chainId}.ts --network localhost`
    ).text();
    regex = /^Satellite_\d+\#ISatellite - (\w+)$/;
  } else {
    output = (
      await $`bun run compile && bun hardhat ignition deploy ./ignition/modules/${chainId}.ts --network ${chainName} --verify`
    ).text();
    regex = /^Satellite_\d+\#ISatellite - (\w+)$/;
  }

  let address: string | undefined;
  for (const line of output.split("\n")) {
    if (regex.test(line)) {
      const [_, addr] = line.match(regex)!;
      address = addr;
    }
  }

  if (!address) {
    console.error("Satellite address not found in output");
    process.exit(1);
  }

  (deployedSatellites.satellites as any[]).push({
    chainId,
    contractAddress: address,
  });

  writeDeployedSatellites(deployedSatellites);
}

main();
