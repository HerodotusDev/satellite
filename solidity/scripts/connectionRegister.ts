import { $ } from "bun";
import fs from "fs";
import { ethers } from "ethers";
import settings from "../settings.json";
import {
  getDeployedSatellites,
  writeDeployedSatellites,
} from "./satelliteDeploymentsManager";
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
      "Usage: bun connection:register <senderChainId> <receiverChainId>",
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

  const deployedSatellites = await getDeployedSatellites();

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
    (deployedSatellites.connections as any[]).find(
      (c) =>
        parseInt(c.from) === parseInt(senderChainId) &&
        parseInt(c.to) === parseInt(receiverChainId),
    )
  ) {
    console.error(
      `Connection ${senderChainId} -> ${receiverChainId} already exists`,
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
    receiverSatellite.contractAddress,
    connectionData.inboxContract,
    ethers.FunctionFragment.getSelector(connectionData.sendFunction, [
      "uint256",
      "address",
      "bytes",
      "bytes",
    ]),
    "0x0000000000000000000000000000000000000000",
  ];

  await $`PRIVATE_KEY=${PRIVATE_KEY} CONTRACT_ADDRESS=${senderSatellite.contractAddress} ARGS=${senderArgs.join(",")} bun hardhat --network ${settings[senderChainId].network} run scripts/connectionRegister_inner.ts`;

  // TODO: handle starknet
  if (
    settings[receiverChainId].network != "starknetSepolia" &&
    settings[receiverChainId].network != "starknet"
  ) {
    const receiverArgs = [
      senderChainId,
      senderSatellite.contractAddress,
      "0x0000000000000000000000000000000000000000",
      "0x00000000",
      alias(senderSatellite.contractAddress, connectionData.L2Alias),
    ];

    await $`PRIVATE_KEY=${PRIVATE_KEY} CONTRACT_ADDRESS=${receiverSatellite.contractAddress} ARGS=${receiverArgs.join(",")} bun hardhat --network ${settings[receiverChainId].network} run scripts/connectionRegister_inner.ts`;
  }

  (deployedSatellites.connections as any[]).push({
    from: senderChainId,
    to: receiverChainId,
  });

  writeDeployedSatellites(deployedSatellites);
}

main();
