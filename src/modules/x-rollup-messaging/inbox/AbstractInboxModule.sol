// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {LibSatellite} from "libraries/LibSatellite.sol";
import {ISatellite} from "interfaces/ISatellite.sol";
import {IInboxModule} from "interfaces/modules/x-rollup-messaging/inbox/IInboxModule.sol";
import {RootForHashingFunction} from "interfaces/modules/IMmrCoreModule.sol";

abstract contract AbstractInboxModule is IInboxModule {
    function receiveHashForBlock(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes32 parentHash) external onlyCrossdomainCounterpart {
        ISatellite(address(this))._receiveBlockHash(chainId, hashingFunction, blockNumber, parentHash);

        // _receiveBlockHash(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes32 parentHash)
        // emit ReceivedHash(messagesOriginChainId, parentHash, blockNumber);
        // event is emitted in HeadersStore so this probably is not needed.
    }

    function receiveMmr(
        uint256 newMmrId,
        RootForHashingFunction[] calldata rootsForHashingFunctions,
        uint256 mmrSize,
        uint256 accumulatedChainId,
        uint256 originChainId,
        uint256 originalMmrId,
        bool isSiblingSynced,
        bool isTimestampRemapper,
        uint256 firstTimestampsBlock
    ) external onlyCrossdomainCounterpart {
        // headersStore.createBranchFromMessage(keccakMMRRoot, mmrSize, aggregatorId, newMmrId);
        ISatellite(address(this))._createMmrFromForeign(
            newMmrId,
            rootsForHashingFunctions,
            mmrSize,
            accumulatedChainId,
            originChainId,
            originalMmrId,
            isSiblingSynced,
            isTimestampRemapper,
            firstTimestampsBlock
        );
        // TODO: should we emit an event?
    }

    modifier onlyCrossdomainCounterpart() {
        require(isCrossdomainCounterpart(), "Only crossdomain counterpart allowed");
        _;
    }

    function isCrossdomainCounterpart() internal view virtual returns (bool);
}
