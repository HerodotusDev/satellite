// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStarknet {
    function stateBlockNumber() external view returns (int256);

    function stateBlockHash() external view returns (uint256);
}
