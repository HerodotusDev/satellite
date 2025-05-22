// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Script as S} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ISatellite} from "src/interfaces/ISatellite.sol";

contract Script is S {
    // Private key taken from .env
    uint256 public PK = vm.envUint("PRIVATE_KEY");

    // Private key of account that deploys to chain 31337
    uint256 public deployerPK;

    // Deployed satellite contract
    ISatellite public satellite = ISatellite(vm.envAddress("SATELLITE_ADDRESS"));

    uint256 public chainId;
    uint256 public forkChainId;

    constructor() {
        chainId = block.chainid;
        forkChainId = vm.envUint("FORK_CHAIN_ID");
        if (forkChainId == 31337) {
            deployerPK = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        } else {
            deployerPK = PK;
            console.log("NOTE: Using deployerPK equal to PK (PRIVATE_KEY from .env)\n");
        }
    }
}
