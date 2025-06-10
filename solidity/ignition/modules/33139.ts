import buildSatelliteDeployment, { ModuleName } from "../SatelliteDeployment";

export const modules: ModuleName[] = [
  "OwnershipModule",
  "SatelliteConnectionRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  "EvmOnChainGrowingModule",
  // "EvmSharpMmrGrowingModule",
  "L1ParentHashFetcherModule",
  "SimpleReceiverModule",
];
export default buildSatelliteDeployment("33139", modules);
