// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {ILibSatellite} from "../ILibSatellite.sol";

interface ISatelliteRegistryModule {
    // ========================= Satellite Registration ========================= //

    /// @param chainId - chain ID where the other satellite is deployed
    /// @param satellite - address of the satellite deployed on `chainId`
    /// @param inbox - address of the contract deployed on our chain responsible for sending message to `chainId`
    /// @dev message can be sent to `chainId` if and only if `inbox` is set to non-zero address
    /// @param sendMessageSelector - selector of the function responsible for sending message to `chainId`, this function should be part of `messaging/sender/*.sol`
    /// @dev if `inbox` is set to 0x0, `sendMessageSelector` must be set to 0
    /// @param senderSatelliteAliased - (aliased) address of the satellite deployed on `chainId` that sends message to our chain
    /// @dev message can be received from `chainId` if and only if `senderSatelliteAlias` is set to non-zero address
    function registerSatellite(uint256 chainId, uint256 satellite, address inbox, bytes4 sendMessageSelector, address senderSatelliteAliased) external;

    /// @notice Event emitted when satellite is registered
    /// @param chainId - chain ID of the satellite
    /// @param satelliteAddress - address of the satellite deployed on `chainId` (uint256 because Starknet addresses must fit)
    /// @param canSendMessageTo - true if this satellite can send messages to satellite on `chainId`
    /// @param senderSatelliteAliased - (aliased) address of the satellite deployed on `chainId` that sends message to our chain, if 0 then satellite can't receive messages from `chainId`
    event SatelliteRegistered(uint256 chainId, uint256 satelliteAddress, bool canSendMessageTo, address senderSatelliteAliased);

    /// @notice When registering a satellite, `satelliteAddress` must be set to non-zero address
    error InvalidSatelliteAddress();
    /// @notice When registering a satellite with no inbox (non-connected satellite), `senderSatelliteAlias` and `sendMessageSelector` must be set to 0.
    error InvalidNonConnectedSatelliteParameters();
    /// @notice Satellite for that chain ID is already registered. Try calling `removeSatellite` first.
    error SenderSatelliteAlreadyRegistered();
    /// @notice `senderSatelliteAliased` is already registered as sender satellite.
    error SatelliteAlreadyRegistered();

    // ========================= Satellite Removal ========================= //

    /// @param chainId - chain id of other side of the connection
    /// @param senderSatelliteAlias - (aliased) address of the satellite deployed on `chainId` that sends message to our chain
    /// @dev `senderSatelliteAlias` should be the same as the one used when registering the connection
    function removeSatellite(uint256 chainId, address senderSatelliteAlias) external;

    /// @notice Event emitted when satellite is removed
    /// @param chainId - chain ID of the satellite
    /// @param satelliteAddress - address of the satellite deployed on `chainId` (uint256 because Starknet addresses must fit)
    event SatelliteRemoved(uint256 chainId, uint256 satelliteAddress);

    /// @notice Satellite for that chain ID is not registered.
    error SatelliteNotRegistered();
    /// @notice When removing a satellite that was sender satellite to our chain, `senderSatelliteAlias` must be set to non-zero address.
    /// @notice If it wasn't configured as sender satellite, `senderSatelliteAlias` must be set to 0x0.
    error InvalidSenderSatelliteAddress();

    // ========================= Satellite Retrieval ========================= //

    /// @param chainId - chain id of other side of the connection
    /// @return Satellite struct, which contains the satellite address, sendMessageSelector, inbox address and canReceive flag
    function getSatellite(uint256 chainId) external view returns (ILibSatellite.SatelliteData memory);
}
