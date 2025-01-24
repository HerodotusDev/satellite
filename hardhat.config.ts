import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import "@nomicfoundation/hardhat-ignition-ethers";
import "@matterlabs/hardhat-zksync";
import "@matterlabs/hardhat-zksync-verify";

import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        details: {
          yulDetails: {
            optimizerSteps: "u",
          },
        },
      },
    },
  },
  paths: {
    sources: "./src",
  },
  networks: {
    localhost: {
      url: "http://localhost:8545",
      accounts: [process.env.PRIVATE_KEY as string],
    },
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: [process.env.PRIVATE_KEY as string],
    },
    zkSyncSepolia: {
      url: "https://sepolia.era.zksync.dev",
      ethNetwork: "sepolia",
      accounts: [process.env.PRIVATE_KEY as string],
      zksync: true,
      verifyURL:
        "https://explorer.sepolia.era.zksync.dev/contract_verification",
    },
    optimismSepolia: {
      url: `https://opt-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: [process.env.PRIVATE_KEY as string],
    },
    arbitrumSepolia: {
      url: `https://arb-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: [process.env.PRIVATE_KEY as string],
    },
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.L1_ETHERSCAN_API_KEY as string,
      zksyncsepolia: process.env.ZKSYNC_ETHERSCAN_API_KEY as string,
      optimismSepolia: process.env.OPTIMISM_ETHERSCAN_API_KEY as string,
      arbitrumSepolia: process.env.ARBITRUM_ETHERSCAN_API_KEY as string,
    },
    customChains: [
      {
        network: "optimismSepolia",
        chainId: 11155420,
        urls: {
          apiURL: "https://api-sepolia-optimistic.etherscan.io/api",
          browserURL: "https://sepolia-optimism.etherscan.io/",
        },
      },
      {
        network: "arbitrumSepolia",
        chainId: 421614,
        urls: {
          apiURL: "https://api-sepolia.arbiscan.io/api",
          browserURL: "https://sepolia.arbiscan.io/",
        },
      },
    ],
  },
};

export default config;
