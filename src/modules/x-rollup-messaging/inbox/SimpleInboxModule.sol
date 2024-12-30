// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {LibSatellite} from "libraries/LibSatellite.sol";
import {ISatellite} from "interfaces/ISatellite.sol";
import {ISimpleInboxModule} from "interfaces/modules/x-rollup-messaging/inbox/ISimpleInboxModule.sol";
import {RootForHashingFunction} from "interfaces/modules/IMMRsCoreModule.sol";

contract SimpleInboxModule is ISimpleInboxModule {
    // event ReceivedHash(uint256 originChainId, bytes32 blockhash, uint256 blockNumber);

    // address public crossDomainMsgSender;
    // HeadersStore public headersStore;
    // uint256 public messagesOriginChainId;

    // function setCrossDomainMsgSender(address _crossDomainMsgSender, bool value) external {
    //     LibSatellite.enforceIsContractOwner();
    //     ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();

    //     s.crossDomainMsgSenders[_crossDomainMsgSender] = value;
    // }

    // probably not needed, we can call HeadersStore directly
    // function setHeadersStore(address _headersStore) external onlyOwner {
    //     headersStore = HeadersStore(_headersStore);
    // }

    // function setMessagesOriginChainId(uint256 _messagesOriginChainId) external onlyOwner {
    //     messagesOriginChainId = _messagesOriginChainId;
    // }

    function receiveHashForBlock(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes32 parentHash) external onlyCrossdomainCounterpart {
        ISatellite(address(this))._receiveBlockHash(chainId, hashingFunction, blockNumber, parentHash);

        // _receiveBlockHash(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes32 parentHash)
        // emit ReceivedHash(messagesOriginChainId, parentHash, blockNumber);
        // event is emitted in HeadersStore so this probably is not needed.
    }

    function receiveMMR(
        uint256 newMmrId,
        RootForHashingFunction[] calldata rootsForHashingFunctions,
        uint256 mmrSize,
        uint256 accumulatedChainId,
        uint256 originChainId,
        uint256 originalMmrId,
        bool isSiblingSynced
    ) external onlyCrossdomainCounterpart {
        // headersStore.createBranchFromMessage(keccakMMRRoot, mmrSize, aggregatorId, newMmrId);
        ISatellite(address(this))._createMmrFromForeign(newMmrId, rootsForHashingFunctions, mmrSize, accumulatedChainId, originChainId, originalMmrId, isSiblingSynced);
        // TODO: should we emit an event?
    }

    modifier onlyCrossdomainCounterpart() {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        require(s.crossDomainMsgSenders[msg.sender], "Not authorized cross-domain message. Only cross-domain counterpart can call this function.");
        _;
    }
}
