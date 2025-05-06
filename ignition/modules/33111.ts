import buildSatelliteDeployment, { ModuleName } from "../SatelliteDeployment";

export const modules: ModuleName[] = [
  "OwnershipModule",
  "SatelliteConnectionRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  // "DataProcessorModule",
  "EvmOnChainGrowingModule",
  "EvmSharpMmrGrowingModule",
  "NativeParentHashFetcherModule",
  "SimpleReceiverModule",
];
export default buildSatelliteDeployment("33111", modules);
