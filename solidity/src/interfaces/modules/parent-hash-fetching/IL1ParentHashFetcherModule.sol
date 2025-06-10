// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

/// @notice Module that fetches the parent hash of blocks from L1
/// @notice It works only on Arbitrum and Apechain, because they return L1 block hash from blockhash() function
interface IL1ParentHashFetcherModule {
    struct L1ParentHashFetcherModuleStorage {
        // Chain ID of the L1 chain
        uint256 l1ChainId;
    }

    /// @notice Fetches the parent hash of a given block
    function l1FetchParentHash(uint256 blockNumber) external;

    /// @notice Initializes the module
    /// @param l1ChainId Chain ID of the L1 chain
    function initL1ParentHashFetcherModule(uint256 l1ChainId) external;
}
