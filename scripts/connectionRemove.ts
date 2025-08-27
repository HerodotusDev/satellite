import { $ } from "bun";
import settings from "../solidity/settings.json";
import {
  getDeployedSatellites,
  parseChainId,
  STARKNET_CHAIN_IDS,
  writeDeployedSatellites,
} from "./satelliteDeploymentsManager";

function alias(address: string, shift: string) {
  const addressInt = BigInt(address);
  const shiftInt = BigInt(shift);
  const mod = BigInt("0x10000000000000000000000000000000000000000");
  const aliasInt = (addressInt + shiftInt) % mod;
  return "0x" + aliasInt.toString(16).padStart(40, "0");
}

async function main() {
  if (Bun.argv.length != 4) {
    console.error(
      "Usage: bun connection:remove <senderChainId> <receiverChainId>",
    );
    process.exit(1);
  }

  const senderChainId = parseChainId(Bun.argv[2]!);
  if (senderChainId === null) {
    console.error(`Unknown chain id: ${Bun.argv[2]}`);
    process.exit(1);
  }
  const senderSettings =
    settings[senderChainId.toString() as keyof typeof settings];
  if (!senderSettings) {
    console.error(`No settings found for chain id: ${Bun.argv[2]}`);
    process.exit(1);
  }

  const receiverChainId = parseChainId(Bun.argv[3]!);
  if (receiverChainId === null) {
    console.error(`Unknown chain id: ${Bun.argv[3]}`);
    process.exit(1);
  }
  const receiverSettings =
    settings[receiverChainId.toString() as keyof typeof settings];
  if (!receiverSettings) {
    console.error(`No settings found for chain id: ${Bun.argv[3]}`);
    process.exit(1);
  }

  const deployedSatellites = await getDeployedSatellites();

  const senderSatellite = deployedSatellites.satellites[senderChainId];
  if (!senderSatellite) {
    console.error(`No satellite deployment found for ${senderChainId}`);
    process.exit(1);
  }

  const receiverSatellite = deployedSatellites.satellites[receiverChainId];
  if (!receiverSatellite) {
    console.error(`No satellite deployment found for ${receiverChainId}`);
    process.exit(1);
  }

  const connectionData = senderSettings.connections.find(
    (c) => parseInt(c.to) === receiverChainId,
  );

  if (!connectionData) {
    console.error(
      `No connection data found for ${senderChainId} -> ${receiverChainId}`,
    );
    process.exit(1);
  }

  const senderArgs = [
    receiverChainId,
    "0x0000000000000000000000000000000000000000",
  ];

  await $`bun hardhat --network ${senderSettings.network} run scripts/connectionRemove_inner.ts`.env(
    {
      CONTRACT_ADDRESS: senderSatellite.contractAddress,
      ARGS: senderArgs.join(","),
    },
  );

  // TODO: handle starknet
  if (STARKNET_CHAIN_IDS.includes(receiverChainId)) {
    const receiverArgs = [
      senderChainId,
      alias(senderSatellite.contractAddress, connectionData.L2Alias),
    ];

    await $`bun hardhat --network ${receiverSettings.network} run scripts/connectionRemove_inner.ts`.env(
      {
        CONTRACT_ADDRESS: receiverSatellite.contractAddress,
        ARGS: receiverArgs.join(","),
      },
    );
  }

  delete senderSatellite.connections?.[receiverChainId];

  writeDeployedSatellites(deployedSatellites);
}

main();
