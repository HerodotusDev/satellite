import buildSatelliteDeployment, { ModuleName } from "../SatelliteDeployment";

export const modules: ModuleName[] = [
  "OwnershipModule",
  "SatelliteRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  "CairoFactRegistryModule",
  "DataProcessorModule",
  "EvmOnChainGrowingModule",
  "EvmSharpMmrGrowingModule",
  "StarknetSharpMmrGrowingModule",
  "NativeParentHashFetcherModule",
  "StarknetParentHashFetcherModule",
  "OptimismParentHashFetcherModule",
  "UniversalSenderModule",
  "L1ToArbitrumSenderModule",
  "L1ToOptimismSenderModule",
  "L1ToZkSyncSenderModule",
  "L1ToStarknetSenderModule",
  "LegacyContractsInteractionModule",
];
export default buildSatelliteDeployment("11155111", modules);
