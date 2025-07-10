// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {ICairoFactRegistryModule} from "../interfaces/modules/ICairoFactRegistryModule.sol";
import {IFactsRegistry} from "../interfaces/external/IFactsRegistry.sol";
import {AccessController} from "../libraries/AccessController.sol";
import {ISatellite} from "../interfaces/ISatellite.sol";

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

    function moduleStorage() internal pure returns (CairoFactRegistryModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
    // ========= Main function for end user ========= //

    /// @inheritdoc ICairoFactRegistryModule
    function isCairoFactValid(bytes32 factHash, bool isMocked) public view returns (bool) {
        if (isMocked) {
            return isCairoMockedFactValid(factHash);
        } else {
            return isCairoVerifiedFactValid(factHash);
        }
    }

    // ========= Fact registry with real verification ========= //

    /// @inheritdoc ICairoFactRegistryModule
    function isCairoVerifiedFactValid(bytes32 factHash) public view returns (bool) {
        CairoFactRegistryModuleStorage storage ms = moduleStorage();
        return ms.facts[factHash] || ms.externalFactRegistry.isValid(factHash);
    }

    /// @inheritdoc ICairoFactRegistryModule
    function isCairoVerifiedFactStored(bytes32 factHash) external view returns (bool) {
        return moduleStorage().facts[factHash];
    }

    /// @inheritdoc ICairoFactRegistryModule
    function getCairoVerifiedFactRegistryContract() external view returns (address) {
        return address(moduleStorage().externalFactRegistry);
    }

    /// @inheritdoc ICairoFactRegistryModule
    function setCairoVerifiedFactRegistryContract(address externalFactRegistry) external onlyOwner {
        moduleStorage().externalFactRegistry = IFactsRegistry(externalFactRegistry);
        emit CairoFactRegistryExternalContractSet(externalFactRegistry);
    }

    /// @inheritdoc ICairoFactRegistryModule
    function storeCairoVerifiedFact(bytes32 factHash) external {
        CairoFactRegistryModuleStorage storage ms = moduleStorage();
        require(ms.externalFactRegistry.isValid(factHash), "Fact hash not registered");
        ms.facts[factHash] = true;
        emit CairoFactSet(factHash);
    }

    // ========= Mocked fact registry ========= //

    /// @inheritdoc ICairoFactRegistryModule
    function isCairoMockedFactValid(bytes32 factHash) public view returns (bool) {
        CairoFactRegistryModuleStorage storage ms = moduleStorage();
        return ms.mockedFacts[factHash] || (address(ms.fallbackMockedContract) != address(0) && ms.fallbackMockedContract.isValid(factHash));
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
        return isCairoFactValid(factHash, isMockedForInternal());
    }

    /// @inheritdoc ICairoFactRegistryModule
    function isMockedForInternal() public view returns (bool) {
        return moduleStorage().isMockedForInternal;
    }

    /// @inheritdoc ICairoFactRegistryModule
    function setIsMockedForInternal(bool isMocked) external onlyOwner {
        moduleStorage().isMockedForInternal = isMocked;
        emit IsMockedForInternalSet(isMocked);
    }

    // ========= Moving facts ========= //

    function _saveCairoFact(bytes32 factHash, bool isMocked) internal {
        CairoFactRegistryModuleStorage storage ms = moduleStorage();
        if (isMocked) {
            ms.mockedFacts[factHash] = true;
            if (address(ms.fallbackMockedContract) != address(0)) {
                ms.fallbackMockedContract.setValid(factHash);
            }
        } else {
            ms.facts[factHash] = true;
            if (address(ms.externalFactRegistry) != address(0)) {
                ms.externalFactRegistry.setValid(factHash);
            }
        }
    }

    /// @inheritdoc ICairoFactRegistryModule
    function _receiveCairoFactHash(bytes32 factHash, bool isMocked) external onlyModule {
        _saveCairoFact(factHash, isMocked);
    }

    /// @inheritdoc ICairoFactRegistryModule
    function getStorageSlotForCairoFact(bytes32 factHash, bool isMocked) public pure returns (bytes32) {
        uint256 baseSlot = uint256(MODULE_STORAGE_POSITION) + (isMocked ? 1 : 0);
        return keccak256(abi.encode(factHash, baseSlot));
    }

    /// @inheritdoc ICairoFactRegistryModule
    function moveCairoFactFromStorageProof(uint256 originChainId, uint256 blockNumber, bytes32 factHash, bool isMocked) external {
        bytes32 slot = getStorageSlotForCairoFact(factHash, isMocked);

        ISatellite satellite = ISatellite(address(this));

        uint256 accountU256 = satellite.getSatellite(originChainId).satelliteAddress;
        require(accountU256 >> 160 == 0, "NON_EVM_SATELLITE");
        address account = address(uint160(accountU256));

        require(uint256(satellite.storageSlot(originChainId, blockNumber, account, slot)) == 1, "FACT_NOT_SAVED");

        _saveCairoFact(factHash, isMocked);
    }
}
