// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {IArbitrumInbox} from "interfaces/external/IArbitrumInbox.sol";
import {ISatellite} from "interfaces/ISatellite.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";
import {AbstractMessagesSenderModule} from "./AbstractMessagesSenderModule.sol";
import {RootForHashingFunction} from "interfaces/modules/IMMRsCoreModule.sol";
import {IOptimismCrossDomainMessenger} from "interfaces/external/IOptimismCrossDomainMessenger.sol";
import {IL1ToOptimismMessagesSenderModule} from "interfaces/modules/x-rollup-messaging/outbox/IL1ToOptimismMessagesSenderModule.sol";

contract L1ToOptimismMessagesSenderModule is AbstractMessagesSenderModule, IL1ToOptimismMessagesSenderModule {
    function configureL1ToOptimism(address optimismMessenger, address optimismSatellite) external {
        LibSatellite.enforceIsContractOwner();

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        require(s.optimismSatellite == address(0), "OPTIMISM_SAT_ALREADY_SET");
        s.optimismMessenger = optimismMessenger;
        s.optimismSatellite = optimismSatellite;
    }

    /// @notice Send parent hash that was registered on L1 to the Arbitrum
    /// @param chainId the chain ID of the block whose parent hash is being sent
    /// @param hashingFunction the hashing function used to hash the parent hash
    /// @param blockNumber the number of block being sent
    /// @param _xDomainMsgGasData the gas data for the cross-domain message, depends on the destination L2
    function sendParentHashL1ToOptimism(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes calldata _xDomainMsgGasData) external override payable {
        _sendParentHash(LibSatellite.satelliteStorage().optimismSatellite, chainId, hashingFunction, blockNumber, _xDomainMsgGasData);
    }

    function sendMmrL1ToOptimism(uint256 accumulatedChainId, uint256 originalMmrId, uint256 newMmrId, bytes32[] calldata hashingFunctions, bytes calldata _xDomainMsgGasData) external override payable {
        _sendMmr(LibSatellite.satelliteStorage().optimismSatellite, accumulatedChainId, originalMmrId, newMmrId, hashingFunctions, _xDomainMsgGasData);
    }

    function _sendMessage(address _l2Target, bytes memory _data, bytes memory _xDomainMsgGasData) internal override {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        IOptimismCrossDomainMessenger optimismMessenger = IOptimismCrossDomainMessenger(s.optimismMessenger);

        uint32 l2GasLimit = abi.decode(_xDomainMsgGasData, (uint32));
        optimismMessenger.sendMessage(_l2Target, _data, l2GasLimit);
    }
}
