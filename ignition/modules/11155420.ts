import buildSatelliteDeployment from "../SatelliteDeployment";

export default buildSatelliteDeployment("11155420", [
  "OwnershipModule",
  "SatelliteConnectionRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  "EvmOnChainGrowingModule",
  "NativeParentHashFetcherModule",
  "OptimismReceiverModule",
]);
