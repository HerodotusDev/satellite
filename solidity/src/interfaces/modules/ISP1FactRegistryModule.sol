// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface ISP1FactRegistryModule {
    event SP1FactRegistered(bytes32 indexed factHash, address indexed submitter);
    event VKeyUpdated(bytes32 indexed oldVKey, bytes32 indexed newVKey);
    event SP1VerifierUpdated(address indexed oldVerifier, address indexed newVerifier);

    /// @notice Verify an SP1 proof and register the committed fact hash.
    /// @dev Reverts if the SP1 verifier rejects the proof. Idempotent: re-submitting a proof
    ///      for an already-registered fact is a no-op (no state change, no event).
    function verifyAndRegisterSP1Fact(bytes calldata publicValues, bytes calldata proofBytes) external;

    /// @notice Whether given fact hash has been verified via SP1 or other means.
    /// @dev Delegates to isCairoFactValid(factHash, false).
    function isFactValid(bytes32 factHash) external view returns (bool);

    /// @notice Rotate the SP1 program verification key.
    function setProgramVKey(bytes32 newVKey) external;

    /// @notice Update the SP1 verifier contract address.
    function setSP1Verifier(address newVerifier) external;

    /// @notice Returns the current SP1 verifier contract address.
    function getSP1Verifier() external view returns (address);

    /// @notice Returns the current SP1 program verification key.
    function getProgramVKey() external view returns (bytes32);
}
