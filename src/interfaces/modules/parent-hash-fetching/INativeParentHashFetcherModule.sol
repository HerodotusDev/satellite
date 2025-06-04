// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

/// @notice Module that fetches the parent hash of blocks from the chain it's deployed on
/// @notice Does not work on Arbitrum and Apechain, because they return L1 block hash from blockhash() function
interface INativeParentHashFetcherModule {
    /// @notice Fetches the parent hash of a given block
    function nativeFetchParentHash(uint256 blockNumber) external;
}
