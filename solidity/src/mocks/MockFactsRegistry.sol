// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {IFactsRegistry} from "../interfaces/external/IFactsRegistry.sol";

contract MockFactsRegistry is IFactsRegistry {
    mapping(bytes32 => bool) public isValid;

    function setValid(bytes32 fact) external {
        isValid[fact] = true;
    }
}
