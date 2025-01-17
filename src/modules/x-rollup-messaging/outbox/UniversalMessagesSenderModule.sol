// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {ISatellite} from "interfaces/ISatellite.sol";
import {ILibSatellite} from "interfaces/ILibSatellite.sol";
import {IUniversalMessagesSenderModule} from "interfaces/modules/x-rollup-messaging/outbox/IUniversalMessagesSenderModule.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";
import {RootForHashingFunction} from "interfaces/modules/IMmrCoreModule.sol";

contract UniversalMessagesSenderModule is IUniversalMessagesSenderModule {
    /// @notice Send parent hash that was registered on L1 to the destination chain
    /// @param destinationChainId the chain ID of the destination chain
    /// @param accumulatedChainId the chain ID of the block that is being sent
    /// @param hashingFunction the hashing function used to hash the parent hash
    /// @param blockNumber the number of block being sent
    /// @param _xDomainMsgGasData the gas data for the cross-domain message, depends on the destination L2
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

        ILibSatellite.SatelliteConnection memory satellite = s.SatelliteConnectionRegistry[destinationChainId];

        bytes memory data = abi.encodeWithSelector(
            satellite.sendMessageSelector,
            satellite.satelliteAddress,
            satellite.inboxAddress,
            abi.encodeWithSignature("receiveHashForBlock(uint256,bytes32,uint256,bytes32)", accumulatedChainId, hashingFunction, blockNumber, parentHash),
            _xDomainMsgGasData
        );

        (bool success, ) = address(this).call(data);
        require(success, "Function call failed");
    }

    function sendMmr(
        uint256 destinationChainId,
        uint256 accumulatedChainId,
        uint256 originalMmrId,
        uint256 newMmrId,
        bytes32[] calldata hashingFunctions,
        bytes calldata _xDomainMsgGasData
    ) external payable {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        require(hashingFunctions.length > 0, "hashingFunctions array cannot be empty");
        RootForHashingFunction[] memory rootsForHashingFunctions = new RootForHashingFunction[](hashingFunctions.length);

        uint256 mmrSize = s.mmrs[accumulatedChainId][originalMmrId][hashingFunctions[0]].latestSize;
        bytes32 root = s.mmrs[accumulatedChainId][originalMmrId][hashingFunctions[0]].mmrSizeToRoot[mmrSize];
        bool isSiblingSynced = s.mmrs[accumulatedChainId][originalMmrId][hashingFunctions[0]].isSiblingSynced;
        rootsForHashingFunctions[0] = RootForHashingFunction(root, hashingFunctions[0]);

        for (uint256 i = 1; i < hashingFunctions.length; i++) {
            uint256 _mmrSize = s.mmrs[accumulatedChainId][originalMmrId][hashingFunctions[i]].latestSize;
            bytes32 _root = s.mmrs[accumulatedChainId][originalMmrId][hashingFunctions[i]].mmrSizeToRoot[_mmrSize];
            bool _isSiblingSynced = s.mmrs[accumulatedChainId][originalMmrId][hashingFunctions[i]].isSiblingSynced;
            require(mmrSize == _mmrSize, "MMR size mismatch");
            require(isSiblingSynced == _isSiblingSynced, "MMR isSiblingSynced mismatch");
            rootsForHashingFunctions[i] = RootForHashingFunction(_root, hashingFunctions[i]);
        }

        ILibSatellite.SatelliteConnection memory satellite = s.SatelliteConnectionRegistry[destinationChainId];

        bytes memory data = abi.encodeWithSelector(
            satellite.sendMessageSelector,
            satellite.satelliteAddress,
            satellite.inboxAddress,
            abi.encodeWithSignature(
                "receiveMmr(uint256, (bytes32, bytes32)[], uint256, uint256, uint256, uint256, bool)",
                newMmrId,
                rootsForHashingFunctions,
                mmrSize,
                accumulatedChainId,
                block.chainid,
                originalMmrId,
                isSiblingSynced
            ),
            _xDomainMsgGasData
        );

        (bool success, ) = address(this).call(data);
        require(success, "Function call failed");
    }
}
