import buildSatelliteDeployment, { ModuleName } from "../SatelliteDeployment";

export const modules: ModuleName[] = [
  "OwnershipModule",
  "SatelliteRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  "EvmOnChainGrowingModule",
  "NativeParentHashFetcherModule",
  "OptimismReceiverModule",
];
export default buildSatelliteDeployment("11155420", modules);
