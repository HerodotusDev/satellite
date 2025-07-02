// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

// This module stores fact hashes for verified or mocked facts.

interface ICairoFactRegistryModule {
    /// Whether given fact was verified (not necessarily stored locally).
    function isCairoFactValid(bytes32 factHash) external view returns (bool);

    /// Whether given fact hash was verified and stored locally.
    /// Verified facts can be moved if and only if this function returns true.
    function isCairoFactStored(bytes32 factHash) external view returns (bool);

    /// Returns address of the contract that stores verified facts.
    function getCairoFactRegistryExternalContract() external view returns (address);

    /// Sets address of the contract that stores verified facts.
    function setCairoFactRegistryExternalContract(address fallbackContract) external;

    /// Moves verified fact from external (fallback) contract to local storage.
    function storeCairoFact(bytes32 factHash) external;

    /// Whether given fact was mocked.
    function isCairoMockedFactValid(bytes32 factHash) external view returns (bool);

    /// Mocks given fact. Caller must be an admin.
    function setCairoMockedFact(bytes32 factHash) external;

    // ========= For internal use in grower and data processor ========= //

    function isCairoFactValidForInternal(bytes32 factHash) external view returns (bool);

    function isMockedForInternal() external view returns (bool);

    function setMockedForInternal(bool isMocked) external;
}
