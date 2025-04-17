import { $ } from "bun";
import { getDeployedSatellites } from "./satelliteDeploymentsManager";

async function runTestScript() {
  const deployedSatellites = await getDeployedSatellites();

  // TODO: read chain id from somewhere
  // TODO: support other chains and forking

  const satellite = deployedSatellites.satellites.find(
    (s) => s.chainId === "31337",
  );
  if (!satellite) {
    console.error("Satellite not deployed for chain 31337");
    process.exit(1);
  }

  const satelliteAddress = satellite.contractAddress;

  $.nothrow();

  await $`ETHERSCAN_API_KEY="" SATELLITE_ADDRESS=${satelliteAddress} forge script scripts/TestScript.s.sol:TestScript --rpc-url http://localhost:8545 -vvv --chain 31337 ${Bun.argv.slice(2).join(" ")}`;
}

runTestScript();
