// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

// This module stores fact hashes for verified or mocked facts.

interface ICairoFactRegistryModule {
    event CairoFactSet(bytes32 factHash);
    event CairoFactRegistryExternalContractSet(address externalFactRegistry);
    event CairoMockedFactSet(bytes32 factHash);
    event CairoMockedFactRegistryFallbackContractSet(address fallbackMockedContract);
    event IsMockedForInternalSet(bool isMocked);

    // ========= Main function for end user ========= //

    /// Whether given fact is valid (mocked or verified).
    function isCairoFactValid(bytes32 factHash, bool isMocked) external view returns (bool);

    // ========= Fact registry with real verification ========= //

    /// Whether given fact was verified (not necessarily stored locally).
    function isCairoVerifiedFactValid(bytes32 factHash) external view returns (bool);

    /// Whether given fact hash was verified and stored locally.
    /// Verified facts can be moved if and only if this function returns true.
    function isCairoVerifiedFactStored(bytes32 factHash) external view returns (bool);

    /// Returns address of the contract that stores verified facts.
    function getCairoVerifiedFactRegistryContract() external view returns (address);

    /// Sets address of the contract that stores verified facts.
    function setCairoVerifiedFactRegistryContract(address contractAddress) external;

    /// Moves verified fact from external (fallback) contract to local storage.
    function storeCairoVerifiedFact(bytes32 factHash) external;

    // ========= Mocked fact registry ========= //

    /// Whether given fact was mocked.
    function isCairoMockedFactValid(bytes32 factHash) external view returns (bool);

    /// Mocks given fact. Caller must be an admin.
    function setCairoMockedFact(bytes32 factHash) external;

    /// Returns address of the contract that stores mocked facts.
    function getCairoMockedFactRegistryFallbackContract() external view returns (address);

    /// Sets address of the contract that stores mocked facts.
    function setCairoMockedFactRegistryFallbackContract(address fallbackMockedContract) external;

    // ========= For internal use in grower and data processor ========= //

    function isCairoFactValidForInternal(bytes32 factHash) external view returns (bool);

    function isMockedForInternal() external view returns (bool);

    function setIsMockedForInternal(bool isMocked) external;

    // ========= Moving facts ========= //

    function _receiveCairoFactHash(bytes32 factHash, bool isMocked) external;

    function getStorageSlotForCairoFact(bytes32 factHash, bool isMocked) external pure returns (bytes32);

    function moveCairoFactFromStorageProof(uint256 originChainId, uint256 blockNumber, bytes32 factHash, bool isMocked) external;
}
