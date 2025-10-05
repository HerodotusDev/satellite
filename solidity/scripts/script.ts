import { $ } from "bun";
import { getDeployedSatellites } from "../../scripts/satelliteDeploymentsManager";

async function runTestScript() {
  if (Bun.argv.length < 4) {
    console.error("Usage: bun script <chainId> <scriptPath:contractName>");
    process.exit(1);
  }
  const chainId = parseInt(Bun.argv[2]);
  const scriptPath = Bun.argv[3];
  let rpcUrl: string;
  try {
    rpcUrl = (
      await $`CHAIN_ID=${chainId} bun hardhat run scripts/getRpcUrl.ts`.text()
    ).trim();
  } catch (e) {
    console.log(e);
    console.log((e as any)?.stderr?.toString?.());
    process.exit(1);
  }

  const deployedSatellites = await getDeployedSatellites();

  // Call anvil eth_chainId
  const forkedChainIdResponse = await fetch(rpcUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      method: "eth_chainId",
      params: [],
      id: 1,
    }),
  });
  if (forkedChainIdResponse.status != 200) {
    console.error(
      "Failed to get chain id from RPC:",
      forkedChainIdResponse.status,
    );
    process.exit(1);
  }
  const forkedChainId = parseInt((await forkedChainIdResponse.json()).result);

  const satellite = deployedSatellites.satellites[forkedChainId];
  if (!satellite) {
    console.error(`Satellite not deployed for chain ${forkedChainId}`);
    process.exit(1);
  }

  const satelliteAddress = satellite.contractAddress;

  $.nothrow();

  await $`forge script ${scriptPath} --rpc-url ${rpcUrl} -vvv --chain ${chainId} ${Bun.argv.slice(4).join(" ")}`.env(
    {
      ...process.env,
      FORCE_COLOR: "1",
      ETHERSCAN_API_KEY: "",
      ETHERSCAN_API_URL: "",
      SATELLITE_ADDRESS: satelliteAddress,
      FORK_CHAIN_ID: forkedChainId.toString(),
    },
  );
}

runTestScript();
