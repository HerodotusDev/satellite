import buildSatelliteDeployment from "../SatelliteDeployment";

export default buildSatelliteDeployment("421614", [
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
