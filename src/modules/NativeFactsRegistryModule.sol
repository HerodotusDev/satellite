// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {StatelessMmr} from "@solidity-mmr/lib/StatelessMmr.sol";
import {Lib_SecureMerkleTrie as SecureMerkleTrie} from "@optimism/libraries/trie/Lib_SecureMerkleTrie.sol";
import {Lib_RLPReader as RLPReader} from "@optimism/libraries/rlp/Lib_RLPReader.sol";

import {Bitmap16} from "libraries/internal/Bitmap16.sol";
import {NullableStorageSlot} from "libraries/internal/NullableStorageSlot.sol";
import {INativeFactsRegistryModule} from "interfaces/modules/INativeFactsRegistryModule.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";
import {ISatellite} from "interfaces/ISatellite.sol";

contract NativeFactsRegistryModule is INativeFactsRegistryModule {
    using Bitmap16 for uint16;

    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    uint8 private constant ACCOUNT_NONCE_INDEX = 0;
    uint8 private constant ACCOUNT_BALANCE_INDEX = 1;
    uint8 private constant ACCOUNT_STORAGE_ROOT_INDEX = 2;
    uint8 private constant ACCOUNT_CODE_HASH_INDEX = 3;

    bytes32 private constant EMPTY_TRIE_ROOT_HASH = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;
    bytes32 private constant EMPTY_CODE_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");
    uint256 public immutable CHAIN_ID = block.chainid;

    mapping(address => mapping(uint256 => mapping(AccountFields => bytes32))) internal _accountField;
    // address => block number => slot => value
    mapping(address => mapping(uint256 => mapping(bytes32 => bytes32))) internal _accountStorageSlotValues;

    function proveNativeAccount(address account, uint16 accountFieldsToSave, BlockHeaderProof calldata headerProof, bytes calldata accountTrieProof) external {
        // Verify the proof and decode the account fields
        (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot) = verifyNativeAccount(account, headerProof, accountTrieProof);

        // Save the desired account properties to the storage
        if (accountFieldsToSave.readBitAtIndexFromRight(0)) {
            uint256 nonceNullable = NullableStorageSlot.toNullable(nonce);
            _accountField[account][headerProof.blockNumber][AccountFields.NONCE] = bytes32(nonceNullable);
        }

        if (accountFieldsToSave.readBitAtIndexFromRight(1)) {
            uint256 accountBalanceNullable = NullableStorageSlot.toNullable(accountBalance);
            _accountField[account][headerProof.blockNumber][AccountFields.BALANCE] = bytes32(accountBalanceNullable);
        }

        if (accountFieldsToSave.readBitAtIndexFromRight(2)) {
            uint256 codeHashNullable = NullableStorageSlot.toNullable(uint256(codeHash));
            _accountField[account][headerProof.blockNumber][AccountFields.CODE_HASH] = bytes32(codeHashNullable);
        }

        if (accountFieldsToSave.readBitAtIndexFromRight(3)) {
            uint256 storageRootNullable = NullableStorageSlot.toNullable(uint256(storageRoot));
            _accountField[account][headerProof.blockNumber][AccountFields.STORAGE_ROOT] = bytes32(storageRootNullable);
        }

        emit NativeAccountProven(account, headerProof.blockNumber, nonce, accountBalance, codeHash, storageRoot);
    }

    function proveNativeStorage(address account, uint256 blockNumber, bytes32 slot, bytes calldata storageSlotTrieProof) external {
        // Verify the proof and decode the slot value
        uint256 slotValueNullable = NullableStorageSlot.toNullable(uint256(verifyNativeStorage(account, blockNumber, slot, storageSlotTrieProof)));
        _accountStorageSlotValues[account][blockNumber][slot] = bytes32(slotValueNullable);
        emit NativeStorageSlotProven(account, blockNumber, slot, bytes32(NullableStorageSlot.fromNullable(slotValueNullable)));
    }

    function verifyNativeAccount(
        address account,
        BlockHeaderProof calldata headerProof,
        bytes calldata accountTrieProof
    ) public view returns (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot) {
        // Ensure provided header is a valid one by making sure it is committed in the HeadersStore MMR
        _verifyAccumulatedHeaderProof(headerProof);

        // Verify the account state proof
        bytes32 stateRoot = _getStateRoot(headerProof.provenBlockHeader);

        (bool doesAccountExist, bytes memory accountRLP) = SecureMerkleTrie.get(abi.encodePacked(account), accountTrieProof, stateRoot);
        // Decode the account fields
        (nonce, accountBalance, storageRoot, codeHash) = _decodeAccountFields(doesAccountExist, accountRLP);
    }

    function verifyNativeStorage(address account, uint256 blockNumber, bytes32 slot, bytes calldata storageSlotTrieProof) public view returns (bytes32 slotValue) {
        bytes32 storageRootRaw = _accountField[account][blockNumber][AccountFields.STORAGE_ROOT];
        // Convert from nullable
        bytes32 storageRoot = bytes32(NullableStorageSlot.fromNullable(uint256(storageRootRaw)));

        (, bytes memory slotValueRLP) = SecureMerkleTrie.get(abi.encode(slot), storageSlotTrieProof, storageRoot);

        slotValue = slotValueRLP.toRLPItem().readBytes32();
    }

    function nativeAccountField(address account, uint256 blockNumber, AccountFields field) external view returns (bytes32) {
        bytes32 valueRaw = _accountField[account][blockNumber][field];
        // If value is null revert
        if (NullableStorageSlot.isNull(uint256(valueRaw))) {
            revert("ERR_VALUE_IS_NULL");
        }
        return bytes32(NullableStorageSlot.fromNullable(uint256(valueRaw)));
    }

    function nativeAccountStorageSlotValues(address account, uint256 blockNumber, bytes32 slot) external view returns (bytes32) {
        bytes32 valueRaw = _accountStorageSlotValues[account][blockNumber][slot];
        // If value is null revert
        if (NullableStorageSlot.isNull(uint256(valueRaw))) {
            revert("ERR_VALUE_IS_NULL");
        }
        return bytes32(NullableStorageSlot.fromNullable(uint256(valueRaw)));
    }

    function _verifyAccumulatedHeaderProof(BlockHeaderProof memory proof) internal view {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        bytes32 mmrRoot = s.mmrs[CHAIN_ID][proof.treeId][KECCAK_HASHING_FUNCTION].mmrSizeToRoot[proof.mmrTreeSize];
        require(mmrRoot != bytes32(0), "ERR_EMPTY_MMR_ROOT");

        bytes32 blockHeaderHash = keccak256(proof.provenBlockHeader);

        StatelessMmr.verifyProof(proof.blockProofLeafIndex, blockHeaderHash, proof.mmrElementInclusionProof, proof.mmrPeaks, proof.mmrTreeSize, mmrRoot);

        uint256 actualBlockNumber = _decodeBlockNumber(proof.provenBlockHeader);
        require(actualBlockNumber == proof.blockNumber, "ERR_INVALID_BLOCK_NUMBER");
    }

    function _decodeAccountFields(bool doesAccountExist, bytes memory accountRLP) internal pure returns (uint256 nonce, uint256 balance, bytes32 storageRoot, bytes32 codeHash) {
        if (!doesAccountExist) {
            return (0, 0, EMPTY_TRIE_ROOT_HASH, EMPTY_CODE_HASH);
        }

        RLPReader.RLPItem[] memory accountFields = accountRLP.toRLPItem().readList();

        nonce = accountFields[ACCOUNT_NONCE_INDEX].readUint256();
        balance = accountFields[ACCOUNT_BALANCE_INDEX].readUint256();
        codeHash = accountFields[ACCOUNT_CODE_HASH_INDEX].readBytes32();
        storageRoot = accountFields[ACCOUNT_STORAGE_ROOT_INDEX].readBytes32();
    }

    function _getStateRoot(bytes memory headerRlp) internal pure returns (bytes32) {
        return RLPReader.toRLPItem(headerRlp).readList()[3].readBytes32();
    }

    function _decodeBlockNumber(bytes memory headerRlp) internal pure returns (uint256) {
        return RLPReader.toRLPItem(headerRlp).readList()[8].readUint256();
    }
}
