import fs from "fs";
import { getActiveEnvironmentSafe } from "./satelliteDeploymentsManager";

export async function main() {
  const activeEnvironment = await getActiveEnvironmentSafe();

  if (activeEnvironment !== null) {
    console.log(`\nCurrently active environment: ${activeEnvironment}\n`);
  } else {
    console.log(`\nNo active environment found\n`);
  }

  console.log(`Available environments:`);
  const files = fs.readdirSync("../deployments");
  for (const file of files) {
    if (file.endsWith(".json")) {
      const env = file.substring(0, file.length - 5);
      console.log(`${env == activeEnvironment ? ">>" : " -"} ${env}`);
    }
  }
  console.log(
    `\nRun "bun env:change <environment>" to change the active environment`,
  );
  console.log(`Run "bun env:create <environment>" to create a new environment`);
  console.log(`Run "bun env:delete <environment>" to delete an environment`);
}

main();
