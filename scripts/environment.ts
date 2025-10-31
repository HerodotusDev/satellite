import {
  getActiveEnvironmentSafe,
  getAllEnvironments,
} from "./satelliteDeploymentsManager";

export async function main() {
  const activeEnvironment = await getActiveEnvironmentSafe();

  if (activeEnvironment !== null) {
    console.log(`\nCurrently active environment: ${activeEnvironment}\n`);
  } else {
    console.log(`\nNo active environment found\n`);
  }

  console.log(`Available environments:`);
  const envs = await getAllEnvironments();
  for (const env of envs) {
    console.log(`${env == activeEnvironment ? ">>" : " -"} ${env}`);
  }
  console.log(
    `\nRun "bun env:change <environment>" to change the active environment`,
  );
  console.log(`Run "bun env:create <environment>" to create a new environment`);
  console.log(`Run "bun env:delete <environment>" to delete an environment`);
}

main();
