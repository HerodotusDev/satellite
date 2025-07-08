// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {ICairoFactRegistryModule} from "../interfaces/modules/ICairoFactRegistryModule.sol";
import {IFactsRegistry} from "../interfaces/external/IFactsRegistry.sol";
import {AccessController} from "../libraries/AccessController.sol";

struct CairoFactRegistryModuleStorage {
    // It is stored here so that it can be storage proven between satellites.
    mapping(bytes32 => bool) facts;
    mapping(bytes32 => bool) mockedFacts;
    IFactsRegistry externalFactRegistry;
    bool isMockedForInternal;
    IFactsRegistry fallbackMockedContract;
}

contract CairoFactRegistryModule is ICairoFactRegistryModule, AccessController {
    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.satellite.module.storage.cairo-fact-registry-module");

    event CairoFactSet(bytes32 factHash);
    event CairoFactRegistryExternalContractSet(address externalFactRegistry);
    event CairoMockedFactSet(bytes32 factHash);
    event CairoMockedFactRegistryFallbackContractSet(address fallbackMockedContract);
    event IsMockedForInternalSet(bool isMocked);

    function moduleStorage() internal pure returns (CairoFactRegistryModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // ========= Fact registry with real verification ========= //

    /// @inheritdoc ICairoFactRegistryModule
    function isCairoFactValid(bytes32 factHash) public view returns (bool) {
        CairoFactRegistryModuleStorage storage ms = moduleStorage();
        return ms.facts[factHash] || ms.externalFactRegistry.isValid(factHash);
    }

    /// @inheritdoc ICairoFactRegistryModule
    function isCairoFactStored(bytes32 factHash) external view returns (bool) {
        return moduleStorage().facts[factHash];
    }

    /// @inheritdoc ICairoFactRegistryModule
    function getCairoFactRegistryExternalContract() external view returns (address) {
        return address(moduleStorage().externalFactRegistry);
    }

    /// @inheritdoc ICairoFactRegistryModule
    function setCairoFactRegistryExternalContract(address externalFactRegistry) external onlyOwner {
        moduleStorage().externalFactRegistry = IFactsRegistry(externalFactRegistry);
        emit CairoFactRegistryExternalContractSet(externalFactRegistry);
    }

    /// @inheritdoc ICairoFactRegistryModule
    function storeCairoFact(bytes32 factHash) external {
        CairoFactRegistryModuleStorage storage ms = moduleStorage();
        require(ms.externalFactRegistry.isValid(factHash), "Fact hash not registered");
        ms.facts[factHash] = true;
        emit CairoFactSet(factHash);
    }

    // ========= Mocked fact registry ========= //

    /// @inheritdoc ICairoFactRegistryModule
    function isCairoMockedFactValid(bytes32 factHash) external view returns (bool) {
        CairoFactRegistryModuleStorage storage ms = moduleStorage();
        return ms.mockedFacts[factHash] || address(ms.fallbackMockedContract) != address(0) && ms.fallbackMockedContract.isValid(factHash);
    }

    /// @inheritdoc ICairoFactRegistryModule
    function setCairoMockedFact(bytes32 factHash) external onlyAdmin {
        CairoFactRegistryModuleStorage storage ms = moduleStorage();
        ms.mockedFacts[factHash] = true;
        if (address(ms.fallbackMockedContract) != address(0)) {
            ms.fallbackMockedContract.setValid(factHash);
        }
        emit CairoMockedFactSet(factHash);
    }

    /// @inheritdoc ICairoFactRegistryModule
    function getCairoMockedFactRegistryFallbackContract() external view returns (address) {
        return address(moduleStorage().fallbackMockedContract);
    }

    /// @inheritdoc ICairoFactRegistryModule
    function setCairoMockedFactRegistryFallbackContract(address fallbackMockedContract) external onlyOwner {
        moduleStorage().fallbackMockedContract = IFactsRegistry(fallbackMockedContract);
        emit CairoMockedFactRegistryFallbackContractSet(fallbackMockedContract);
    }

    // ========= For internal use in grower and data processor ========= //

    /// @inheritdoc ICairoFactRegistryModule
    function isCairoFactValidForInternal(bytes32 factHash) external view returns (bool) {
        CairoFactRegistryModuleStorage storage ms = moduleStorage();
        if (ms.isMockedForInternal) {
            return ms.mockedFacts[factHash];
        } else {
            return isCairoFactValid(factHash);
        }
    }

    /// @inheritdoc ICairoFactRegistryModule
    function isMockedForInternal() external view returns (bool) {
        return moduleStorage().isMockedForInternal;
    }

    /// @inheritdoc ICairoFactRegistryModule
    function setIsMockedForInternal(bool isMocked) external onlyOwner {
        moduleStorage().isMockedForInternal = isMocked;
        emit IsMockedForInternalSet(isMocked);
    }
}
