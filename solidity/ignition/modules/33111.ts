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
  "L1ParentHashFetcherModule",
  "NativeArbitrumParentHashFetcherModule",
  "SimpleReceiverModule",
];
export default buildSatelliteDeployment("33111", modules);
