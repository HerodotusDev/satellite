// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IFactsRegistry} from "interfaces/external/IFactsRegistry.sol";

contract MockFactsRegistry is IFactsRegistry {
    function isValid(bytes32) external pure returns (bool) {
        return true;
    }
}
