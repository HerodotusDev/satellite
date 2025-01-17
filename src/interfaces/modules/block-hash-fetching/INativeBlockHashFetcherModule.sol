// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

/// @notice Module that fetches the block hash of blocks from the chain it's deployed on
interface INativeBlockHashFetcherModule {
    /// @notice Fetches the block hash of a given block
    function nativeFetchBlockHash(uint256 blockNumber) external;
}
