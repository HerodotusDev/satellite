import buildSatelliteDeployment, { ModuleName } from "../SatelliteDeployment";

export const modules: ModuleName[] = [
  "OwnershipModule",
  "SatelliteConnectionRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  // "DataProcessorModule",
  // "EvmOnChainGrowingModule",
  // "EvmSharpMmrGrowingModule",
  // "StarknetSharpMmrGrowingModule",
  // "NativeParentHashFetcherModule",
  // "StarknetParentHashFetcherModule",
];
export default buildSatelliteDeployment("31337", modules);
