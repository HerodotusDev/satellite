// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {LibSatellite} from "src/libraries/LibSatellite.sol";
import {ISatellite} from "src/interfaces/ISatellite.sol";
import {IReceiverModule} from "src/interfaces/modules/messaging/receiver/IReceiverModule.sol";
import {RootForHashingFunction} from "src/interfaces/modules/IMmrCoreModule.sol";

/// @notice Abstract contract for receiving messages from satellites deployed on other chains
/// @notice It checks whether the message is coming from correct address (including aliasing cross-domain counterpart)
abstract contract AbstractReceiverModule is IReceiverModule {
    function receiveParentHash(uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes32 parentHash) external onlyCrossdomainCounterpart {
        ISatellite(address(this))._receiveParentHash(chainId, hashingFunction, blockNumber, parentHash);
    }

    function receiveMmr(
        uint256 newMmrId,
        RootForHashingFunction[] calldata rootsForHashingFunctions,
        uint256 mmrSize,
        uint256 accumulatedChainId,
        uint256 originChainId,
        uint256 originalMmrId,
        bool isOffchainGrown
    ) external onlyCrossdomainCounterpart {
        ISatellite(address(this))._createMmrFromForeign(newMmrId, rootsForHashingFunctions, mmrSize, accumulatedChainId, originChainId, originalMmrId, isOffchainGrown);
    }

    modifier onlyCrossdomainCounterpart() {
        require(isCrossdomainCounterpart(), "Only crossdomain counterpart allowed");
        _;
    }

    function isCrossdomainCounterpart() internal view virtual returns (bool);
}
