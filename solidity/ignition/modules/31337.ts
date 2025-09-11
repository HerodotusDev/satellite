import buildSatelliteDeployment, { ModuleName } from "../SatelliteDeployment";

export const modules: ModuleName[] = [
  "OwnershipModule",
  "SatelliteRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  "CairoFactRegistryModule",
  "DataProcessorModule",
  "EvmOnChainGrowingModule",
  "EvmSharpMmrGrowingModule",
  // "StarknetSharpMmrGrowingModule",
  "NativeParentHashFetcherModule",
  "OptimismParentHashFetcherModule",
  // "StarknetParentHashFetcherModule",
  "MockFactsRegistry",
];
export default buildSatelliteDeployment("31337", modules);
