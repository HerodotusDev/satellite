// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface IFactsRegistry {
    function isValid(bytes32 fact) external view returns (bool);

    function setValid(bytes32 fact) external;
}
