import buildSatelliteDeployment, { ModuleName } from "../SatelliteDeployment";

export const modules: ModuleName[] = [
  "OwnershipModule",
  "SatelliteConnectionRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  // "DataProcessorModule",
  "EvmOnChainGrowingModule",
  "NativeParentHashFetcherModule",
  "ArbitrumParentHashFetcherModule",
  "SimpleReceiverModule",
  "UniversalSenderModule",
  "ArbitrumToApeChainSenderModule",
];
export default buildSatelliteDeployment("421614", modules);
