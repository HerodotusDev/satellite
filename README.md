![](/banner.png)

### Herodotus EVM V2 Smart Contracts

Herodotus contracts for EVM chains.

## Contracts Overview

- `Satellite`: a Diamond contract
- `ISatellite`: an interface joining all interfaces of the Satellite Diamond into one - to be used to interact with the Satellite Diamond
  - `LibSatellite`: a Diamond library, holds the persistent diamond state and manages Diamond functionalities
  - `SatelliteInspectorModule`: a Diamond Loupe contract
  - `SatelliteMaintenanceModule`: a Diamond Cut contract
  - `OwnershipModule`: ERC173 ownership contract for the whole Diamond
- `MmrCoreModule`: contains core logic for MMRs
- `EVMFactRegistryModule`: used for storage proofs on-chain based on headers from MMRs from MmrCoreModule
- `/growing`: contracts responsible for growing MMRs
- `/messaging`: contracts responsible for interacting other Satellites & contracts
- `/parent-hash-fetching`: contracts responsible for fetching parent hashes

## [Deployed Contracts](/deployed_satellites.json)

## Documentation

Here are some useful links for further reading:

- [Herodotus Cloud Documentation](https://docs.herodotus.cloud)
- [Herodotus Documentation](https://docs.herodotus.dev)

## License

Copyright 2024 - Herodotus Dev Ltd
