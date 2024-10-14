// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {IFactsRegistry} from "interfaces/external/IFactsRegistry.sol";

contract MockFactsRegistry is IFactsRegistry {
    function isValid(bytes32) external pure returns (bool) {
        return true;
    }
}
