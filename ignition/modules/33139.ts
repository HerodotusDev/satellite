import buildSatelliteDeployment, { ModuleName } from "../SatelliteDeployment";

export const modules: ModuleName[] = [
  "OwnershipModule",
  "SatelliteConnectionRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  "EvmOnChainGrowingModule",
  // "EvmSharpMmrGrowingModule",
  "NativeParentHashFetcherModule",
  "SimpleReceiverModule",
];
export default buildSatelliteDeployment("33139", modules);
