import settings from "../settings.json";

const DATA_PROCESSOR_PROGRAM_HASH =
  "0x0000000000000000000000000000000000000000000000000000000000000000";

interface InitFunction {
  name: string;
  args: any[];
}

export interface Module {
  interfaceName: string;
  initFunctions?: InitFunction[];
}

export const modules = (chainId: keyof typeof settings) =>
  ({
    OwnershipModule: {
      interfaceName: "IOwnershipModule",
    },
    SatelliteInspectorModule: {
      interfaceName: "ISatelliteInspectorModule",
    },
    SatelliteConnectionRegistryModule: {
      interfaceName: "ISatelliteConnectionRegistryModule",
    },

    MmrCoreModule: {
      interfaceName: "IMmrCoreModule",
    },
    EvmFactRegistryModule: {
      interfaceName: "IEvmFactRegistryModule",
    },
    DataProcessorModule: {
      interfaceName: "IDataProcessorModule",
      initFunctions: [
        {
          name: "setDataProcessorProgramHash",
          args: [DATA_PROCESSOR_PROGRAM_HASH],
        },
        {
          name: "setDataProcessorFactsRegistry",
          args: [(settings[chainId] as any)?.DATA_PROCESSOR_FACTS_REGISTRY],
        },
      ],
    },

    EvmOnChainGrowingModule: {
      interfaceName: "IEvmOnChainGrowingModule",
    },
    EvmSharpMmrGrowingModule: {
      interfaceName: "IEvmSharpMmrGrowingModule",
      initFunctions: [
        {
          name: "initEvmSharpMmrGrowingModule",
          args: [(settings[chainId] as any)?.SHARP_FACT_REGISTRY],
        },
      ],
    },
    StarknetSharpMmrGrowingModule: {
      interfaceName: "IStarknetSharpMmrGrowingModule",
      initFunctions: [
        {
          name: "initStarknetSharpMmrGrowingModule",
          args: [(settings[chainId] as any)?.SHARP_FACT_REGISTRY],
        },
      ],
    },

    NativeParentHashFetcherModule: {
      interfaceName: "INativeParentHashFetcherModule",
    },
    StarknetParentHashFetcherModule: {
      interfaceName: "IStarknetParentHashFetcherModule",
      initFunctions: [
        {
          name: "initStarknetParentHashFetcherModule",
          args: [
            (settings[chainId] as any).STARKNET_CORE,
            (settings[chainId] as any).STARKNET_CHAIN_ID,
          ],
        },
      ],
    },

    UniversalSenderModule: {
      interfaceName: "IUniversalSenderModule",
    },
    L1ToArbitrumSenderModule: {
      interfaceName: "IL1ToArbitrumSenderModule",
    },
    L1ToOptimismSenderModule: {
      interfaceName: "IL1ToOptimismSenderModule",
    },
    L1ToZkSyncSenderModule: {
      interfaceName: "IL1ToZkSyncSenderModule",
    },

    SimpleReceiverModule: {
      interfaceName: "IReceiverModule",
    },
    OptimismReceiverModule: {
      interfaceName: "IReceiverModule",
    },
  }) satisfies Record<string, Module>;
