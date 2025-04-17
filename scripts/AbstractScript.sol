// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Script as S} from "forge-std/Script.sol";
import {ISatellite} from "src/interfaces/ISatellite.sol";

contract Script is S {
    // Private key taken from .env
    uint256 public PK = vm.envUint("PRIVATE_KEY");

    // TODO: this shouldn't be here for not 31337
    // Private key of account that deploys to chain 31337
    uint256 public deployerPK = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    // Deployed satellite contract
    ISatellite public satellite = ISatellite(vm.envAddress("SATELLITE_ADDRESS"));
}
