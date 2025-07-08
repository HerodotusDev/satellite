import buildSatelliteDeployment, { ModuleName } from "../SatelliteDeployment";

export const modules: ModuleName[] = [
  "OwnershipModule",
  "SatelliteConnectionRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  "CairoFactRegistryModule",
  "EvmOnChainGrowingModule",
  // "EvmSharpMmrGrowingModule",
  "NativeArbitrumParentHashFetcherModule",
  "SimpleReceiverModule",
];
export default buildSatelliteDeployment("33139", modules);
