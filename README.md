![](/banner.png)

### Herodotus EVM V2 Smart Contracts

Herodotus contracts for EVM chains.

# Prerequisites:

- Git
- Node.js (^18.0)
- npm
- pnpm
- Foundry
- Solc

## Running Locally

Create a `.env` file based on `.env.example`, and then run:

```bash
git clone git@github.com:HerodotusDev/herodotus-evm-v2.git
cd herodotus-evm-v2

# If you do not have pnpm, run `npm install -g pnpm`
# Install dependencies
pnpm install

# Install libraries
forge install

# Running tests requires .env to be configured
forge test
```

## Contracts Overview

- `Satellite`: a Diamond contract
- `ISatellite`: an interface joining all interfaces of the Satellite Diamond into one - to be used to interact with the Satellite Diamond
  - `LibSatellite`: a Diamond library, holds the persistent diamond state and manages Diamond functionalities
  - `SatelliteInspectorModule`: a Diamond Loupe contract
  - `SatelliteMaintenanceModule`: a Diamond Cut contract
  - `OwnershipModule`: ERC173 ownership contract for the whole Diamond
- `MmrCoreModule`: contains core logic for MMRs
- `NativeSharpMmrGrowingModule`: contains logic for aggregating facts - off-chain proving
- `NativeOnChainGrowingModule`: contains logic for on-chain growing mmrs with native blocks & hashing function
- `NativeFactsRegistryModule`: used for storage proofs on-chain based on headers from MMRs from MmrCoreModule

- `/x-rollup-messaging`: contains contracts for messaging between rollups

  - `/parent-hash-fetcher`: contains contracts for fetching parent hashes from other rollups
    - `NativeParentHashFetcher`: fetches parent hashes from the Native chain (chain on which this rollup is deployed)

## TODOs:

- Messaging contracts
- More Parent Hash getters
- More Tests

## Deployed Contracts

### Sepolia

```
SatelliteMaintenanceModule: 0x22b387307183C6E4f9E1708D61427e7678106104
Satellite: 0x710CdB36686CAFc73e6CEAF1bF8700226736A79c
OwnershipModule: 0x03d3bB47B0bB38383B9C6dfd5eC402Ca81963A8f
SatelliteInspectorModule: 0x4bd71E988Da55f451008CC81a90d30AA49dF34fc
MmrCoreModule: 0xfc8ff335a3755cb3118AD378335720a84eD2146f
MockFactsRegistry: 0xc81B78Ee1636bf5bB09CC150DA15Ca48D0ADC38c
SharpFactsAggregatorModule: 0x00eD1852C25A87f524605c5AA2eDa120fe09A312
NativeFactsRegistryModule: 0xB7D90624345a34566829044221396224B08D7655
NativeParentHashFetcherModule: 0xCBa5C999B19ebDEc3ABc2f74067f237c6d31Ab20
```

## Deployment

### First make sure you run:

```
bun forge:build
```

This generates the `out/contracts-with-selectors.json` file which is used for deployment

**_Make sure you run `bun forge:build` after every Satellite interface change_**

### Run tests

- `bun forge:test` - run all tests

### Deploy everything for the first time

- `bun forge:deploy` - dry run of the deployment
- `bun forge:deploy:anvil` - deployment to local Anvil network
- `bun forge:deploy:sepolia` - deployment to Sepolia testnet

### Redeploy/deploy and add/replace a module to existing Satellite

Needs `DEPLOYED_SATELLITE_ADDRESS` set in `.env`

- `bun forge:deploy:update script/deploy/modules/Deploy<Name>Module.s.sol`
- `bun forge:deploy:update:anvil script/deploy/modules/Deploy<Name>Module.s.sol`
- `bun forge:deploy:update:sepolia script/deploy/modules/Deploy<Name>Module.s.sol`

## Documentation

Here are some useful links for further reading:

- [Herodotus Documentation](https://docs.herodotus.dev)
- [Herodotus Builder Guide](https://herodotus.notion.site/herodotus/Herodotus-Hands-On-Builder-Guide-5298b607069f4bcfba9513aa75ee74d4)

## License

Copyright 2024 - Herodotus Dev Ltd
