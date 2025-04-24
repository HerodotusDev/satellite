import { $ } from "bun";
import { getDeployedSatellites } from "./satelliteDeploymentsManager";

async function runTestScript() {
  const deployedSatellites = await getDeployedSatellites();

  // TODO: read chain id from somewhere
  // TODO: support other chains and forking

  // Call anvil eth_chainId
  let response;
  try {
    response = await $`curl \
      -X POST \
      -H "Content-Type: application/json" \
      --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
      http://127.0.0.1:8545`.text();
  } catch (e) {
    console.error(e);
    console.error("Failed to get chain id from anvil");
    console.error("Do you have anvil running?");
    process.exit(1);
  }

  const forkedChainId = parseInt(JSON.parse(response).result);

  const satellite = deployedSatellites.satellites.find(
    (s) => parseInt(s.chainId) === forkedChainId,
  );
  if (!satellite) {
    console.error(`Satellite not deployed for chain ${forkedChainId}`);
    process.exit(1);
  }

  const satelliteAddress = satellite.contractAddress;

  $.nothrow();

  await $`ETHERSCAN_API_KEY="" SATELLITE_ADDRESS=${satelliteAddress} FORK_CHAIN_ID=${forkedChainId} forge script scripts/TestScript.s.sol:TestScript --rpc-url http://localhost:8545 -vvv --chain 31337 ${Bun.argv.slice(2).join(" ")}`;
}

runTestScript();
