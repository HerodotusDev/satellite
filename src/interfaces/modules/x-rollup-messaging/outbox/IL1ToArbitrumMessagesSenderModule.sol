// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {LibSatellite} from "libraries/LibSatellite.sol";
import {ISatellite} from "interfaces/ISatellite.sol";
import {RootForHashingFunction} from "interfaces/modules/IMMRsCoreModule.sol";

interface IL1ToArbitrumMessagesSenderModule {
    function configure(address arbitrumInbox, address arbitrumSatellite) external;

    function sendParentHashL1ToArbitrum(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes calldata _xDomainMsgGasData) external payable;
}
