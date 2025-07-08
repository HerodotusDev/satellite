import buildSatelliteDeployment, { ModuleName } from "../SatelliteDeployment";

export const modules: ModuleName[] = [
  "OwnershipModule",
  "SatelliteRegistryModule",
  "SatelliteInspectorModule",
  "MmrCoreModule",
  "EvmFactRegistryModule",
  "EvmOnChainGrowingModule",
  "ArbitrumParentHashFetcherModule",
  "SimpleReceiverModule",
  "UniversalSenderModule",
  "ArbitrumToApeChainSenderModule",
];
export default buildSatelliteDeployment("421614", modules);
