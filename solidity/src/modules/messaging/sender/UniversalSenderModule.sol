// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {ISatellite} from "src/interfaces/ISatellite.sol";
import {ILibSatellite} from "src/interfaces/ILibSatellite.sol";
import {IUniversalSenderModule} from "src/interfaces/modules/messaging/sender/IUniversalSenderModule.sol";
import {LibSatellite} from "src/libraries/LibSatellite.sol";
import {RootForHashingFunction} from "src/interfaces/modules/IMmrCoreModule.sol";

/// @notice Sender module that uses appropriate sender module depending on the destination chain
/// @dev It uses Satellite Connection Registry to find function selector for the destination chain
contract UniversalSenderModule is IUniversalSenderModule {
    /// @inheritdoc IUniversalSenderModule
    function sendParentHash(
        uint256 destinationChainId,
        uint256 accumulatedChainId,
        bytes32 hashingFunction,
        uint256 blockNumber,
        bytes calldata _xDomainMsgGasData
    ) external payable {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        bytes32 parentHash = s.receivedParentHashes[accumulatedChainId][hashingFunction][blockNumber];

        require(parentHash != bytes32(0), "ERR_BLOCK_NOT_REGISTERED");

        ILibSatellite.SatelliteConnection memory satellite = s.satelliteConnectionRegistry[destinationChainId];

        bytes memory data = abi.encodeWithSelector(
            satellite.sendMessageSelector,
            satellite.satelliteAddress,
            satellite.inboxAddress,
            abi.encodeWithSignature("receiveParentHash(uint256,bytes32,uint256,bytes32)", accumulatedChainId, hashingFunction, blockNumber, parentHash),
            _xDomainMsgGasData
        );

        (bool success, ) = address(this).call{value: msg.value}(data);
        require(success, "Function call failed");
    }

    /// @inheritdoc IUniversalSenderModule
    function sendMmr(
        uint256 destinationChainId,
        uint256 accumulatedChainId,
        uint256 originalMmrId,
        uint256 newMmrId,
        bytes32[] calldata hashingFunctions,
        bool isOffchainGrownDestination,
        bytes calldata _xDomainMsgGasData
    ) external payable {
        require(newMmrId != LibSatellite.EMPTY_MMR_ID, "NEW_MMR_ID_0_NOT_ALLOWED");
        require(hashingFunctions.length > 0, "INVALID_HASHING_FUNCTIONS_LENGTH");
        if (isOffchainGrownDestination == false) {
            // Onchain grown MMRs can have only one hashing function
            require(hashingFunctions.length == 1, "INVALID_HASHING_FUNCTIONS_LENGTH");
        }
        require(originalMmrId != LibSatellite.EMPTY_MMR_ID, "ORIGINAL_MMR_ID_0_NOT_ALLOWED");

        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        RootForHashingFunction[] memory rootsForHashingFunctions = new RootForHashingFunction[](hashingFunctions.length);

        uint256 commonMmrSize = s.mmrs[accumulatedChainId][originalMmrId][hashingFunctions[0]].latestSize;
        bool commonIsOffchainGrown = s.mmrs[accumulatedChainId][originalMmrId][hashingFunctions[0]].isOffchainGrown;

        for (uint256 i = 0; i < hashingFunctions.length; i++) {
            uint256 mmrSize = s.mmrs[accumulatedChainId][originalMmrId][hashingFunctions[i]].latestSize;
            bytes32 root = s.mmrs[accumulatedChainId][originalMmrId][hashingFunctions[i]].mmrSizeToRoot[mmrSize];
            bool isOffchainGrown = s.mmrs[accumulatedChainId][originalMmrId][hashingFunctions[i]].isOffchainGrown;

            // MMRs with all hashing functions must have the same size and isOffchainGrown value
            require(mmrSize == commonMmrSize, "MMR size mismatch");
            require(isOffchainGrown == commonIsOffchainGrown, "isOffchainGrown mismatch");

            rootsForHashingFunctions[i] = RootForHashingFunction(root, hashingFunctions[i]);
        }

        ILibSatellite.SatelliteConnection memory satellite = s.satelliteConnectionRegistry[destinationChainId];

        bytes memory data = abi.encodeWithSelector(
            satellite.sendMessageSelector,
            satellite.satelliteAddress,
            satellite.inboxAddress,
            abi.encodeWithSignature(
                "receiveMmr(uint256,(bytes32,bytes32)[],uint256,uint256,uint256,uint256,bool)",
                newMmrId,
                rootsForHashingFunctions,
                commonMmrSize,
                accumulatedChainId,
                block.chainid,
                originalMmrId,
                isOffchainGrownDestination
            ),
            _xDomainMsgGasData
        );

        (bool success, ) = address(this).call{value: msg.value}(data);
        require(success, "Function call failed");
    }
}
