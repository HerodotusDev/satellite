import { $ } from "bun";
import {
  getDeployedSatellites,
  parseChainId,
  STARKNET_CHAIN_IDS,
} from "./satelliteDeploymentsManager";
import { starknetDeclare, starknetUpgrade } from "./starknet";
import { starknetGetAccount } from "./starknet";

async function main() {
  if (Bun.argv.length != 3) {
    console.error("Usage: bun satellite:upgrade <chainId>");
    process.exit(1);
  }

  const chainId = parseChainId(Bun.argv[2]!)?.toString();
  if (chainId === undefined) {
    console.error("Invalid chainId");
    process.exit(1);
  }
  console.log("Upgrading satellite for chainId", chainId);

  if (chainId in STARKNET_CHAIN_IDS) {
    console.log("Upgrading satellite for Starknet");
  } else {
    await $`bun run satellite:upgrade ${chainId}`
      .nothrow()
      .env({
        ...process.env,
        FORCE_COLOR: "1",
      })
      .cwd("./solidity");
  }
}

export async function upgradeStarknetSatellite(chainId: keyof typeof STARKNET_CHAIN_IDS) {
  const deployedSatellites = await getDeployedSatellites();

  const satelliteAddress = deployedSatellites.satellites[chainId]?.contractAddress
  if (!satelliteAddress) {
    console.error(`Satellite ${chainId} not deployed`)
    process.exit(1);
  }

  const classHash = await starknetDeclare(STARKNET_CHAIN_IDS[chainId]);
  await starknetUpgrade(STARKNET_CHAIN_IDS[chainId], satelliteAddress, classHash);
}
main();


main();
