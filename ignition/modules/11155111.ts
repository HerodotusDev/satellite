import buildSatelliteDeployment from "../SatelliteDeployment";

export default buildSatelliteDeployment("11155111", [
  "OwnershipModule",
  "SatelliteConnectionRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EVMFactRegistryModule",
  "DataProcessorModule",
  "EvmOnChainGrowingModule",
  "EvmSharpMmrGrowingModule",
  "StarknetSharpMmrGrowingModule",
  "NativeParentHashFetcherModule",
  "StarknetParentHashFetcherModule",
  "UniversalSenderModule",
  "L1ToArbitrumSenderModule",
  "L1ToOptimismSenderModule",
  "L1ToZkSyncSenderModule",
]);
