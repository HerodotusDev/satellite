// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {IFactsRegistry} from "../interfaces/external/IFactsRegistry.sol";

contract AuthenticatedMockFactsRegistry is IFactsRegistry {
    mapping(bytes32 => bool) private _isValid;
    address public owner;
    mapping(address => bool) public isAdmin;
    address public isValidFallback;
    address public setValidFallback;

    event FactRegistered(bytes32 indexed fact);
    event AdminStatusChanged(address indexed admin, bool isAdmin);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FallbacksChanged(address indexed isValidFallback, address indexed setValidFallback);

    constructor(address _owner) {
        require(_owner != address(0), "Owner cannot be zero address");
        owner = _owner;
    }

    function isValid(bytes32 fact) external view override returns (bool) {
        if (_isValid[fact]) {
            return true;
        }
        if (isValidFallback != address(0)) {
            return IFactsRegistry(isValidFallback).isValid(fact);
        }
        return false;
    }

    function setValid(bytes32 fact) external onlyAdmin {
        _isValid[fact] = true;
        emit FactRegistered(fact);

        if (setValidFallback != address(0)) {
            IFactsRegistry(setValidFallback).setValid(fact);
        }
    }

    function manageAdmins(address[] calldata admins, bool isAdmin_) external onlyOwner {
        require(admins.length > 0, "Empty admin array");
        for (uint256 i = 0; i < admins.length; i++) {
            require(admins[i] != address(0), "Admin cannot be zero address");
            isAdmin[admins[i]] = isAdmin_;
            emit AdminStatusChanged(admins[i], isAdmin_);
        }
    }

    function manageFallbacks(address _isValidFallback, address _setValidFallback) external onlyOwner {
        isValidFallback = _isValidFallback;
        setValidFallback = _setValidFallback;
        emit FallbacksChanged(_isValidFallback, _setValidFallback);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin can call this function");
        _;
    }
}
