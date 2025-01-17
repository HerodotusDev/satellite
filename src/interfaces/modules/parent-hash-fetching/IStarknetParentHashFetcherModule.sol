// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

/// @notice Module that fetches the parent hash of blocks from Starknet
/// @dev It needs to be deployed on the chain that Starknet settles on (L1)
interface IStarknetParentHashFetcherModule {
    /// @notice Fetches the parent hash of the latest block
    function starknetFetchParentHash() external;
}
