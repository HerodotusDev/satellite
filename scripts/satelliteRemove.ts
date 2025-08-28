import {
  getDeployedSatellites,
  parseChainId,
  writeDeployedSatellites,
} from "./satelliteDeploymentsManager";

async function main() {
  if (Bun.argv.length != 3) {
    console.error("Usage: bun satellite:remove <chainId>");
    process.exit(1);
  }

  const chainId = parseChainId(Bun.argv[2]!)?.toString();
  if (chainId === undefined) {
    console.error("Invalid chainId");
    process.exit(1);
  }
  const deployedSatellites = await getDeployedSatellites();

  const satellite = deployedSatellites.satellites[chainId];
  if (!satellite) {
    console.error(`No satellite deployment found for ${chainId}`);
    process.exit(1);
  }

  const connectionsOut = Object.keys(satellite.connections ?? {});
  const connectionsIn = Object.entries(deployedSatellites.satellites)
    .filter(([_, s]) => s.connections?.[chainId])
    .map(([id]) => id);
  if (connectionsIn.length > 0 || connectionsOut.length > 0) {
    console.error(
      `Satellite ${chainId} is connected to ${connectionsOut} other satellites`,
    );
    console.error(
      `Remove following satellite connections with "bun connection:remove <senderChainId> <receiverChainId>":`,
    );
    for (const connectionOut of connectionsOut) {
      console.error(`- ${chainId} -> ${connectionOut}`);
    }
    for (const connectionIn of connectionsIn) {
      console.error(`- ${connectionIn} -> ${chainId}`);
    }
    process.exit(1);
  }

  delete deployedSatellites.satellites[chainId];

  writeDeployedSatellites(deployedSatellites);
}

main();
