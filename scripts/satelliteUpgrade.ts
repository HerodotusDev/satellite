import { $ } from "bun";
import {
  parseChainId,
  STARKNET_CHAIN_IDS,
} from "./satelliteDeploymentsManager";

async function main() {
  if (Bun.argv.length != 3) {
    console.error("Usage: bun satellite:upgrade <chainId>");
    process.exit(1);
  }

  const chainId = parseChainId(Bun.argv[2]!);
  if (chainId === null) {
    console.error("Invalid chainId");
    process.exit(1);
  }
  console.log("Upgrading satellite for chainId", chainId);

  if (STARKNET_CHAIN_IDS.includes(chainId)) {
    console.log("Upgrading satellite for Starknet");
  } else {
    await $`bun run satellite:upgrade ${chainId}`
      .nothrow()
      .env({
        ...process.env,
        FORCE_COLOR: "1",
      })
      .cwd("./solidity");
  }
}

main();
