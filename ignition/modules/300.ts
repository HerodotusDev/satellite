// ZkSync is handled separately by deploy/deploy.ts

export const modules = [
  "OwnershipModule",
  "SatelliteConnectionRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EVMFactRegistryModule",
  "NativeOnChainGrowingModule",
  "NativeParentHashFetcherModule",
  "SimpleReceiverModule",
] as const;
