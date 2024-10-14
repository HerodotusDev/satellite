// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface INativeParentHashesFetcherModule {
    function nativeFetchParentHash(uint256 blockNumber) external;
}
