import { $ } from "bun";
import fs from "fs";
import { ethers } from "ethers";
import settings from "../settings.json";
import deployedSatellites from "../deployed_satellites.json";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

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

  const senderChainId = Bun.argv[2] as keyof typeof settings;
  const receiverChainId = Bun.argv[3] as keyof typeof settings;

  if (!(senderChainId in settings)) {
    console.error(`No settings found for ${senderChainId}`);
    process.exit(1);
  }

  if (!(receiverChainId in settings)) {
    console.error(`No settings found for ${receiverChainId}`);
    process.exit(1);
  }

  const senderSatellite = deployedSatellites.satellites.find(
    (s) => s.chainId === senderChainId,
  );
  if (!senderSatellite) {
    console.error(`No satellite deployment found for ${senderChainId}`);
    process.exit(1);
  }

  const receiverSatellite = deployedSatellites.satellites.find(
    (s) => s.chainId === receiverChainId,
  );
  if (!receiverSatellite) {
    console.error(`No satellite deployment found for ${receiverChainId}`);
    process.exit(1);
  }

  if (
    !(deployedSatellites.connections as any[]).find(
      (c) =>
        parseInt(c.from) === parseInt(senderChainId) &&
        parseInt(c.to) === parseInt(receiverChainId),
    )
  ) {
    console.error(
      `Connection ${senderChainId} -> ${receiverChainId} not found`,
    );
    process.exit(1);
  }

  const connectionData = settings[senderChainId].connections.find(
    (c) => c.to === receiverChainId,
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

  await $`PRIVATE_KEY=${PRIVATE_KEY} CONTRACT_ADDRESS=${senderSatellite.contractAddress} ARGS=${senderArgs.join(",")} bun hardhat --network ${settings[senderChainId].network} run scripts/connectionRemove_inner.ts`;

  // TODO: handle starknet
  if (settings[receiverChainId].network != "starknetSepolia") {
    const receiverArgs = [
      senderChainId,
      alias(senderSatellite.contractAddress, connectionData.L2Alias),
    ];

    await $`PRIVATE_KEY=${PRIVATE_KEY} CONTRACT_ADDRESS=${receiverSatellite.contractAddress} ARGS=${receiverArgs.join(",")} bun hardhat --network ${settings[receiverChainId].network} run scripts/connectionRemove_inner.ts`;
  }

  (deployedSatellites.connections as any[]) = (
    deployedSatellites.connections as any[]
  ).filter(
    (c) =>
      parseInt(c.from) !== parseInt(senderChainId) ||
      parseInt(c.to) !== parseInt(receiverChainId),
  );

  fs.writeFileSync(
    "deployed_satellites.json",
    JSON.stringify(deployedSatellites, null, 2),
  );
}

main();
