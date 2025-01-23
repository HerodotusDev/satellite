// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {StatelessMmr} from "@solidity-mmr/lib/StatelessMmr.sol";
import {Lib_SecureMerkleTrie as SecureMerkleTrie} from "src/libraries/external/optimism/trie/Lib_SecureMerkleTrie.sol";
import {Lib_RLPReader as RLPReader} from "src/libraries/external/optimism/rlp/Lib_RLPReader.sol";
import {IEVMFactRegistryModule} from "src/interfaces/modules/IEVMFactRegistryModule.sol";
import {LibSatellite} from "src/libraries/LibSatellite.sol";
import {ISatellite} from "src/interfaces/ISatellite.sol";

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

    // ========================= Satellite Module Storage ========================= //

    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.satellite.module.storage.evm-fact-registry");

    function moduleStorage() internal pure returns (EVMFactRegistryModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // ===================== Functions for End Users ===================== //

    /// @inheritdoc IEVMFactRegistryModule
    function accountField(uint256 chainId, address account, uint256 blockNumber, AccountField field) external view returns (bytes32) {
        EVMFactRegistryModuleStorage storage ms = moduleStorage();

        Account storage accountData = ms.accountField[chainId][account][blockNumber];
        require(readBitAtIndexFromRight(accountData.savedFields, uint8(field)), "ERR_FIELD_NOT_SAVED");
        return accountData.fields[field];
    }

    /// @inheritdoc IEVMFactRegistryModule
    function storageSlot(uint256 chainId, address account, uint256 blockNumber, bytes32 slot) external view returns (bytes32) {
        EVMFactRegistryModuleStorage storage ms = moduleStorage();

        StorageSlot storage valueRaw = ms.accountStorageSlotValues[chainId][account][blockNumber][slot];
        require(valueRaw.exists, "ERR_SLOT_NOT_SAVED");
        return bytes32(valueRaw.value);
    }

    /// @inheritdoc IEVMFactRegistryModule
    function timestamp(uint256 chainId, uint256 timestamp_) external view returns (uint256) {
        EVMFactRegistryModuleStorage storage ms = moduleStorage();

        // block number stored is blockNumber + 1 and 0 means no data
        uint256 blockNumberStored = ms.timestampToBlockNumber[chainId][timestamp_];
        require(blockNumberStored != 0, "ERR_NO_BLOCK_STORED_FOR_TIMESTAMP");
        return blockNumberStored - 1;
    }

    // ========================= Core Functions ========================= //

    /// @inheritdoc IEVMFactRegistryModule
    function proveAccount(uint256 chainId, address account, uint8 accountFieldsToSave, BlockHeaderProof calldata headerProof, bytes calldata accountTrieProof) external {
        EVMFactRegistryModuleStorage storage ms = moduleStorage();

        // Verify the proof and decode the account fields
        (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot) = verifyAccount(chainId, account, headerProof, accountTrieProof);

        // Save the desired account properties to the storage
        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountField.NONCE))) {
            ms.accountField[chainId][account][headerProof.blockNumber].savedFields |= uint8(1 << uint8(AccountField.NONCE));
            ms.accountField[chainId][account][headerProof.blockNumber].fields[AccountField.NONCE] = bytes32(nonce);
        }

        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountField.BALANCE))) {
            ms.accountField[chainId][account][headerProof.blockNumber].savedFields |= uint8(1 << uint8(AccountField.BALANCE));
            ms.accountField[chainId][account][headerProof.blockNumber].fields[AccountField.BALANCE] = bytes32(accountBalance);
        }

        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountField.CODE_HASH))) {
            ms.accountField[chainId][account][headerProof.blockNumber].savedFields |= uint8(1 << uint8(AccountField.CODE_HASH));
            ms.accountField[chainId][account][headerProof.blockNumber].fields[AccountField.CODE_HASH] = codeHash;
        }

        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountField.STORAGE_ROOT))) {
            ms.accountField[chainId][account][headerProof.blockNumber].savedFields |= uint8(1 << uint8(AccountField.STORAGE_ROOT));
            ms.accountField[chainId][account][headerProof.blockNumber].fields[AccountField.STORAGE_ROOT] = storageRoot;
        }

        emit ProvenAccount(chainId, account, headerProof.blockNumber, nonce, accountBalance, codeHash, storageRoot);
    }

    /// @inheritdoc IEVMFactRegistryModule
    function proveStorage(uint256 chainId, address account, uint256 blockNumber, bytes32 slot, bytes calldata storageSlotTrieProof) external {
        EVMFactRegistryModuleStorage storage ms = moduleStorage();

        // Verify the proof and decode the slot value
        bytes32 slotValue = verifyStorage(chainId, account, blockNumber, slot, storageSlotTrieProof);
        ms.accountStorageSlotValues[chainId][account][blockNumber][slot] = StorageSlot(slotValue, true);

        emit ProvenStorage(chainId, account, blockNumber, slot, slotValue);
    }

    /// @inheritdoc IEVMFactRegistryModule
    function proveTimestamp(uint256 chainId, uint256 timestamp_, BlockHeaderProof calldata headerProof, BlockHeaderProof calldata headerProofNext) external {
        EVMFactRegistryModuleStorage storage ms = moduleStorage();

        uint256 blockNumber = verifyTimestamp(chainId, timestamp_, headerProof, headerProofNext);
        // blockNumber + 1 is stored, so uint256.max cannot be stored
        require(blockNumber != type(uint256).max, "ERR_BLOCK_NUMBER_TOO_HIGH");
        ms.timestampToBlockNumber[chainId][timestamp_] = blockNumber + 1;

        emit ProvenTimestamp(chainId, timestamp_, blockNumber);
    }

    // ========================= View functions ========================= //

    /// @inheritdoc IEVMFactRegistryModule
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

    /// @inheritdoc IEVMFactRegistryModule
    function verifyStorage(uint256 chainId, address account, uint256 blockNumber, bytes32 slot, bytes calldata storageSlotTrieProof) public view returns (bytes32 slotValue) {
        EVMFactRegistryModuleStorage storage ms = moduleStorage();

        Account storage accountData = ms.accountField[chainId][account][blockNumber];
        require(readBitAtIndexFromRight(accountData.savedFields, uint8(AccountField.STORAGE_ROOT)), "ERR_STORAGE_ROOT_NOT_SAVED");

        bytes32 storageRoot = accountData.fields[AccountField.STORAGE_ROOT];

        (, bytes memory slotValueRLP) = SecureMerkleTrie.get(abi.encode(slot), storageSlotTrieProof, storageRoot);

        slotValue = slotValueRLP.toRLPItem().readBytes32();
    }

    /// @inheritdoc IEVMFactRegistryModule
    function verifyTimestamp(uint256 chainId, uint256 timestamp_, BlockHeaderProof calldata headerProof, BlockHeaderProof calldata headerProofNext) public view returns (uint256) {
        _verifyAccumulatedHeaderProof(chainId, headerProof);
        _verifyAccumulatedHeaderProof(chainId, headerProofNext);

        uint256 blockNumber = _decodeBlockNumber(headerProof.provenBlockHeader);
        uint256 blockNumberNext = _decodeBlockNumber(headerProofNext.provenBlockHeader);

        require(blockNumber + 1 == blockNumberNext, "ERR_INVALID_BLOCK_NUMBER_NEXT");

        uint256 blockTimestamp = _decodeBlockTimestamp(headerProof.provenBlockHeader);
        uint256 blockTimestampNext = _decodeBlockTimestamp(headerProofNext.provenBlockHeader);

        require(blockTimestamp <= timestamp_ && timestamp_ < blockTimestampNext, "ERR_TIMESTAMP_NOT_IN_RANGE");

        return blockNumber;
    }

    // ========================= Internal functions ========================= //

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

    function _decodeBlockTimestamp(bytes memory headerRlp) internal pure returns (uint256) {
        return RLPReader.toRLPItem(headerRlp).readList()[11].readUint256();
    }

    function readBitAtIndexFromRight(uint8 bitmap, uint8 index) internal pure returns (bool value) {
        require(index < 8, "ERR_OUR_OF_RANGE");
        return (bitmap & (1 << index)) != 0;
    }
}
