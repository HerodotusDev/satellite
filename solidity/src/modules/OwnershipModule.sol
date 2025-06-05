// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {LibSatellite} from "src/libraries/LibSatellite.sol";
import {IOwnershipModule} from "src/interfaces/modules/IOwnershipModule.sol";
import {AccessController} from "src/libraries/AccessController.sol";

contract OwnershipModule is IOwnershipModule, AccessController {
    function transferOwnership(address _newOwner) external override onlyOwner {
        LibSatellite.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibSatellite.contractOwner();
    }
}
