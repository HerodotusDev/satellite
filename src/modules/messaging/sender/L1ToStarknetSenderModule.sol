// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {LibSatellite} from "src/libraries/LibSatellite.sol";
import {IStarknetCore} from "src/interfaces/external/IStarknetCore.sol";
import {IL1ToStarknetSenderModule} from "src/interfaces/modules/messaging/sender/IL1ToStarknetSenderModule.sol";
import {AccessController} from "src/libraries/AccessController.sol";
import {RootForHashingFunction} from "src/interfaces/modules/IMmrCoreModule.sol";
import {Uint256Splitter} from "src/libraries/internal/Uint256Splitter.sol";

contract L1ToStarknetSenderModule is IL1ToStarknetSenderModule, AccessController {
    using Uint256Splitter for uint256;

    bytes4 public constant RECEIVE_MMR_L1_SELECTOR = bytes4(keccak256("receiveMmr(uint256,(bytes32,bytes32)[],uint256,uint256,uint256,uint256,bool)"));
    bytes4 public constant RECEIVE_PARENT_HASH_L1_SELECTOR = bytes4(keccak256("receiveParentHash(uint256,bytes32,uint256,bytes32)"));
    uint256 public constant RECEIVE_MMR_L2_SELECTOR = 0x03b0888423d829a33dcfd4acf7bfe4d08132cdd35debb0e74af5f0f3a395d2e6;
    uint256 public constant RECEIVE_PARENT_HASH_L2_SELECTOR = 0x03e956c16ad6daeda6a681c48ddd8b98ae1b6b9d03e7618decfb89d1646b6911;

    /// @inheritdoc IL1ToStarknetSenderModule
    function sendMessageL1ToStarknet(uint256 satelliteAddress, address inboxAddress, bytes calldata _data, bytes memory) external payable onlyModule {
        bytes4 selector = bytes4(_data[:4]);
        bytes memory encodedParams = new bytes(_data.length - 4);
        for (uint i = 4; i < _data.length; i++) {
            encodedParams[i - 4] = _data[i];
        }

        uint256[] memory starknetData;
        uint256 l2Selector;
        if (selector == RECEIVE_MMR_L1_SELECTOR) (starknetData, l2Selector) = _receiveMmr(encodedParams);
        else if (selector == RECEIVE_PARENT_HASH_L1_SELECTOR) (starknetData, l2Selector) = _receiveParentHash(encodedParams);
        else revert("Invalid selector");

        IStarknetCore(inboxAddress).sendMessageToL2{value: msg.value}(satelliteAddress, l2Selector, starknetData);
    }

    function _receiveMmr(bytes memory encodedData) internal pure returns (uint256[] memory starknetData, uint256 l2Selector) {
        (
            uint256 newMmrId,
            RootForHashingFunction[] memory rootsForHashingFunctions,
            uint256 mmrSize,
            uint256 accumulatedChainId,
            uint256 originChainId,
            uint256 originalMmrId,
            bool isSiblingSynced
        ) = abi.decode(encodedData, (uint256, RootForHashingFunction[], uint256, uint256, uint256, uint256, bool));

        l2Selector = RECEIVE_MMR_L2_SELECTOR;

        // 5 * u256 = 10
        // 1 * bool = 1
        // array length = 1
        // n * (bytes32, bytes32) = n * 4
        uint256 pos = 0;
        starknetData = new uint256[](12 + rootsForHashingFunctions.length * 4);

        (uint256 newMmrIdLow, uint256 newMmrIdHigh) = newMmrId.split128();
        starknetData[pos++] = newMmrIdLow;
        starknetData[pos++] = newMmrIdHigh;

        starknetData[pos++] = rootsForHashingFunctions.length;

        for (uint256 i = 0; i < rootsForHashingFunctions.length; i++) {
            (uint256 rootLow, uint256 rootHigh) = uint256(rootsForHashingFunctions[i].root).split128();
            starknetData[pos++] = rootLow;
            starknetData[pos++] = rootHigh;

            (uint256 hashingFunctionLow, uint256 hashingFunctionHigh) = uint256(rootsForHashingFunctions[i].hashingFunction).split128();
            starknetData[pos++] = hashingFunctionLow;
            starknetData[pos++] = hashingFunctionHigh;
        }

        (uint256 mmrSizeLow, uint256 mmrSizeHigh) = mmrSize.split128();
        starknetData[pos++] = mmrSizeLow;
        starknetData[pos++] = mmrSizeHigh;

        (uint256 accumulatedChainIdLow, uint256 accumulatedChainIdHigh) = accumulatedChainId.split128();
        starknetData[pos++] = accumulatedChainIdLow;
        starknetData[pos++] = accumulatedChainIdHigh;

        (uint256 originChainIdLow, uint256 originChainIdHigh) = originChainId.split128();
        starknetData[pos++] = originChainIdLow;
        starknetData[pos++] = originChainIdHigh;

        (uint256 originalMmrIdLow, uint256 originalMmrIdHigh) = originalMmrId.split128();
        starknetData[pos++] = originalMmrIdLow;
        starknetData[pos++] = originalMmrIdHigh;

        starknetData[pos++] = isSiblingSynced ? 1 : 0;
    }

    function _receiveParentHash(bytes memory encodedData) internal pure returns (uint256[] memory starknetData, uint256 l2Selector) {
        (uint256 accumulatedChainId, bytes32 hashingFunction, uint256 blockNumber, bytes32 parentHash) = abi.decode(encodedData, (uint256, bytes32, uint256, bytes32));

        l2Selector = RECEIVE_PARENT_HASH_L2_SELECTOR;

        starknetData = new uint256[](8);

        (starknetData[0], starknetData[1]) = accumulatedChainId.split128();
        (starknetData[2], starknetData[3]) = uint256(hashingFunction).split128();
        (starknetData[4], starknetData[5]) = blockNumber.split128();
        (starknetData[6], starknetData[7]) = uint256(parentHash).split128();
    }
}
