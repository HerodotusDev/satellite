// ZkSync is handled separately by deploy/deploy.ts

export const modules = [
  "OwnershipModule",
  "SatelliteConnectionRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  "CairoFactRegistryModule",
  // "DataProcessorModule",
  "EvmOnChainGrowingModule",
  // "NativeParentHashFetcherModule", // TODO: check if ZKSync supports blockhash function correctly
  "SimpleReceiverModule",
] as const;
