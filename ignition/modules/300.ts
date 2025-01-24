// ZkSync is handled separately by deploy/deploy.ts

export const modules = [
  "OwnershipModule",
  "SatelliteConnectionRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EVMFactRegistryModule",
  "EvmOnChainGrowingModule",
  "NativeParentHashFetcherModule",
  "SimpleReceiverModule",
] as const;
