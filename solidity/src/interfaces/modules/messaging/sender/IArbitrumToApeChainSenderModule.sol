// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface IArbitrumToApeChainSenderModule {
    /// @notice Storage structure for the module
    struct ArbitrumToApeChainSenderModuleStorage {
        address apeChainTokenAddress;
    }

    /// @notice Set the address of the ApeChain token
    /// @param tokenAddress the address of the native token in https://docs.apechain.com/contracts/Testnet/contract-information#chaininfo
    function setApeChainTokenAddress(address tokenAddress) external;

    /// @notice Send message from Arbitrum to ApeChain
    /// @param satelliteAddress the address of the satellite on ApeChain
    /// @param inboxAddress the address of the ApeChain Inbox
    /// @dev inboxAddress - Inbox in https://docs.apechain.com/contracts/Testnet/contract-information#corecontracts
    function sendMessageArbitrumToApeChain(uint256 satelliteAddress, address inboxAddress, bytes memory _data, bytes memory _xDomainMsgGasData) external payable;
}
