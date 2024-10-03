// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

/// @notice This struct represents a Merkle Mountain Range accumulating provably valid block hashes
/// @dev each MMR is mapped to a unique ID also referred to as mmrId
struct MMRInfo {
    /// @notice latestSize represents the latest size of the MMR
    uint256 latestSize;
    /// @notice mmrSizeToRoot maps the MMR size to the MMR root, that way we have automatic versioning
    mapping(uint256 => bytes32) mmrSizeToRoot;
}
