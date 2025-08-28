import {
  changeEnvironment,
  doesEnvironmentExist,
  writeDeployedSatellites,
} from "./satelliteDeploymentsManager";

async function main() {
  const environment = process.argv[2];
  if (!environment) {
    console.error("Usage: bun env:create <environment>");
    process.exit(1);
  }

  if (await doesEnvironmentExist(environment)) {
    console.error(`Environment "${environment}" already exists`);
    process.exit(1);
  }

  changeEnvironment(environment);

  writeDeployedSatellites({ satellites: {} });
}

main();
