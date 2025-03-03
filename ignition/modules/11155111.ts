import buildSatelliteDeployment, { ModuleName } from "../SatelliteDeployment";

export const modules: ModuleName[] = [
  "OwnershipModule",
  "SatelliteConnectionRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
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
  "L1ToStarknetSenderModule",
];
export default buildSatelliteDeployment("11155111", modules);
