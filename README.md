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
  - `LibSatellite`: a Diamond library, holds the persistent diamond state and manages Diamond functionalities
  - `SatelliteInspectorModule`: a Diamond Loupe contract
  - `SatelliteMaintenanceModule`: a Diamond Cut contract
  - `OwnershipModule`: ERC173 ownership contract for the whole Diamond
- `SatelliteCoreModule`: contains core logic for MMRs
- `SharpFactsAggregatorModule`: contains logic for aggregating facts - off-chain proving

## Next Steps

- Messaging contracts
- Parent Hash getters

## Deployed Contracts

- [Deployed Contracts Addresses](https://docs.herodotus.dev/herodotus-docs/deployed-contracts)

## Deployment

`pnpm run deploy`

## Documentation

Here are some useful links for further reading:

- [Herodotus Documentation](https://docs.herodotus.dev)
- [Herodotus Builder Guide](https://herodotus.notion.site/herodotus/Herodotus-Hands-On-Builder-Guide-5298b607069f4bcfba9513aa75ee74d4)

## License

Copyright 2024 - Herodotus Dev Ltd
