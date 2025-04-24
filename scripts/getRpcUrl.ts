import config from "../hardhat.config";

function main() {
  const chainId = process.env.CHAIN_ID;

  const network = Object.values(config.networks ?? {}).find(
    (n) => n?.chainId === Number(chainId),
  );

  if (!network) {
    throw new Error(`Network with chainId ${chainId} not found`);
  }

  console.log((network as any)?.url);
}

main();
