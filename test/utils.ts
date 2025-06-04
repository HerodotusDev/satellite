import { ethers, ignition } from "hardhat";
import SatelliteModule from "../ignition/modules/31337";

export const accountFields = {
  NONCE: 0,
  BALANCE: 1,
  STORAGE_ROOT: 2,
  CODE_HASH: 3,
  APE_FLAGS: 4,
  APE_FIXED: 5,
  APE_SHARES: 6,
  APE_DEBT: 7,
  APE_DELEGATE: 8,
};

export const accountFieldsBitmask = {
  NONCE: 1,
  BALANCE: 2,
  STORAGE_ROOT: 4,
  CODE_HASH: 8,
  APE_FLAGS: 16,
};

export const headerFields = {
  PARENT_HASH: 0,
  OMMERS_HASH: 1,
  BENEFICIARY: 2,
  STATE_ROOT: 3,
  RECEIPTS_ROOT: 4,
  TRANSACTION_ROOT: 5,
  LOGS_BLOOM: 6,
  DIFFICULTY: 7,
  NUMBER: 8,
  GAS_LIMIT: 9,
  GAS_USED: 10,
  TIMESTAMP: 11,
  EXTRA_DATA: 12,
  MIX_HASH: 13,
  NONCE: 14,
};

export const headerFieldsBitmask = {
  PARENT_HASH: 1,
  OMMERS_HASH: 2,
  BENEFICIARY: 4,
  STATE_ROOT: 8,
  RECEIPTS_ROOT: 16,
  TRANSACTION_ROOT: 32,
  LOGS_BLOOM: 64,
  DIFFICULTY: 128,
  NUMBER: 256,
  GAS_LIMIT: 512,
  GAS_USED: 1024,
  TIMESTAMP: 2048,
  EXTRA_DATA: 4096,
  MIX_HASH: 8192,
  NONCE: 16384,
};

export function toU256(x: bigint | number, ...y: bigint[]) {
  return (
    "0x" +
    x.toString(16).padStart(64, "0") +
    y.map((y) => y.toString(16).padStart(64, "0")).join("")
  );
}

export function getMappingSlot(baseSlot: bigint, keys: bigint[]) {
  let slot = baseSlot;
  for (const key of keys) {
    slot = BigInt(ethers.keccak256(toU256(key, slot)));
  }
  return slot;
}

export async function setMmrData(
  satelliteAddress: string,
  chainId: bigint,
  mmrId: bigint,
  hashingFunction: bigint,
  isOffchainGrown: boolean,
  latestMmrSize: bigint,
  roots: bigint | { root: bigint; size: bigint }[],
) {
  const baseSlot = BigInt(
    "0x3566ec3f371302e261b8606f979325c5d4baa8f06afec0221cefed0d7fd9cc76",
  );
  const mmrMappingSlot = baseSlot + BigInt(4);
  const mmrInfoSlot = getMappingSlot(mmrMappingSlot, [
    chainId,
    mmrId,
    hashingFunction,
  ]);

  await ethers.provider.send("hardhat_setStorageAt", [
    satelliteAddress,
    toU256(mmrInfoSlot),
    toU256(isOffchainGrown ? 1 : 0),
  ]);

  await ethers.provider.send("hardhat_setStorageAt", [
    satelliteAddress,
    toU256(mmrInfoSlot + BigInt(1)),
    toU256(latestMmrSize),
  ]);

  const mmrRootsSlot = mmrInfoSlot + BigInt(2);
  const rootsAndSizes =
    typeof roots == "bigint" ? [{ size: latestMmrSize, root: roots }] : roots;

  for (const r of rootsAndSizes) {
    await ethers.provider.send("hardhat_setStorageAt", [
      satelliteAddress,
      toU256(getMappingSlot(mmrRootsSlot, [r.size])),
      toU256(r.root),
    ]);
  }
}

export async function deploy() {
  const { satellite } = await ignition.deploy(SatelliteModule);
  const satelliteAddress = await satellite.getAddress();

  return { satellite, satelliteAddress };
}

export const KECCAK_HASHER = BigInt(
  "0xdf35a135a69c769066bbb4d17b2fa3ec922c028d4e4bf9d0402e6f7c12b31813",
);

export const POSEIDON_HASHER = BigInt(
  "0xd3764378578a6e2b5a09713c3e8d5015a802d8de808c962ff5c53384ac7b1450",
);

export const APECHAIN_SHARE_PRICE_ADDRESS =
  "0xA4b05FffffFffFFFFfFFfffFfffFFfffFfFfFFFf";

export const APECHAIN_SHARE_PRICE_SLOT =
  "0x15fed0451499512d95f3ec5a41c878b9de55f21878b5b4e190d4667ec709b432";
