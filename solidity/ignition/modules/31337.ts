import buildSatelliteDeployment, { ModuleName } from "../SatelliteDeployment";

export const modules: ModuleName[] = [
  "OwnershipModule",
  "SatelliteConnectionRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  "CairoFactRegistryModule",
  "DataProcessorModule",
  "EvmOnChainGrowingModule",
  "EvmSharpMmrGrowingModule",
  // "StarknetSharpMmrGrowingModule",
  "NativeParentHashFetcherModule",
  // "StarknetParentHashFetcherModule",
  "MockFactsRegistry",
];
export default buildSatelliteDeployment("31337", modules);
