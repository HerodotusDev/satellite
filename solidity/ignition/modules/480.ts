import buildSatelliteDeployment, { ModuleName } from "../SatelliteDeployment";

export const modules: ModuleName[] = [
  "OwnershipModule",
  "SatelliteRegistryModule",
  "SatelliteInspectorModule",
  "CairoFactRegistryModule",
  "DataProcessorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  "EvmOnChainGrowingModule",
  "NativeParentHashFetcherModule",
  "OptimismReceiverModule",
];
export default buildSatelliteDeployment("480", modules);
