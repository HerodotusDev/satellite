// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface IERC20Outbox {
    function roots(bytes32 input) external view returns (bytes32);
}

/// @notice Module that fetches the parent hash of blocks from Arbitrum
/// @dev It needs to be deployed on the chain that Arbitrum settles on (L1)
interface IArbitrumParentHashFetcherModule {
    struct ArbitrumParentHashFetcherModuleStorage {
        IERC20Outbox outboxContract;
        // Chain ID of blocks being fetched
        uint256 chainId;
    }

    function initArbitrumParentHashFetcherModule(address outboxAddress, uint256 chainId) external;

    function arbitrumFetchParentHash(bytes32 rootHash, bytes memory blockHeader) external;
}
