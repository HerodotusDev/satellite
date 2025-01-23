// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {IFactsRegistry} from "src/interfaces/external/IFactsRegistry.sol";

contract MockFactsRegistry {
    function isValid(bytes32 fact) external view returns (bool) {
        return true;
    }
}
