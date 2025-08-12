import settings from "../settings.json";

interface InitFunction {
  name: string;
  args: any[];
}

export interface Module {
  interfaceName: string;
  isExternal?: boolean; // true if this contract shouldn't be connected to the satellite
  initFunctions?: InitFunction[];
}

export const modules = (chainId: keyof typeof settings) =>
  ({
    OwnershipModule: {
      interfaceName: "IExtendedOwnershipModule",
    },

    SatelliteInspectorModule: {
      interfaceName: "ISatelliteInspectorModule",
    },

    SatelliteRegistryModule: {
      interfaceName: "ISatelliteRegistryModule",
    },

    MmrCoreModule: {
      interfaceName: "IMmrCoreModule",
    },

    EvmFactRegistryModule: {
      interfaceName: "IEvmFactRegistryModule",
    },

    EvmOnChainGrowingModule: {
      interfaceName: "IEvmOnChainGrowingModule",
    },

    ...("CAIRO_FACT_REGISTRY_IS_MOCKED" in settings[chainId]
      ? {
          CairoFactRegistryModule: {
            interfaceName: "ICairoFactRegistryModule",
            initFunctions: [
              {
                name: "setIsMockedForInternal",
                args: [settings[chainId].CAIRO_FACT_REGISTRY_IS_MOCKED],
              },
              ...("CAIRO_FACT_REGISTRY_EXTERNAL_CONTRACT" in settings[chainId]
                ? [
                    {
                      name: "setCairoVerifiedFactRegistryContract",
                      args: [
                        settings[chainId].CAIRO_FACT_REGISTRY_EXTERNAL_CONTRACT,
                      ],
                    },
                  ]
                : []),
              ...("CAIRO_FACT_REGISTRY_MOCKED_FALLBACK" in settings[chainId]
                ? [
                    {
                      name: "setCairoMockedFactRegistryFallbackContract",
                      args: [
                        settings[chainId].CAIRO_FACT_REGISTRY_MOCKED_FALLBACK,
                      ],
                    },
                  ]
                : []),
            ],
          },
        }
      : {}),

    ...("DATA_PROCESSOR_PROGRAM_HASH" in settings[chainId] &&
    "CAIRO_FACT_REGISTRY_IS_MOCKED" in settings[chainId]
      ? {
          DataProcessorModule: {
            interfaceName: "IDataProcessorModule",
            initFunctions: [
              {
                name: "setDataProcessorProgramHash",
                args: [settings[chainId].DATA_PROCESSOR_PROGRAM_HASH],
              },
            ],
          },
        }
      : {}),

    ...("EVM_SHARP_GROWER_PROGRAM_HASH" in settings[chainId] &&
    "CAIRO_FACT_REGISTRY_IS_MOCKED" in settings[chainId]
      ? {
          EvmSharpMmrGrowingModule: {
            interfaceName: "IEvmSharpMmrGrowingModule",
            initFunctions: [
              {
                name: "initEvmSharpMmrGrowingModule",
                args: [],
              },
            ],
          },
        }
      : {}),

    ...("STARKNET_CHAIN_ID" in settings[chainId] &&
    "CAIRO_FACT_REGISTRY_IS_MOCKED" in settings[chainId]
      ? {
          StarknetSharpMmrGrowingModule: {
            interfaceName: "IStarknetSharpMmrGrowingModule",
            initFunctions: [
              {
                name: "initStarknetSharpMmrGrowingModule",
                args: [settings[chainId].STARKNET_CHAIN_ID],
              },
            ],
          },
        }
      : {}),

    NativeArbitrumParentHashFetcherModule: {
      interfaceName: "INativeParentHashFetcherModule",
    },

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

    ...("ARBITRUM_FETCHER_OUTBOX_ADDRESS" in settings[chainId] &&
    "ARBITRUM_FETCHER_CHAIN_ID" in settings[chainId]
      ? {
          ArbitrumParentHashFetcherModule: {
            interfaceName: "IArbitrumParentHashFetcherModule",
            initFunctions: [
              {
                name: "initArbitrumParentHashFetcherModule",
                args: [
                  settings[chainId].ARBITRUM_FETCHER_OUTBOX_ADDRESS,
                  settings[chainId].ARBITRUM_FETCHER_CHAIN_ID,
                ],
              },
            ],
          },
        }
      : {}),

    ...("OPTIMISM_FETCHERS" in settings[chainId]
      ? {
          OptimismParentHashFetcherModule: {
            interfaceName: "IOptimismParentHashFetcherModule",
            initFunctions: (
              settings[chainId].OPTIMISM_FETCHERS as {
                chainId: string;
                disputeGameFactory: string;
                trustedGameProposer: string;
              }[]
            ).map((fetcher) => ({
              name: "addOptimismParentHashFetcher",
              args: [
                fetcher.chainId,
                fetcher.disputeGameFactory,
                fetcher.trustedGameProposer,
              ],
            })),
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

    LegacyContractsInteractionModule: {
      interfaceName: "ILegacyContractsInteractionModule",
      initFunctions: [],
    },

    MockFactsRegistry: {
      interfaceName: "IFactsRegistry",
      isExternal: true,
    },
  }) satisfies Record<string, Module>;
