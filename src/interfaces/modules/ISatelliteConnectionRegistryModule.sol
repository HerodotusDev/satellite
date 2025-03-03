// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ILibSatellite} from "src/interfaces/ILibSatellite.sol";

interface ISatelliteConnectionRegistryModule {
    /// @param chainId - chain id of other side of the connection
    /// @param satellite - address of the satellite deployed on `chainId`
    /// @param inbox - address of the contract deployed on our chain responsible for sending message to `chainId`
    /// @dev message can be sent to `chainId` if and only if `inbox` is set to non-zero address
    /// @param senderSatelliteAlias - (aliased) address of the satellite deployed on `chainId` that sends message to our chain
    /// @dev message can be received from `chainId` if and only if `senderSatelliteAlias` is set to non-zero address
    /// @param sendMessageSelector - selector of the function responsible for sending message to `chainId`, this function should be part of `messaging/sender/*.sol`
    function registerSatelliteConnection(uint256 chainId, uint256 satellite, address inbox, address senderSatelliteAlias, bytes4 sendMessageSelector) external;

    /// @param chainId - chain id of other side of the connection
    /// @param senderSatelliteAlias - (aliased) address of the satellite deployed on `chainId` that sends message to our chain
    /// @dev `senderSatelliteAlias` should be the same as the one used when registering the connection
    function removeSatelliteConnection(uint256 chainId, address senderSatelliteAlias) external;

    /// @param chainId - chain id of other side of the connection
    /// @return SatelliteConnection struct, which contains the satellite address, inbox address, and sendMessageSelector
    function getSatelliteConnection(uint256 chainId) external view returns (ILibSatellite.SatelliteConnection memory);
}
