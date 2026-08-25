// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface ISP1FactRegistryModule {
    event SP1FactRegistered(bytes32 indexed factHash, address indexed submitter);
    event VKeyUpdated(bytes32 indexed oldVKey, bytes32 indexed newVKey);
    event SP1VerifierUpdated(address indexed oldVerifier, address indexed newVerifier);

    /// @notice Verify an SP1 proof and register the committed fact hash.
    /// @dev Reverts if the SP1 verifier rejects the proof. Re-submitting re-emits SP1FactRegistered;
    ///      fact storage is a no-op if the hash is already registered.
    function verifyAndRegisterSP1Fact(bytes calldata publicValues, bytes calldata proofBytes) external;

    /// @notice Rotate the SP1 program verification key.
    function setProgramVKey(bytes32 newVKey) external;

    /// @notice Update the SP1 verifier contract address.
    function setSP1Verifier(address newVerifier) external;

    /// @notice Returns the current SP1 verifier contract address.
    function getSP1Verifier() external view returns (address);

    /// @notice Returns the current SP1 program verification key.
    function getProgramVKey() external view returns (bytes32);
}
