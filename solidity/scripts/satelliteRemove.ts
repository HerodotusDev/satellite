import { $ } from "bun";
import fs from "fs";
import { ethers } from "ethers";
import settings from "../settings.json";
import {
  getDeployedSatellites,
  writeDeployedSatellites,
} from "./satelliteDeploymentsManager";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

async function main() {
  if (Bun.argv.length != 3) {
    console.error("Usage: bun satellite:remove <chainId>");
    process.exit(1);
  }

  const chainId = Bun.argv[2] as keyof typeof settings;

  if (!(chainId in settings)) {
    console.error(`No settings found for ${chainId}`);
    process.exit(1);
  }

  const deployedSatellites = await getDeployedSatellites();

  const satellite = deployedSatellites.satellites.find(
    (s) => s.chainId === chainId,
  );
  if (!satellite) {
    console.error(`No satellite deployment found for ${chainId}`);
    process.exit(1);
  }

  const connections = (deployedSatellites.connections as any[]).filter(
    (c) =>
      parseInt(c.from) === parseInt(chainId) ||
      parseInt(c.to) === parseInt(chainId),
  );
  if (connections.length > 0) {
    console.error(
      `Satellite ${chainId} is connected to ${connections.length} other satellites`,
    );
    console.error(
      `Remove following satellite connections with "bun connection:remove <senderChainId> <receiverChainId>":`,
    );
    for (const connection of connections) {
      console.error(`- ${connection.from} -> ${connection.to}`);
    }
    process.exit(1);
  }

  (deployedSatellites.satellites as any[]) = (
    deployedSatellites.satellites as any[]
  ).filter((s) => parseInt(s.chainId) !== parseInt(chainId));

  writeDeployedSatellites(deployedSatellites);
}

main();
