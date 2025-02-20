import buildSatelliteDeployment from "../SatelliteDeployment";

export default buildSatelliteDeployment("33111", [
  "OwnershipModule",
  "SatelliteConnectionRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  // "DataProcessorModule",
  "EvmOnChainGrowingModule",
  "NativeParentHashFetcherModule",
  "SimpleReceiverModule",
]);
