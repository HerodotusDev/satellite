// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {IArbitrumInbox} from "interfaces/external/IArbitrumInbox.sol";
import {ISatellite} from "interfaces/ISatellite.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";
import {RootForHashingFunction} from "interfaces/modules/IMMRsCoreModule.sol";

abstract contract AbstractMessagesSenderModule {
    /// @notice Send parent hash that was registered on L1 to the destination chain
    /// @param satelliteAddress the address of the satellite contract on the destination chain
    /// @param chainId the chain ID of the block whose parent hash is being sent
    /// @param hashingFunction the hashing function used to hash the parent hash
    /// @param blockNumber the number of block being sent
    /// @param _xDomainMsgGasData the gas data for the cross-domain message, depends on the destination L2
    function _sendParentHash(address satelliteAddress, uint256 chainId, bytes32 hashingFunction, uint256 blockNumber, bytes calldata _xDomainMsgGasData) internal {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        bytes32 parentHash = s.receivedParentHashes[chainId][hashingFunction][blockNumber];

        require(parentHash != bytes32(0), "ERR_BLOCK_NOT_REGISTERED");

        _sendMessage(
            satelliteAddress,
            abi.encodeWithSignature("receiveHashForBlock(uint256,bytes32,uint256,bytes32)", chainId, hashingFunction, blockNumber, parentHash),
            _xDomainMsgGasData
        );
    }

    function _sendMmr(address satelliteAddress, uint256 accumulatedChainId, uint256 originalMmrId, uint256 newMmrId, bytes32[] calldata hashingFunctions, bytes calldata _xDomainMsgGasData) internal {
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
        _sendMessage(satelliteAddress, abi.encodeWithSignature("receiveMMR(uint256, (bytes32, bytes32)[], uint256, uint256, uint256, uint256, bool)", newMmrId, rootsForHashingFunctions, mmrSize, accumulatedChainId, block.chainid, originalMmrId, isSiblingSynced), _xDomainMsgGasData);
    }

    function _sendMessage(address _l2Target, bytes memory _data, bytes memory _xDomainMsgGasData) internal virtual;
}
