// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {ICairoFactRegistryModule} from "../interfaces/modules/ICairoFactRegistryModule.sol";
import {IFactsRegistry} from "../interfaces/external/IFactsRegistry.sol";
import {AccessController} from "../libraries/AccessController.sol";

struct CairoFactRegistryModuleStorage {
    // It is stored here so that it can be storage proven between satellites.
    mapping(bytes32 => bool) facts;
    mapping(bytes32 => bool) mockedFacts;
    IFactsRegistry fallbackContract;
    bool isMockedForInternal;
}

contract CairoFactRegistryModule is ICairoFactRegistryModule, AccessController {
    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.satellite.module.storage.cairo-fact-registry-module");

    function moduleStorage() internal pure returns (CairoFactRegistryModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    /// @inheritdoc ICairoFactRegistryModule
    function isCairoFactValid(bytes32 factHash) external view returns (bool) {
        CairoFactRegistryModuleStorage storage ms = moduleStorage();
        return ms.facts[factHash] || ms.fallbackContract.isValid(factHash);
    }

    /// @inheritdoc ICairoFactRegistryModule
    function isCairoFactStored(bytes32 factHash) external view returns (bool) {
        return moduleStorage().facts[factHash];
    }

    /// @inheritdoc ICairoFactRegistryModule
    function getCairoFactRegistryExternalContract() external view returns (address) {
        return address(moduleStorage().fallbackContract);
    }

    /// @inheritdoc ICairoFactRegistryModule
    function storeCairoFact(bytes32 factHash) external {
        CairoFactRegistryModuleStorage storage ms = moduleStorage();
        require(ms.fallbackContract.isValid(factHash), "Fact hash not registered");
        ms.facts[factHash] = true;
    }

    /// @inheritdoc ICairoFactRegistryModule
    function isCairoMockedFactValid(bytes32 factHash) external view returns (bool) {
        return moduleStorage().mockedFacts[factHash];
    }

    /// @inheritdoc ICairoFactRegistryModule
    function setCairoMockedFact(bytes32 factHash) external onlyAdmin {
        moduleStorage().mockedFacts[factHash] = true;
    }

    // ========= For internal use in grower and data processor ========= //

    /// @inheritdoc ICairoFactRegistryModule
    function isCairoFactValidForInternal(bytes32 factHash) external view returns (bool) {
        CairoFactRegistryModuleStorage storage ms = moduleStorage();
        if(ms.isMockedForInternal) {
            return ms.mockedFacts[factHash];
        } else {
            return ms.facts[factHash] || ms.fallbackContract.isValid(factHash);
        }
    }

    /// @inheritdoc ICairoFactRegistryModule
    function isMockedForInternal() external view returns (bool) {
        return moduleStorage().isMockedForInternal;
    }

    /// @inheritdoc ICairoFactRegistryModule
    function setMockedForInternal(bool isMocked) external onlyOwner {
        moduleStorage().isMockedForInternal = isMocked;
    }
}
