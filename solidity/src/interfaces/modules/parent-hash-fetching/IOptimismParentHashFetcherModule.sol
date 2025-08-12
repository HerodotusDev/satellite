// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface IDisputeGameFactory {
    function gameAtIndex(uint256 _index) external view returns (uint32 gameType, uint64 timestamp, address proxy);
}

interface IFaultDisputeGame {
    /// @notice Getter for the root claim of the dispute game.
    /// @return The root claim.
    function rootClaim() external view returns (bytes32);

    /// @notice Returns the current status of the game.
    /// @return The current game status.
    function status() external view returns (uint8);

    /// @notice Getter for the creator of the dispute game.
    /// @return The address of the game creator.
    function gameCreator() external view returns (address);
}

struct OptimismFetcherChainInfo {
    // Dispute game factory
    IDisputeGameFactory disputeGameFactory;
    // Dispute game
    address trustedGameProposer;
}

struct OptimismParentHashFetcherModuleStorage {
    // Chain ID of blocks being fetched
    mapping(uint256 chainId => OptimismFetcherChainInfo) chainInfo;
}

/// @notice Module that fetches the parent hash of blocks from Arbitrum
/// @dev It needs to be deployed on the chain that Arbitrum settles on (L1)
interface IOptimismParentHashFetcherModule {
    event OptimismParentHashFetcherInitialized(uint256 chainId, address disputeGameFactory, address trustedGameProposer);

    function initOptimismParentHashFetcherModule(uint256 chainId, address disputeGameFactory, address trustedGameProposer) external;

    function optimismFetchParentHash(uint256 chainId, uint256 gameIndex, bytes32 versionByte, bytes32 stateRoot, bytes32 withdrawalStorageRoot, bytes memory blockHeader) external;
}
