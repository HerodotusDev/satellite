// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {LibSatellite} from "libraries/LibSatellite.sol";
import {IOwnershipModule} from "interfaces/modules/IOwnershipModule.sol";

contract OwnershipModule is IOwnershipModule {
    function transferOwnership(address _newOwner) external override {
        LibSatellite.enforceIsContractOwner();
        LibSatellite.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibSatellite.contractOwner();
    }
}
