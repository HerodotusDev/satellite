import buildSatelliteDeployment, { ModuleName } from "../SatelliteDeployment";

export const modules: ModuleName[] = [
  "OwnershipModule",
  "SatelliteRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  "CairoFactRegistryModule",
  "EvmOnChainGrowingModule",
  "EvmSharpMmrGrowingModule",
  "NativeArbitrumParentHashFetcherModule",
  "SimpleReceiverModule",
];
export default buildSatelliteDeployment("33111", modules);
