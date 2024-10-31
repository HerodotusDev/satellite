// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {IStarknet} from "interfaces/external/IStarknet.sol";

contract MockStarknetCore is IStarknet {
    int256 blockNumber = 0;
    uint256 blockHash = 0;

    function stateBlockNumber() external view override returns (int256) {
        return blockNumber;
    }

    function stateBlockHash() external view override returns (uint256) {
        return blockHash;
    }
}
