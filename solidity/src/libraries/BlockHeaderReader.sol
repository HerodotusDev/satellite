// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import {Lib_RLPReader as RLPReader} from "./external/optimism/rlp/Lib_RLPReader.sol";
import {IEvmFactRegistryModule} from "../interfaces/modules/IEvmFactRegistryModule.sol";

abstract contract BlockHeaderReader {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    uint8 internal constant BLOCK_HEADER_FIELD_COUNT = 15;

    function _readBlockHeaderFields(bytes memory headerRlp) internal pure returns (bytes32[BLOCK_HEADER_FIELD_COUNT] memory fields) {
        RLPReader.RLPItem[] memory headerFields = RLPReader.toRLPItem(headerRlp).readList();
        for (uint8 i = 0; i < BLOCK_HEADER_FIELD_COUNT; i++) {
            // Logs bloom is longer than 32 bytes, so it's not supported
            if (i == uint8(IEvmFactRegistryModule.BlockHeaderField.LOGS_BLOOM)) continue;
            fields[i] = headerFields[i].readBytes32();
        }
    }
}
