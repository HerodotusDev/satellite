// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ILibSatellite} from "./ILibSatellite.sol";
import {IOwnershipModule} from "./modules/IOwnershipModule.sol";
import {ISatelliteConnectionRegistryModule} from "./modules/ISatelliteConnectionRegistryModule.sol";
import {IMmrCoreModule} from "./modules/IMmrCoreModule.sol";
import {ISatelliteInspectorModule} from "./modules/ISatelliteInspectorModule.sol";
import {ISatelliteMaintenanceModule} from "./modules/ISatelliteMaintenanceModule.sol";
import {INativeSharpMmrGrowingModule} from "./modules/growing/INativeSharpMmrGrowingModule.sol";
import {IStarknetSharpMmrGrowingModule} from "./modules/growing/IStarknetSharpMmrGrowingModule.sol";
import {IEVMFactRegistryModule} from "./modules/IEVMFactRegistryModule.sol";
import {INativeBlockHashFetcherModule} from "./modules/block-hash-fetching/INativeBlockHashFetcherModule.sol";
import {IStarknetBlockHashFetcherModule} from "./modules/block-hash-fetching/IStarknetBlockHashFetcherModule.sol";
import {IReceiverModule} from "./modules/messaging/receiver/IReceiverModule.sol";
import {INativeOnChainGrowingModule} from "./modules/growing/INativeOnChainGrowingModule.sol";
import {IDataProcessorModule} from "./modules/IDataProcessorModule.sol";
import {IUniversalSenderModule} from "./modules/messaging/sender/IUniversalSenderModule.sol";
import {IL1ToArbitrumSenderModule} from "./modules/messaging/sender/IL1ToArbitrumSenderModule.sol";
import {IL1ToOptimismSenderModule} from "./modules/messaging/sender/IL1ToOptimismSenderModule.sol";
interface ISatellite is
    ILibSatellite,
    IOwnershipModule,
    ISatelliteConnectionRegistryModule,
    IMmrCoreModule,
    ISatelliteInspectorModule,
    ISatelliteMaintenanceModule,
    INativeSharpMmrGrowingModule,
    IEVMFactRegistryModule,
    INativeBlockHashFetcherModule,
    INativeOnChainGrowingModule,
    IStarknetSharpMmrGrowingModule,
    IReceiverModule,
    IUniversalSenderModule,
    IL1ToArbitrumSenderModule,
    IL1ToOptimismSenderModule,
    IStarknetBlockHashFetcherModule,
    IDataProcessorModule
{}
