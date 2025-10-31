import { ethers } from "ethers";
import contractAbi from "../abi/all.json";

// 1. Filter the ABI to find only the error definitions
const errorAbis = contractAbi.filter((entry) => entry.type === "error");

// 2. Iterate over the errors and calculate the selector for each
const errorSelectors = {} as Record<string, string>;

for (const error of errorAbis) {
  // 3. Construct the signature string
  // e.g., "NotOwner()" or "InsufficientBalance(uint256,uint256)"
  const paramTypes = error.inputs.map((input) => input.type).join(",");
  const signature = `${error.name}(${paramTypes})`;

  // 4. Hash the signature and get the first 4 bytes
  // ethers.id() is a convenient way to get the keccak256 hash of a string
  const selector = ethers.id(signature).slice(0, 10);

  errorSelectors[error.name] = selector;
}

console.log(errorSelectors);
