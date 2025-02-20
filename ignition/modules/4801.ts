import buildSatelliteDeployment from "../SatelliteDeployment";

export default buildSatelliteDeployment("4801", [
  "OwnershipModule",
  "SatelliteConnectionRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  // "DataProcessorModule",
  "EvmOnChainGrowingModule",
  "NativeParentHashFetcherModule",
  "OptimismReceiverModule",
]);
