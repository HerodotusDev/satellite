// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {TaskCode} from "./Task.sol";

/// @dev A module task.
/// @param programHash The program hash of the module.
/// @param inputs The inputs to the module.
struct ModuleTask {
    bytes32 programHash;
    bytes32[] inputs;
}

/// @notice Codecs for ModuleTask.
/// @dev Represent module with a program hash and inputs.
library ModuleCodecs {
    /// @dev Get the commitment of a Module.
    /// @param module The Module to commit.
    function commit(ModuleTask memory module) internal pure returns (bytes32) {
        return keccak256(abi.encode(module.programHash, module.inputs));
    }
}
