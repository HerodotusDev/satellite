![](/banner.png)

# Herodotus EVM V2 Smart Contracts

## Quick start for end-users

This contract provides cross-chain and historical data on EVM blockchains, e.g. reading balance of Ethereum account `0x123` at block `456` from Optimism contract. To get exact data you need into this contract, you should use [Storage Proof API](TODO: link). If data is present in this contract, you can be sure that it is correct without needing to trust its owner or anyone (for more details see [design section](#design)).

Those are function that you probably need:

#### [`accountField(uint256 chainId, address account, uint256 blockNumber, AccountField field) returns (bytes32)`](./src/interfaces/modules/IEvmFactRegistryModule.sol#L44-L45)

Returns value of `field` (which is either `NONCE`, `BALANCE`, `STORAGE_ROOT` or `CODE_HASH`) for `account` at `blockNumber` on chain with id `chainId`.

#### [`storageSlot(uint256 chainId, address account, uint256 blockNumber, bytes32 slot) returns (bytes32)`](./src/interfaces/modules/IEvmFactRegistryModule.sol#L47-L48)

Returns value of storage slot number `slot` of `account` at `blockNumber` on chain with id `chainId`.

#### [`timestamp(uint256 chainId, uint256 timestamp) returns (uint256)`](./src/interfaces/modules/IEvmFactRegistryModule.sol#L49-50)

Returns block number of the closest block with timestamp less than or equal to the given `timestamp` on chain with id `chainId`.

## [Deployed Contracts](./deployments)

## Design

### How to access historical data in provable way?

Let's say that your contract needs to know what was the balance of account `0x123` on Ethereum at block 456 and you don't want to trust any third-party that provides this type of data. How can we do that?

The main problem is that Ethereum contracts can only access current chain data. Note: You might have heard of archive nodes, which store all historical data, but keep in mind that this is just access though RPC, not on-chain, meaning that no contract can access this data.

#### Solution

To solve this problem, we came up with the following idea: We will store block hashes for all historical blocks in data structure that allows to easily append new blocks and prove that certain block is present in the structure. One example of such structure is Merkle Mountain Range (MMR), which is similar to Merkle Tree, but has dynamic size, which means that you can add new elements to it in (amortized) constant time. Really big advantage of MMR is that it can be represented with just 2 values and only when append or verification of inclusion is performed, more data has to be provided for evaluating new values. So, we will write a smart contract that stores MMR and exposes functions to append new blocks and verify inclusion of any block given its hash.

> But how do we make sure that only valid Ethereum blocks can be appended to MMR?

Fortunately, EVM has an OPCODE for getting block hash of any of the latest 256 blocks, so we only allow to append those blocks.

> But isn't that problematic if we want to construct MMR with all Ethereum blocks?

For that let's introduce append chaining (or batching). As you probably know, Ethereum block header contains hash of the parent block (that's where word "blockchain" comes from). We can use that fact to append multiple consecutive blocks at once while requiring that at least just one of those blocks is in the latest 256.

For example, if current block has number 1258, we can append blocks 1000-1200, because block 1200 is within last 256 blocks and hashes off all other blocks (1000-1199) can be proven though parent hashes. After those blocks are appended, we can add more blocks provided that the last block in the batch is 999, because it is a parent of block 1000, which is already in an MMR.

### Reducing cost

We will be calling the process described above an on-chain growing, because it does all calculations within the smart contract. As you might imagine, this is really, really expensive and infeasible for bigger number of blocks, let alone for the whole blockchain. To prove all Ethereum blocks, we need much more efficient solution.

So here is where Zero Knowledge Proofs come to rescue. We won't really use the zero knowledge property, but the fact that verifying ZK proof is much cheaper than running the program itself. In our case we will use STARKs with Cairo0 programming language, SHARP prover and L1 verifier. Program, that takes current MMR state along with block headers to append and returns new MMR data, will be ran, proven and verified on Ethereum. Then our contract will just check if the initial MMR data present in the proof matches one stored in the contract as well as whether the first block in the chain is a parent of existing one or one of the latest 256 blocks. If those conditions are met, MMR data will be updated with new values given in the ZK proof. Thanks to the STARK proof, we can be sure that new MMR values are the same as if growing happened on-chain.

We will be calling this process of appending using ZK proofs an off-chain growing or SHARP growing (becase proofs are generated and verified with Starkware's Sharp Prover).

### Enhancements

TODO: multiple MMRs, MMR IDs, different hash functions.

## Modules

Because of great complexity of the contract and need for fine-tuned upgradability, we decided to use [Diamond Proxy Patter](TODO: link) with following facets (or as we will call them - modules):

- [EVM Fact Registry](./src/modules/EvmFactRegistryModule.sol) - stores accounts and storage data that was proven
- [MMR Core](./src/modules/MmrCoreModule.sol) - responsible for storing and moving MMR data
- Growing modules - append new blocks to existing MMR
  - [Evm On-Chain Growing](./src/modules/growing/EvmOnChainGrowingModule.sol) - processes all block data directly in the contract as described in [solution section](#solution)
  - [Evm Sharp Growing](./src/modules/growing/EvmSharpMmrGrowingModule.sol) - processes block data that was proven with ZK proof using SHARP as described in [reducing cost](#reducing-cost)
  - [Starknet Growing](./src/modules/growing/StarknetSharpMmrGrowingModule.sol) - TODO
- [Satellite Registry](./src/modules/SatelliteConnectionRegistryModule.sol) - stores information about other satellites to/from which it can send/receive messages
- Messaging modules - responsible for sending and receiving data to and from satellites deployed on other chains
  - Receiver modules
    - [Simple Receiver](./src/modules/messaging/receiver/SimpleReceiverModule.sol) - receives message on chains that set `msg.sender` for cross-chain messages to transaction sender on the source chain
    - [Optimism Receiver](./src/modules/messaging/receiver/OptimismReceiverModule.sol) - receive messages on optimism (which [handles messaging differently](./src/modules/messaging/receiver/OptimismReceiverModule.sol#L12-L17))
  - Sender modules
    - [Universal Sender](./src/modules/messaging/sender/UniversalSenderModule.sol) - prepares and sends messages that move MMRs and Parent Hashes regardless of the destination chain (uses specific senders under the hood)
    - [L1 to Starknet](./src/modules/messaging/sender/L1ToStarknetSenderModule.sol)
    - [L1 to Optimism](./src/modules/messaging/sender/L1ToOptimismSenderModule.sol) - sends message to Optimism (or similar chains like WorldChain)
    - [L1 to ZkSync](./src/modules/messaging/sender/L1ToZkSyncSenderModule.sol)
    - [L1 to Arbitrum](./src/modules/messaging/sender/L1ToArbitrumSenderModule.sol)
    - [Arbitrum to ApeChain](./src/modules/messaging/sender/ArbitrumToApeChainSenderModule.sol)
- Parent Hash Fetching modules
  - [Native Parent Hash Fetcher]() - fetches one of latest 256 parent hashes from the chain the satellite is deployed at
  - [Starknet Parent Hash Fetcher]()
- [DataProcessor]()
- [Ownership]()
- [Satellite Inspector]()
- [Satellite Maintenance]()

## Deployment

1. Create `.env` file using `.env.example` template. You will need `PRIVATE_KEY` of EVM deployment account and `ALCHEMY_API_KEY` which you can get from [Alchemy dashboard](https://dashboard.alchemy.com). Make sure that you enabled chains you need. Additionally, you will need API key for block explorers of chains you want to deploy to (`*CHAIN_NAME*_ETHERSCAN_API_KEY`).

2. Compile your contract with

```
bun compile
```

3. Select your environment

> Environments allow you to have multiple sets of satellite deployments, e.g. production, staging and local development. Data about deployed satellites is saved to `deployments/<ENVIRONMENT_NAME>.json`.

```
bun env:change <ENVIRONMENT_NAME>
```

4. Deploy with

```
bun satellite:deploy CHAIN_ID
```

5. To connect two satellites that support messaging, run

```
bun connection:register SENDER_CHAIN_ID RECEIVER_CHAIN_ID
```

### Managing environments

To list all environments, run

```
bun env
```

To create a new environment with no satellites, run

```
bun env:create <ENVIRONMENT_NAME>
```

To delete environment, run

```
bun env:delete <ENVIRONMENT_NAME>
```

### Upgrades

To upgrade existing satellite, run steps 1 and 2 from section above and then run

```
bun satellite:upgrade CHAIN_ID
```

### Removing satellites and connections

To remove connection between two satellites, run

```
bun connection:remove SENDER_CHAIN_ID RECEIVER_CHAIN_ID
```

When all connections to/from satellite are removed, you can remove satellite with

```
bun satellite:remove CHAIN_ID
```

## Development

> If you get any unexpected errors, run `bun clear`.

### Local anvil

To set up anvil and deploy satellite to it, run:

```bash
bun env:create local # or `bun env:change local` if you already have an environment
bun anvil
bun satellite:deploy 31337
bun run_script:local --broadcast
```

If you want to remove the satellite, to deploy it again, run:

```bash
bun satellite:remove 31337
rm -rf ignition/deployments/chain-31337
```

### Forked anvil

To fork anvil from any chain, run:

```bash
bun anvil:fork *CHAIN_ID*
bun run_script:local
```

Then to run script for deployed satellite, run:

```bash
bun env:change stage # or whatever environment you want to use
bun run_script:local --broadcast
```

## Documentation

Here are some useful links for further reading:

- [Herodotus Cloud Documentation](https://docs.herodotus.cloud)
- [Herodotus Documentation](https://docs.herodotus.dev)

## License

Copyright 2024 - Herodotus Dev Ltd

```

```
