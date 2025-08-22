// ZkSync is handled separately by deploy/deploy.ts

export const modules = [
  "OwnershipModule",
  "SatelliteRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  "EvmOnChainGrowingModule",
  // "NativeParentHashFetcherModule", // TODO: check if ZKSync supports blockhash function correctly
  "SimpleReceiverModule",
] as const;
