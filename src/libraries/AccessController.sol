// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {LibSatellite} from "src/libraries/LibSatellite.sol";

abstract contract AccessController {
    modifier onlyModule() {
        LibSatellite.enforceIsSatelliteModule();
        _;
    }

    modifier onlyOwner() {
        LibSatellite.enforceIsContractOwner();
        _;
    }
}
