import buildSatelliteDeployment from "../SatelliteDeployment";

export default buildSatelliteDeployment("Satellite_11155111", [
  {
    moduleName: "OwnershipModule",
    interfaceName: "IOwnershipModule",
  },
  {
    moduleName: "SatelliteInspectorModule",
    interfaceName: "ISatelliteInspectorModule",
  },
  {
    moduleName: "MmrCoreModule",
    interfaceName: "IMmrCoreModule",
  },
  {
    moduleName: "NativeSharpMmrGrowingModule",
    interfaceName: "INativeSharpMmrGrowingModule",
    initFunction: {
      name: "initNativeSharpMmrGrowingModule",
      args: ["0x0ed8c44415e882F3033B4F3AFF916BbB4997f915"],
    },
  },
  {
    moduleName: "EVMFactRegistryModule",
    interfaceName: "IEVMFactRegistryModule",
  },
  {
    moduleName: "NativeParentHashFetcherModule",
    interfaceName: "INativeParentHashFetcherModule",
  },
  {
    moduleName: "NativeOnChainGrowingModule",
    interfaceName: "INativeOnChainGrowingModule",
  },
  {
    moduleName: "StarknetSharpMmrGrowingModule",
    interfaceName: "IStarknetSharpMmrGrowingModule",
  },
  {
    moduleName: "StarknetParentHashFetcherModule",
    interfaceName: "IStarknetParentHashFetcherModule",
  },
  {
    moduleName: "DataProcessorModule",
    interfaceName: "IDataProcessorModule",
  },
  {
    moduleName: "SatelliteConnectionRegistryModule",
    interfaceName: "ISatelliteConnectionRegistryModule",
  },
  {
    moduleName: "UniversalSenderModule",
    interfaceName: "IUniversalSenderModule",
  },
  {
    moduleName: "L1ToArbitrumSenderModule",
    interfaceName: "IL1ToArbitrumSenderModule",
  },
  {
    moduleName: "L1ToOptimismSenderModule",
    interfaceName: "IL1ToOptimismSenderModule",
  },
]);
