import { $ } from "bun";
import hre from "hardhat";

async function main() {
  if (Bun.argv.length != 3) {
    console.error("Usage: bun satellite:deploy <chainId>");
    process.exit(1);
  }

  const chainId = Bun.argv[2];
  const chainConfigs = Object.entries(hre.config.networks).filter(
    ([_, chainData]) => chainData.chainId == parseInt(chainId),
  );
  if (chainConfigs.length == 0) {
    console.error(`Chain ${chainId} not found in hardhat config`);
    process.exit(1);
  }
  if (chainConfigs.length > 1) {
    console.error(`Multiple chains found for ${chainId} in hardhat config`);
    process.exit(1);
  }

  const [chainName, chainConfig] = chainConfigs[0];

  if (chainConfig.zksync) {
    await $`bun run compile:zksync && bun hardhat deploy-zksync --script deploy.ts --network ${chainName}`;
  } else {
    await $`bun run compile && bun hardhat ignition deploy ./ignition/modules/${chainId}.ts --network ${chainName} --verify`;
  }
}

main();
