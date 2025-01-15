// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {StatelessMmr} from "@solidity-mmr/lib/StatelessMmr.sol";
import {Lib_SecureMerkleTrie as SecureMerkleTrie} from "libraries/external/optimism/trie/Lib_SecureMerkleTrie.sol";
import {Lib_RLPReader as RLPReader} from "libraries/external/optimism/rlp/Lib_RLPReader.sol";
import {IEVMFactRegistryModule} from "interfaces/modules/IEVMFactRegistryModule.sol";
import {LibSatellite} from "libraries/LibSatellite.sol";
import {ISatellite} from "interfaces/ISatellite.sol";

contract EVMFactRegistryModule is IEVMFactRegistryModule {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    uint8 private constant ACCOUNT_NONCE_INDEX = 0;
    uint8 private constant ACCOUNT_BALANCE_INDEX = 1;
    uint8 private constant ACCOUNT_STORAGE_ROOT_INDEX = 2;
    uint8 private constant ACCOUNT_CODE_HASH_INDEX = 3;

    bytes32 private constant EMPTY_TRIE_ROOT_HASH = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;
    bytes32 private constant EMPTY_CODE_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");

    // chain_id => address => block_number => Account
    mapping(uint256 => mapping(address => mapping(uint256 => Account))) internal _accountField;
    // chain_id => address => block number => slot => value
    mapping(uint256 => mapping(address => mapping(uint256 => mapping(bytes32 => StorageSlot)))) internal _accountStorageSlotValues;

    // ===================== Functions for end user ===================== //

    function accountField(uint256 chainId, address account, uint256 blockNumber, AccountFields field) external view returns (bytes32) {
        Account storage accountData = _accountField[chainId][account][blockNumber];
        require(readBitAtIndexFromRight(accountData.savedFields, uint8(field)), "ERR_FIELD_NOT_SAVED");
        return accountData.fields[field];
    }

    function storageSlot(uint256 chainId, address account, uint256 blockNumber, bytes32 slot) external view returns (bytes32) {
        StorageSlot storage valueRaw = _accountStorageSlotValues[chainId][account][blockNumber][slot];
        require(valueRaw.exists, "ERR_SLOT_NOT_SAVED");
        return bytes32(valueRaw.value);
    }

    // ========================= Core Functions ========================= //

    function proveAccount(uint256 chainId, address account, uint8 accountFieldsToSave, BlockHeaderProof calldata headerProof, bytes calldata accountTrieProof) external {
        // Verify the proof and decode the account fields
        (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot) = verifyAccount(chainId, account, headerProof, accountTrieProof);

        // Save the desired account properties to the storage
        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountFields.NONCE))) {
            _accountField[chainId][account][headerProof.blockNumber].savedFields |= uint8(1 << uint8(AccountFields.NONCE));
            _accountField[chainId][account][headerProof.blockNumber].fields[AccountFields.NONCE] = bytes32(nonce);
        }

        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountFields.BALANCE))) {
            _accountField[chainId][account][headerProof.blockNumber].savedFields |= uint8(1 << uint8(AccountFields.BALANCE));
            _accountField[chainId][account][headerProof.blockNumber].fields[AccountFields.BALANCE] = bytes32(accountBalance);
        }

        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountFields.CODE_HASH))) {
            _accountField[chainId][account][headerProof.blockNumber].savedFields |= uint8(1 << uint8(AccountFields.CODE_HASH));
            _accountField[chainId][account][headerProof.blockNumber].fields[AccountFields.CODE_HASH] = codeHash;
        }

        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountFields.STORAGE_ROOT))) {
            _accountField[chainId][account][headerProof.blockNumber].savedFields |= uint8(1 << uint8(AccountFields.STORAGE_ROOT));
            _accountField[chainId][account][headerProof.blockNumber].fields[AccountFields.STORAGE_ROOT] = storageRoot;
        }

        emit ProvenAccount(chainId, account, headerProof.blockNumber, nonce, accountBalance, codeHash, storageRoot);
    }

    function proveStorage(uint256 chainId, address account, uint256 blockNumber, bytes32 slot, bytes calldata storageSlotTrieProof) external {
        // Verify the proof and decode the slot value
        bytes32 slotValue = verifyStorage(chainId, account, blockNumber, slot, storageSlotTrieProof);
        _accountStorageSlotValues[chainId][account][blockNumber][slot] = StorageSlot(slotValue, true);

        emit ProvenStorage(chainId, account, blockNumber, slot, slotValue);
    }

    // ========================= View functions ========================= //

    function verifyAccount(
        uint256 chainId,
        address account,
        BlockHeaderProof calldata headerProof,
        bytes calldata accountTrieProof
    ) public view returns (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot) {
        // Ensure provided header is a valid one by making sure it is present in saved MMRs
        _verifyAccumulatedHeaderProof(chainId, headerProof);

        // Verify the account state proof
        bytes32 stateRoot = _getStateRoot(headerProof.provenBlockHeader);

        (bool doesAccountExist, bytes memory accountRLP) = SecureMerkleTrie.get(abi.encodePacked(account), accountTrieProof, stateRoot);
        // Decode the account fields
        (nonce, accountBalance, storageRoot, codeHash) = _decodeAccountFields(doesAccountExist, accountRLP);
    }

    function verifyStorage(
        uint256 chainId,
        address account,
        uint256 blockNumber,
        bytes32 slot,
        bytes calldata storageSlotTrieProof
    ) public view returns (bytes32 slotValue) {
        Account storage accountData = _accountField[chainId][account][blockNumber];
        require(readBitAtIndexFromRight(accountData.savedFields, uint8(AccountFields.STORAGE_ROOT)), "ERR_STORAGE_ROOT_NOT_SAVED");

        bytes32 storageRoot = accountData.fields[AccountFields.STORAGE_ROOT];

        (, bytes memory slotValueRLP) = SecureMerkleTrie.get(abi.encode(slot), storageSlotTrieProof, storageRoot);

        slotValue = slotValueRLP.toRLPItem().readBytes32();
    }

    /// ========================= Internal functions ========================= //

    function _verifyAccumulatedHeaderProof(uint256 chainId, BlockHeaderProof memory proof) internal view {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        bytes32 mmrRoot = s.mmrs[chainId][proof.treeId][KECCAK_HASHING_FUNCTION].mmrSizeToRoot[proof.mmrTreeSize];
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

    function readBitAtIndexFromRight(uint8 bitmap, uint8 index) internal pure returns (bool value) {
        require(index < 8, "ERR_OUR_OF_RANGE");
        return (bitmap & (1 << index)) != 0;
    }
}
