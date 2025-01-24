// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ILibSatellite} from "./ILibSatellite.sol";
import {IOwnershipModule} from "./modules/IOwnershipModule.sol";
import {ISatelliteConnectionRegistryModule} from "./modules/ISatelliteConnectionRegistryModule.sol";
import {IMmrCoreModule} from "./modules/IMmrCoreModule.sol";
import {ISatelliteInspectorModule} from "./modules/ISatelliteInspectorModule.sol";
import {ISatelliteMaintenanceModule} from "./modules/ISatelliteMaintenanceModule.sol";
import {IEvmSharpMmrGrowingModule} from "./modules/growing/IEvmSharpMmrGrowingModule.sol";
import {IStarknetSharpMmrGrowingModule} from "./modules/growing/IStarknetSharpMmrGrowingModule.sol";
import {IEVMFactRegistryModule} from "./modules/IEVMFactRegistryModule.sol";
import {INativeParentHashFetcherModule} from "./modules/parent-hash-fetching/INativeParentHashFetcherModule.sol";
import {IStarknetParentHashFetcherModule} from "./modules/parent-hash-fetching/IStarknetParentHashFetcherModule.sol";
import {IReceiverModule} from "./modules/messaging/receiver/IReceiverModule.sol";
import {IEvmOnChainGrowingModule} from "./modules/growing/IEvmOnChainGrowingModule.sol";
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
    IEvmSharpMmrGrowingModule,
    IEVMFactRegistryModule,
    INativeParentHashFetcherModule,
    IEvmOnChainGrowingModule,
    IStarknetSharpMmrGrowingModule,
    IReceiverModule,
    IUniversalSenderModule,
    IL1ToArbitrumSenderModule,
    IL1ToOptimismSenderModule,
    IStarknetParentHashFetcherModule,
    IDataProcessorModule
{}
