import { $ } from "bun";
import { ethers } from "ethers";
import settings from "../solidity/settings.json";
import {
  getDeployedSatellites,
  parseChainId,
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
      "Usage: bun connection:register <senderChainId> <receiverChainId>",
    );
    process.exit(1);
  }

  const senderChainId = parseChainId(Bun.argv[2]!)?.toString();
  const receiverChainId = parseChainId(Bun.argv[3]!)?.toString();

  if (senderChainId === undefined) {
    console.error(`Invalid senderChainId: ${Bun.argv[2]}`);
    process.exit(1);
  }

  if (receiverChainId === undefined) {
    console.error(`Invalid receiverChainId: ${Bun.argv[3]}`);
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

  if (senderSatellite.connections?.[receiverChainId]) {
    console.error(
      `Connection ${senderChainId} -> ${receiverChainId} already exists`,
    );
    process.exit(1);
  }

  const senderSettings = settings[senderChainId as keyof typeof settings];
  const receiverSettings = settings[receiverChainId as keyof typeof settings];

  const connectionData = senderSettings.connections.find(
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

  await $`bun hardhat --network ${senderSettings.network} run scripts/connectionRegisterEvm.ts`
    .env({
      ...process.env,
      CONTRACT_ADDRESS: senderSatellite.contractAddress,
      ARGS: senderArgs.join(","),
    })
    .cwd("./solidity");

  // TODO: handle starknet
  if (
    receiverSettings.network != "starknetSepolia" &&
    receiverSettings.network != "starknet"
  ) {
    const receiverArgs = [
      senderChainId,
      senderSatellite.contractAddress,
      "0x0000000000000000000000000000000000000000",
      "0x00000000",
      alias(senderSatellite.contractAddress, connectionData.L2Alias),
    ];

    await $`bun hardhat --network ${receiverSettings.network} run scripts/connectionRegisterEvm.ts`
      .env({
        ...process.env,
        CONTRACT_ADDRESS: receiverSatellite.contractAddress,
        ARGS: receiverArgs.join(","),
      })
      .cwd("./solidity");
  }

  if (!senderSatellite.connections) {
    senderSatellite.connections = {};
  }
  senderSatellite.connections[receiverChainId] = {};

  writeDeployedSatellites(deployedSatellites);
}

main();
