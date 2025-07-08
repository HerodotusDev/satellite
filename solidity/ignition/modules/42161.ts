import buildSatelliteDeployment, { ModuleName } from "../SatelliteDeployment";

export const modules: ModuleName[] = [
  "OwnershipModule",
  "SatelliteConnectionRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  "EvmOnChainGrowingModule",
  "ArbitrumParentHashFetcherModule",
  "SimpleReceiverModule",
  "UniversalSenderModule",
  "ArbitrumToApeChainSenderModule",
];
export default buildSatelliteDeployment("42161", modules);
