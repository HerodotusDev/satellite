// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {IArbitrumInbox} from "interfaces/external/IArbitrumInbox.sol";
import {ISatellite} from "interfaces/ISatellite.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";
import {AbstractMessagesSenderModule} from "./AbstractMessagesSenderModule.sol";
import {RootForHashingFunction} from "interfaces/modules/IMMRsCoreModule.sol";

contract L1ToArbitrumMessagesSenderModule is AbstractMessagesSenderModule {
    /// @notice Set the Arbitrum Inbox and Satellite addresses
    /// @param arbitrumInbox address of Arbitrum Inbox contract deployed on Sepolia
    /// @param arbitrumSatellite address of Satellite contract deployed on Arbitrum
    function configure(address arbitrumInbox, address arbitrumSatellite) external override {
        LibSatellite.enforceIsContractOwner();

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        require(s.arbitrumSatellite == address(0), "ARB_SAT_ALREADY_SET");
        s.arbitrumInbox = arbitrumInbox;
        s.arbitrumSatellite = arbitrumSatellite;
    }

    /// @notice Send parent hash that was registered on L1 to the Arbitrum
    /// @param chainId the chain ID of the block whose parent hash is being sent
    /// @param hashingFunction the hashing function used to hash the parent hash
    /// @param blockNumber the number of block being sent
    /// @param _xDomainMsgGasData the gas data for the cross-domain message, depends on the destination L2
    function sendParentHashL1ToArbitrum(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes calldata _xDomainMsgGasData) external {
        _sendParentHash(LibSatellite.satelliteStorage().arbitrumSatellite, chainId, hashingFunction, blockNumber, _xDomainMsgGasData);
    }

    function sendMmrL1ToArbitrum(uint256 accumulatedChainId, uint256 originalMmrId, uint256 newMmrId, bytes32[] calldata hashingFunctions, bytes calldata _xDomainMsgGasData) external {
        _sendMmr(LibSatellite.satelliteStorage().arbitrumSatellite, accumulatedChainId, originalMmrId, newMmrId, hashingFunctions, _xDomainMsgGasData);
    }

    function _sendMessage(address _l2Target, bytes memory _data, bytes memory _xDomainMsgGasData) internal override {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        (uint256 l2GasLimit, uint256 maxFeePerGas, uint256 maxSubmissionCost) = abi.decode(_xDomainMsgGasData, (uint256, uint256, uint256));
        IArbitrumInbox(s.arbitrumInbox).createRetryableTicket{value: msg.value}(_l2Target, 0, maxSubmissionCost, msg.sender, address(0), l2GasLimit, maxFeePerGas, _data);
    }
}
