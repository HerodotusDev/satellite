import config from "../hardhat.config";

function main() {
  if (process.env.CHAIN_ID === undefined) {
    console.error(
      "Usage: CHAIN_ID=<chainId> bun hardhat run scripts/getRpcUrl.ts",
    );
    process.exit(1);
  }

  const chainId = parseInt(process.env.CHAIN_ID);

  if (chainId == 31337) {
    console.log("http://localhost:8545");
    process.exit(0);
  }

  const network = Object.values(config.networks ?? {}).find(
    (n) => n?.chainId === chainId,
  );

  if (!network) {
    throw new Error(`Network with chainId ${chainId} not found`);
  }

  console.log((network as any)?.url);
}

main();
