// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {ISP1FactRegistryModule} from "../interfaces/modules/ISP1FactRegistryModule.sol";
import {ISP1Verifier} from "../interfaces/external/ISP1Verifier.sol";
import {AccessController} from "../libraries/AccessController.sol";
import {ISatellite} from "../interfaces/ISatellite.sol";

struct SP1FactRegistryModuleStorage {
    address sp1Verifier;
    bytes32 programVKey;
}

contract SP1FactRegistryModule is ISP1FactRegistryModule, AccessController {
    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.satellite.module.storage.sp1-fact-registry");

    function moduleStorage() internal pure returns (SP1FactRegistryModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    /// @inheritdoc ISP1FactRegistryModule
    function verifyAndRegisterSP1Fact(bytes calldata publicValues, bytes calldata proofBytes) external {
        SP1FactRegistryModuleStorage storage ms = moduleStorage();
        require(ms.sp1Verifier != address(0), "SP1: verifier not set");

        ISP1Verifier(ms.sp1Verifier).verifyProof(ms.programVKey, publicValues, proofBytes);

        bytes32 factHash = abi.decode(publicValues, (bytes32));

        ISatellite(address(this))._receiveCairoFactHash(factHash, false);
        emit SP1FactRegistered(factHash, msg.sender);
    }

    /// @inheritdoc ISP1FactRegistryModule
    function setProgramVKey(bytes32 newVKey) external onlyOwner {
        SP1FactRegistryModuleStorage storage ms = moduleStorage();
        bytes32 oldVKey = ms.programVKey;
        ms.programVKey = newVKey;
        emit VKeyUpdated(oldVKey, newVKey);
    }

    /// @inheritdoc ISP1FactRegistryModule
    function setSP1Verifier(address newVerifier) external onlyOwner {
        require(newVerifier != address(0), "SP1: zero address");
        SP1FactRegistryModuleStorage storage ms = moduleStorage();
        address oldVerifier = ms.sp1Verifier;
        ms.sp1Verifier = newVerifier;
        emit SP1VerifierUpdated(oldVerifier, newVerifier);
    }

    /// @inheritdoc ISP1FactRegistryModule
    function getSP1Verifier() external view returns (address) {
        return moduleStorage().sp1Verifier;
    }

    /// @inheritdoc ISP1FactRegistryModule
    function getProgramVKey() external view returns (bytes32) {
        return moduleStorage().programVKey;
    }
}
