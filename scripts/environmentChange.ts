import {
  changeEnvironment,
  getActiveEnvironmentSafe,
  isEnvironmentValid,
} from "./satelliteDeploymentsManager";

async function main() {
  const environment = process.argv[2];
  if (!environment) {
    console.error("Usage: bun env:change <environment>");
    process.exit(1);
  }

  const activeEnvironment = await getActiveEnvironmentSafe();
  if (activeEnvironment === environment) {
    console.error("This environment is already active");
    process.exit(1);
  }

  const environmentValidity = await isEnvironmentValid(environment);
  if (environmentValidity === null) {
    console.error(`Environment "${environment}" does not exist`);
    process.exit(1);
  }
  if (environmentValidity === false) {
    console.error(`Environment ${environment} has invalid file structure`);
    process.exit(1);
  }

  changeEnvironment(environment);
}

main();
