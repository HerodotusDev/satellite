import {
  changeEnvironment,
  doesEnvironmentExist,
  getActiveEnvironment,
} from "./satelliteDeploymentsManager";

async function main() {
  const environment = process.argv?.[2]?.trim();
  if (!environment) {
    console.error("Usage: bun env:delete <environment>");
    process.exit(1);
  }

  if (!(await doesEnvironmentExist(environment))) {
    console.error(`Environment "${environment}" does not exist`);
    process.exit(1);
  }

  const file = Bun.file(`../deployments/${environment}.json`);
  // if it errors here, you have an old version of bun
  await file.delete();

  if (environment == (await getActiveEnvironment())) {
    await changeEnvironment(null);
  }
}

main();
