// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {LibSatellite} from "../libraries/LibSatellite.sol";
import {IExtendedOwnershipModule} from "../interfaces/modules/IOwnershipModule.sol";
import {AccessController} from "../libraries/AccessController.sol";

contract OwnershipModule is IExtendedOwnershipModule, AccessController {
    function transferOwnership(address _newOwner) external override onlyOwner {
        LibSatellite.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibSatellite.contractOwner();
    }

    function isAdmin(address account) external view override returns (bool) {
        return LibSatellite.isAdmin(account);
    }

    function manageAdmins(address[] calldata accounts, bool _isAdmin) external override onlyOwner {
        LibSatellite.manageAdmins(accounts, _isAdmin);
    }
}
