// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

/// @notice Interface for the sender module that can send messages to any chain registered in Satellite Connection Registry
interface IUniversalSenderModule {
    /// @notice Send parent hash that was registered on our chain to the destination chain
    /// @param destinationChainId the chain ID of the destination chain
    /// @param accumulatedChainId the chain ID of the block that is being sent
    /// @param hashingFunction the hashing function used to hash the parent hash
    /// @param blockNumber the block number being sent
    /// @param _xDomainMsgGasData the gas data for the cross-domain message, depends on the destination chain
    function sendParentHash(
        uint256 destinationChainId,
        uint256 accumulatedChainId,
        bytes32 hashingFunction,
        uint256 blockNumber,
        bytes calldata _xDomainMsgGasData
    ) external payable;

    /// @notice Send MMR that was registered on our chain to the destination chain
    /// @param destinationChainId the chain ID of the destination chain
    /// @param accumulatedChainId the chain ID of the block that is being sent
    /// @param originalMmrId the ID of the original MMR
    /// @param newMmrId the ID of the new MMR
    /// @param hashingFunctions the hashing functions used to hash the MMR
    /// @param isOffchainGrownDestination if true, MMR will be sent as Offchain Grown
    /// @param _xDomainMsgGasData the gas data for the cross-domain message, depends on the destination chain
    function sendMmr(
        uint256 destinationChainId,
        uint256 accumulatedChainId,
        uint256 originalMmrId,
        uint256 newMmrId,
        bytes32[] calldata hashingFunctions,
        bool isOffchainGrownDestination,
        bytes calldata _xDomainMsgGasData
    ) external payable;
}
