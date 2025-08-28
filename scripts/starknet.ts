import { $ } from "bun";
import { STARKNET_CHAIN_IDS } from "./satelliteDeploymentsManager";
import fs from "fs";

export async function starknetDeclare(networkName: string) {
  const result =
    await $`sncast declare --contract-name Satellite --network ${networkName}`
      .env({
        ...process.env,
        FORCE_COLOR: "1",
      })
      .cwd("./cairo")
      .nothrow();
  const out = result.text();
  const err = result.stderr.toString();

  const matchErr = err.match(/Class with hash (0x[0-9a-fA-F]+) is already declared./);
  const matchOut = out.match(/Class Hash:\W*(0x[0-9a-fA-F]+)/)
  if (matchErr) {
    return matchErr[1]!;
  } else if (matchOut) {
    // TODO: this case is not tested
    return matchOut[1]!;
  } else {
    console.error("Failed to declare satellite");
    process.exit(1);
  }
}

export async function starknetDeploy(chainId: keyof typeof STARKNET_CHAIN_IDS, classHash: string, owner: string) {
  const calldata = `${chainId} 0 ${owner}`;

  const result = await $`sncast deploy --class-hash ${classHash} --network ${STARKNET_CHAIN_IDS[chainId]} --constructor-calldata ${calldata}`.env({
    ...process.env,
    FORCE_COLOR: "1",
  }).cwd("./cairo").nothrow();

  const out = result.text();
  const match = out.match(/Contract Address:\W*(0x[0-9a-fA-F]+)/);
  if (match) {
    return match[1]!;
  } else {
    console.error("Failed to deploy satellite");
    process.exit(1);
  }
}

export async function starknetGetAccount(networkName: typeof STARKNET_CHAIN_IDS[keyof typeof STARKNET_CHAIN_IDS]) {
  let account: string;
  try {
    const accounts = fs.readFileSync(import.meta.dirname + "/../cairo/.env", "utf8").split("\n").filter(line => line.trim().startsWith("ACCOUNT="))
    if (accounts.length === 0) {
      console.error("No accounts found in .env file");
      process.exit(1);
    }
    if (accounts.length > 1) {
      console.error("Multiple accounts found in .env file");
      process.exit(1);
    }
    const accountName = accounts[0]!.split("=")[1];
    if (accountName === undefined) {
      console.error("Invalid account found in .env file");
      process.exit(1);
    }
    account = accountName
  } catch (e) {
    console.error("No .env file found in cairo directory");
    process.exit(1);
  }

  const accountList = (await $`sncast account list`.quiet()).text();
  const path = accountList.split("\n")[0]?.match(/Available accounts \(at (.+)\):/)?.[1];
  if (path === undefined) {
    console.error("No file path found in account list");
    process.exit(1);
  }

  let accountFile;
  try {
    accountFile = JSON.parse(fs.readFileSync(path, "utf8"));
  } catch (e) {
    console.error("Failed to parse account file");
    console.error(e);
    process.exit(1);
  }

  const addr = accountFile[`alpha-${networkName}`]?.[account]?.['address'];

  if (addr === undefined) {
    console.error("Account not found");
    process.exit(1);
  }

  return addr;
}

export async function starknetUpgrade(network: typeof STARKNET_CHAIN_IDS[keyof typeof STARKNET_CHAIN_IDS], satelliteAddress: string, classHash: string) {
  // TODO: not tested
  await $`sncast invoke --contract-address ${satelliteAddress} --function upgrade --calldata "${classHash}" --network ${network}`.env({
    ...process.env,
    FORCE_COLOR: "1",
  }).cwd("./cairo").nothrow();
}
