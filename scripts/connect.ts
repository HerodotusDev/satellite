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
    console.error("Usage: bun connect.ts <senderChainId> <receiverChainId>");
    process.exit(1);
  }

  const senderChainId = Bun.argv[2] as keyof typeof settings;
  const receiverChainId = Bun.argv[3] as keyof typeof settings;

  if (!(senderChainId in settings)) {
    throw new Error(`No settings found for ${senderChainId}`);
  }

  if (!(receiverChainId in settings)) {
    throw new Error(`No settings found for ${receiverChainId}`);
  }

  const senderSatellite = deployedSatellites.satellites.find(
    (s) => s.chainId === senderChainId,
  );
  if (!senderSatellite) {
    throw new Error(`No satellite deployment found for ${senderChainId}`);
  }

  const receiverSatellite = deployedSatellites.satellites.find(
    (s) => s.chainId === receiverChainId,
  );
  if (!receiverSatellite) {
    throw new Error(`No satellite deployment found for ${receiverChainId}`);
  }

  if (
    deployedSatellites.connections.find(
      (c) =>
        parseInt(c.from) === parseInt(senderChainId) &&
        parseInt(c.to) === parseInt(receiverChainId),
    )
  ) {
    throw new Error(
      `Connection already exists for ${senderChainId} -> ${receiverChainId}`,
    );
  }

  const connectionData = settings[senderChainId].connections.find(
    (c) => c.to === receiverChainId,
  );
  if (!connectionData) {
    throw new Error(
      `No connection data found for ${senderChainId} -> ${receiverChainId}`,
    );
  }

  const senderArgs = [
    receiverChainId,
    receiverSatellite.contractAddress,
    connectionData.inboxContract,
    "0x0000000000000000000000000000000000000000",
    ethers.FunctionFragment.getSelector(connectionData.sendFunction, [
      "uint256",
      "address",
      "bytes",
      "bytes",
    ]),
  ];

  await $`PRIVATE_KEY=${PRIVATE_KEY} CONTRACT_ADDRESS=${senderSatellite.contractAddress} ARGS=${senderArgs.join(",")} bun hardhat --network ${settings[senderChainId].network} run scripts/registerSatelliteConnection.ts`;

  const receiverArgs = [
    senderChainId,
    senderSatellite.contractAddress,
    "0x0000000000000000000000000000000000000000",
    alias(senderSatellite.contractAddress, connectionData.L2Alias),
    "0x00000000",
  ];

  await $`PRIVATE_KEY=${PRIVATE_KEY} CONTRACT_ADDRESS=${receiverSatellite.contractAddress} ARGS=${receiverArgs.join(",")} bun hardhat --network ${settings[receiverChainId].network} run scripts/registerSatelliteConnection.ts`;

  deployedSatellites.connections.push({
    from: senderChainId,
    to: receiverChainId,
  });

  fs.writeFileSync(
    "deployed_satellites.json",
    JSON.stringify(deployedSatellites, null, 4),
  );
}

main();
