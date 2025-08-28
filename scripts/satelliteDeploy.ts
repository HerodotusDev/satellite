import { $ } from "bun";
import {
  getDeployedSatellites,
  parseChainId,
  STARKNET_CHAIN_IDS,
  writeDeployedSatellites,
} from "./satelliteDeploymentsManager";
import fs from "fs";
import { starknetDeclare, starknetDeploy, starknetGetAccount } from "./starknet";

async function main() {
  if (Bun.argv.length != 3) {
    console.error("Usage: bun satellite:deploy <chainId>");
    process.exit(1);
  }

  const chainId = parseChainId(Bun.argv[2]!)?.toString();
  if (chainId === undefined) {
    console.error("Invalid chainId");
    process.exit(1);
  }
  console.log("Deploying satellite for chainId", chainId);

  if (chainId in STARKNET_CHAIN_IDS) {
    await deployStarknetSatellite(chainId as keyof typeof STARKNET_CHAIN_IDS);
  } else {
    await $`bun run satellite:deploy ${chainId}`
      .nothrow()
      .env({
        ...process.env,
        FORCE_COLOR: "1",
      })
      .cwd("./solidity");
  }
}

export async function deployStarknetSatellite(chainId: keyof typeof STARKNET_CHAIN_IDS) {
  const deployedSatellites = await getDeployedSatellites();

  if (deployedSatellites.satellites[chainId]) {
    console.error(
      `Satellite ${chainId} already deployed\nHint: you may use "bun satellite:remove ${Bun.argv[2]}" or change the active environment with "bun env:change"`,
    );
    process.exit(1);
  }

  const account = await starknetGetAccount(STARKNET_CHAIN_IDS[chainId]);
  const classHash = await starknetDeclare(STARKNET_CHAIN_IDS[chainId]);
  const satelliteAddress = await starknetDeploy(chainId, classHash, account);
  console.log("Satellite deployed to", satelliteAddress);

  deployedSatellites.satellites[chainId] = {
    contractAddress: satelliteAddress,
  };

  await writeDeployedSatellites(deployedSatellites);
  console.log("Satellite deployed to", satelliteAddress);
}
main();
