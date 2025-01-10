// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {IArbitrumInbox} from "interfaces/external/IArbitrumInbox.sol";
import {ISatellite} from "interfaces/ISatellite.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";
import {AbstractMessagesSenderModule} from "./AbstractMessagesSenderModule.sol";
import {RootForHashingFunction} from "interfaces/modules/IMmrCoreModule.sol";
import {IZkSyncMailbox} from "interfaces/external/IZkSyncMailbox.sol";
import {IL1ToZkSyncMessagesSenderModule} from "interfaces/modules/x-rollup-messaging/outbox/IL1ToZkSyncMessagesSenderModule.sol";

contract L1ToZkSyncMessagesSenderModule is AbstractMessagesSenderModule, IL1ToZkSyncMessagesSenderModule {
    function configureL1ToZkSync(address zkSyncMailbox, address zkSyncSatellite) external {
        LibSatellite.enforceIsContractOwner();

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        require(s.zkSyncSatellite == address(0), "ZKSYNC_SAT_ALREADY_SET");
        s.zkSyncMailbox = zkSyncMailbox;
        s.zkSyncSatellite = zkSyncSatellite;
    }

    /// @notice Send parent hash that was registered on L1 to ZkSync
    /// @param chainId the chain ID of the block whose parent hash is being sent
    /// @param hashingFunction the hashing function used to hash the parent hash
    /// @param blockNumber the number of block being sent
    /// @param _xDomainMsgGasData the gas data for the cross-domain message, depends on the destination L2
    function sendParentHashL1ToZkSync(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes calldata _xDomainMsgGasData) external override payable {
        _sendParentHash(LibSatellite.satelliteStorage().zkSyncSatellite, chainId, hashingFunction, blockNumber, _xDomainMsgGasData);
    }

    function sendMmrL1ToZkSync(uint256 accumulatedChainId, uint256 originalMmrId, uint256 newMmrId, bytes32[] calldata hashingFunctions, bytes calldata _xDomainMsgGasData) external override payable {
        _sendMmr(LibSatellite.satelliteStorage().zkSyncSatellite, accumulatedChainId, originalMmrId, newMmrId, hashingFunctions, _xDomainMsgGasData);
    }

    function _sendMessage(address _l2Target, bytes memory _data, bytes memory _xDomainMsgGasData) internal override {
        IZkSyncMailbox zkSyncMailbox = IZkSyncMailbox(LibSatellite.satelliteStorage().zkSyncMailbox);
        (uint256 l2GasLimit, uint256 l2GasPerPubdataByteLimit) = abi.decode(_xDomainMsgGasData, (uint256, uint256));
        zkSyncMailbox.requestL2Transaction{value: msg.value}(_l2Target, 0, _data, l2GasLimit, l2GasPerPubdataByteLimit, new bytes[](0), msg.sender);
    }
}
