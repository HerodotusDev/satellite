// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface INativeParentHashFetcherModule {
    function nativeFetchParentHash(uint256 blockNumber) external;
}
