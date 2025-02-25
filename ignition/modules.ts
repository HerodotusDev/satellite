import settings from "../settings.json";

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

    ...("DATA_PROCESSOR_FACTS_REGISTRY" in settings[chainId] &&
    "DATA_PROCESSOR_PROGRAM_HASH" in settings[chainId]
      ? {
          DataProcessorModule: {
            interfaceName: "IDataProcessorModule",
            initFunctions: [
              {
                name: "setDataProcessorProgramHash",
                args: [settings[chainId].DATA_PROCESSOR_PROGRAM_HASH],
              },
              {
                name: "setDataProcessorFactsRegistry",
                args: [settings[chainId].DATA_PROCESSOR_FACTS_REGISTRY],
              },
            ],
          },
        }
      : {}),

    EvmOnChainGrowingModule: {
      interfaceName: "IEvmOnChainGrowingModule",
    },

    ...("SHARP_FACT_REGISTRY" in settings[chainId]
      ? {
          EvmSharpMmrGrowingModule: {
            interfaceName: "IEvmSharpMmrGrowingModule",
            initFunctions: [
              {
                name: "initEvmSharpMmrGrowingModule",
                args: [settings[chainId].SHARP_FACT_REGISTRY],
              },
            ],
          },
        }
      : {}),

    ...("SHARP_FACT_REGISTRY" in settings[chainId] &&
    "STARKNET_CHAIN_ID" in settings[chainId]
      ? {
          StarknetSharpMmrGrowingModule: {
            interfaceName: "IStarknetSharpMmrGrowingModule",
            initFunctions: [
              {
                name: "initStarknetSharpMmrGrowingModule",
                args: [
                  settings[chainId].SHARP_FACT_REGISTRY,
                  settings[chainId].STARKNET_CHAIN_ID,
                ],
              },
            ],
          },
        }
      : {}),

    NativeParentHashFetcherModule: {
      interfaceName: "INativeParentHashFetcherModule",
    },

    ...("STARKNET_CORE" in settings[chainId] &&
    "STARKNET_CHAIN_ID" in settings[chainId]
      ? {
          StarknetParentHashFetcherModule: {
            interfaceName: "IStarknetParentHashFetcherModule",
            initFunctions: [
              {
                name: "initStarknetParentHashFetcherModule",
                args: [
                  settings[chainId].STARKNET_CORE,
                  settings[chainId].STARKNET_CHAIN_ID,
                ],
              },
            ],
          },
        }
      : {}),

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

    ...("APE_CHAIN_TOKEN_ADDRESS" in settings[chainId]
      ? {
          ArbitrumToApeChainSenderModule: {
            interfaceName: "IArbitrumToApeChainSenderModule",
            initFunctions: [
              {
                name: "setApeChainTokenAddress",
                args: [settings[chainId].APE_CHAIN_TOKEN_ADDRESS],
              },
            ],
          },
        }
      : {}),

    SimpleReceiverModule: {
      interfaceName: "IReceiverModule",
    },

    OptimismReceiverModule: {
      interfaceName: "IReceiverModule",
    },

    L1ToStarknetSenderModule: {
      interfaceName: "IL1ToStarknetSenderModule",
    },
  }) satisfies Record<string, Module>;
