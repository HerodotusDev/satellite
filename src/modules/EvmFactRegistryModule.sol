// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {StatelessMmr} from "@solidity-mmr/lib/StatelessMmr.sol";
import {Lib_SecureMerkleTrie as SecureMerkleTrie} from "src/libraries/external/optimism/trie/Lib_SecureMerkleTrie.sol";
import {Lib_RLPReader as RLPReader} from "src/libraries/external/optimism/rlp/Lib_RLPReader.sol";
import {IEvmFactRegistryModule} from "src/interfaces/modules/IEvmFactRegistryModule.sol";
import {LibSatellite} from "src/libraries/LibSatellite.sol";
import {ISatellite} from "src/interfaces/ISatellite.sol";

contract EvmFactRegistryModule is IEvmFactRegistryModule {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    uint8 private constant ACCOUNT_NONCE_INDEX = 0;
    uint8 private constant ACCOUNT_BALANCE_INDEX = 1;
    uint8 private constant ACCOUNT_STORAGE_ROOT_INDEX = 2;
    uint8 private constant ACCOUNT_CODE_HASH_INDEX = 3;

    uint8 private constant APECHAIN_ACCOUNT_NONCE_INDEX = 0;
    uint8 private constant APECHAIN_ACCOUNT_FLAGS_INDEX = 1;
    uint8 private constant APECHAIN_ACCOUNT_FIXED_INDEX = 2;
    uint8 private constant APECHAIN_ACCOUNT_SHARES_INDEX = 3;
    uint8 private constant APECHAIN_ACCOUNT_DEBT_INDEX = 4;
    uint8 private constant APECHAIN_ACCOUNT_DELEGATE_INDEX = 5;
    uint8 private constant APECHAIN_ACCOUNT_CODE_HASH_INDEX = 6;
    uint8 private constant APECHAIN_ACCOUNT_STORAGE_ROOT_INDEX = 7;

    address public constant APECHAIN_SHARE_PRICE_ADDRESS = 0xA4b05FffffFffFFFFfFFfffFfffFFfffFfFfFFFf;
    bytes32 public constant APECHAIN_SHARE_PRICE_SLOT = bytes32(0x15fed0451499512d95f3ec5a41c878b9de55f21878b5b4e190d4667ec709b432);

    bytes32 private constant EMPTY_TRIE_ROOT_HASH = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;
    bytes32 private constant EMPTY_CODE_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");

    // ========================= Satellite Module Storage ========================= //

    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.satellite.module.storage.evm-fact-registry");

    function moduleStorage() internal pure returns (EvmFactRegistryModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // ===================== Functions for End Users ===================== //

    /// @inheritdoc IEvmFactRegistryModule
    function accountFieldSafe(uint256 chainId, address account, uint256 blockNumber, AccountField field) external view returns (bool, bytes32) {
        EvmFactRegistryModuleStorage storage ms = moduleStorage();

        Account storage accountData = ms.accountField[chainId][account][blockNumber];
        uint8 savedFieldIndex = uint8(field) < 4 ? uint8(field) : 4;
        if (!readBitAtIndexFromRight(accountData.savedFields, savedFieldIndex)) return (false, bytes32(0));
        return (true, accountData.fields[field]);
    }

    /// @inheritdoc IEvmFactRegistryModule
    function accountField(uint256 chainId, address account, uint256 blockNumber, AccountField field) external view returns (bytes32) {
        (bool exists, bytes32 value) = IEvmFactRegistryModule(address(this)).accountFieldSafe(chainId, account, blockNumber, field);
        require(exists, "STORAGE_PROOF_FIELD_NOT_SAVED");
        return value;
    }

    /// @inheritdoc IEvmFactRegistryModule
    function storageSlotSafe(uint256 chainId, address account, uint256 blockNumber, bytes32 slot) external view returns (bool, bytes32) {
        EvmFactRegistryModuleStorage storage ms = moduleStorage();

        StorageSlot storage valueRaw = ms.accountStorageSlotValues[chainId][account][blockNumber][slot];
        if (!valueRaw.exists) return (false, bytes32(0));
        return (true, valueRaw.value);
    }

    /// @inheritdoc IEvmFactRegistryModule
    function storageSlot(uint256 chainId, address account, uint256 blockNumber, bytes32 slot) external view returns (bytes32) {
        (bool exists, bytes32 value) = IEvmFactRegistryModule(address(this)).storageSlotSafe(chainId, account, blockNumber, slot);
        require(exists, "STORAGE_PROOF_SLOT_NOT_SAVED");
        return value;
    }

    /// @inheritdoc IEvmFactRegistryModule
    function timestampSafe(uint256 chainId, uint256 timestamp_) external view returns (bool, uint256) {
        EvmFactRegistryModuleStorage storage ms = moduleStorage();

        // block number stored is blockNumber + 1 and 0 means no data
        uint256 blockNumberStored = ms.timestampToBlockNumber[chainId][timestamp_];
        if (blockNumberStored == 0) return (false, 0);
        return (true, blockNumberStored - 1);
    }

    /// @inheritdoc IEvmFactRegistryModule
    function timestamp(uint256 chainId, uint256 timestamp_) external view returns (uint256) {
        (bool exists, uint256 value) = IEvmFactRegistryModule(address(this)).timestampSafe(chainId, timestamp_);
        require(exists, "STORAGE_PROOF_TIMESTAMP_NOT_SAVED");
        return value;
    }

    // ========================= Core Functions ========================= //

    function proveAccount(uint256 chainId, address account, uint8 accountFieldsToSave, BlockHeaderProof calldata headerProof, bytes calldata accountTrieProof) external {
        if (_isApeChain(chainId)) {
            require(accountFieldsToSave >> 5 == 0, "STORAGE_PROOF_INVALID_FIELDS_TO_SAVE");
            _proveAccountApechain(chainId, account, accountFieldsToSave, headerProof, accountTrieProof);
        } else {
            require(accountFieldsToSave >> 4 == 0, "STORAGE_PROOF_INVALID_FIELDS_TO_SAVE");
            _proveAccountEvm(chainId, account, accountFieldsToSave, headerProof, accountTrieProof);
        }
    }

    /// @inheritdoc IEvmFactRegistryModule
    function proveStorage(uint256 chainId, address account, uint256 blockNumber, bytes32 slot, bytes calldata storageSlotTrieProof) external {
        EvmFactRegistryModuleStorage storage ms = moduleStorage();

        // Verify the proof and decode the slot value
        bytes32 slotValue = verifyStorage(chainId, account, blockNumber, slot, storageSlotTrieProof);
        ms.accountStorageSlotValues[chainId][account][blockNumber][slot] = StorageSlot(slotValue, true);

        emit ProvenStorage(chainId, account, blockNumber, slot, slotValue);
    }

    /// @inheritdoc IEvmFactRegistryModule
    function proveTimestamp(uint256 chainId, uint256 timestamp_, BlockHeaderProof calldata headerProof, BlockHeaderProof calldata headerProofNext) external {
        EvmFactRegistryModuleStorage storage ms = moduleStorage();

        uint256 blockNumber = verifyTimestamp(chainId, timestamp_, headerProof, headerProofNext);
        // blockNumber + 1 is stored, blockNumber cannot overflow because of check in verifyTimestamp
        ms.timestampToBlockNumber[chainId][timestamp_] = blockNumber + 1;

        emit ProvenTimestamp(chainId, timestamp_, blockNumber);
    }

    // ========================= View functions ========================= //

    /// @inheritdoc IEvmFactRegistryModule
    function verifyAccountApechain(
        uint256 chainId,
        address account,
        BlockHeaderProof calldata headerProof,
        bytes calldata accountTrieProof
    ) public view returns (uint256 nonce, uint256 flags, uint256 fixed_, uint256 shares, uint256 debt, uint256 delegate, bytes32 codeHash, bytes32 storageRoot) {
        require(_isApeChain(chainId), "STORAGE_PROOF_NOT_APECHAIN");

        // Ensure provided header is a valid one by making sure it is present in saved MMRs
        _verifyAccumulatedHeaderProof(chainId, headerProof);

        // Verify the account state proof
        bytes32 stateRoot = _getStateRoot(headerProof.provenBlockHeader);

        (bool doesAccountExist, bytes memory accountRLP) = SecureMerkleTrie.get(abi.encodePacked(account), accountTrieProof, stateRoot);
        // Decode the account fields
        (nonce, flags, fixed_, shares, debt, delegate, codeHash, storageRoot) = _decodeAccountFieldsApechain(doesAccountExist, accountRLP);
    }

    function verifyAccount(
        uint256 chainId,
        address account,
        BlockHeaderProof calldata headerProof,
        bytes calldata accountTrieProof
    ) public view returns (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot) {
        require(!_isApeChain(chainId), "STORAGE_PROOF_SHOULD_BE_NON_APECHAIN");

        // Ensure provided header is a valid one by making sure it is present in saved MMRs
        _verifyAccumulatedHeaderProof(chainId, headerProof);

        // Verify the account state proof
        bytes32 stateRoot = _getStateRoot(headerProof.provenBlockHeader);

        (bool doesAccountExist, bytes memory accountRLP) = SecureMerkleTrie.get(abi.encodePacked(account), accountTrieProof, stateRoot);
        // Decode the account fields
        (nonce, accountBalance, storageRoot, codeHash) = _decodeAccountFields(doesAccountExist, accountRLP);
    }

    /// @inheritdoc IEvmFactRegistryModule
    function verifyStorage(uint256 chainId, address account, uint256 blockNumber, bytes32 slot, bytes calldata storageSlotTrieProof) public view returns (bytes32 slotValue) {
        EvmFactRegistryModuleStorage storage ms = moduleStorage();

        Account storage accountData = ms.accountField[chainId][account][blockNumber];
        require(readBitAtIndexFromRight(accountData.savedFields, uint8(AccountField.STORAGE_ROOT)), "STORAGE_PROOF_STORAGE_ROOT_NOT_SAVED");

        bytes32 storageRoot = accountData.fields[AccountField.STORAGE_ROOT];

        (, bytes memory slotValueRLP) = SecureMerkleTrie.get(abi.encode(slot), storageSlotTrieProof, storageRoot);

        slotValue = slotValueRLP.toRLPItem().readBytes32();
    }

    /// @inheritdoc IEvmFactRegistryModule
    function verifyTimestamp(uint256 chainId, uint256 timestamp_, BlockHeaderProof calldata headerProof, BlockHeaderProof calldata headerProofNext) public view returns (uint256) {
        _verifyAccumulatedHeaderProof(chainId, headerProof);
        _verifyAccumulatedHeaderProof(chainId, headerProofNext);

        uint256 blockNumber = _decodeBlockNumber(headerProof.provenBlockHeader);
        uint256 blockNumberNext = _decodeBlockNumber(headerProofNext.provenBlockHeader);

        require(blockNumber != type(uint256).max, "STORAGE_PROOF_BLOCK_NUMBER_TOO_HIGH");
        require(blockNumber + 1 == blockNumberNext, "STORAGE_PROOF_INVALID_BLOCK_NUMBER_NEXT");

        uint256 blockTimestamp = _decodeBlockTimestamp(headerProof.provenBlockHeader);
        uint256 blockTimestampNext = _decodeBlockTimestamp(headerProofNext.provenBlockHeader);

        require(blockTimestamp <= timestamp_ && timestamp_ < blockTimestampNext, "STORAGE_PROOF_TIMESTAMP_NOT_BETWEEN_BLOCKS");

        return blockNumber;
    }

    function getApechainSharePriceSafe(uint256 chainId, uint256 blockNumber) public view returns (bool, uint256) {
        require(_isApeChain(chainId), "STORAGE_PROOF_NOT_APECHAIN");
        (bool exists, bytes32 slotValue) = IEvmFactRegistryModule(address(this)).storageSlotSafe(chainId, APECHAIN_SHARE_PRICE_ADDRESS, blockNumber, APECHAIN_SHARE_PRICE_SLOT);
        return (exists, uint256(slotValue));
    }

    function getApechainSharePrice(uint256 chainId, uint256 blockNumber) public view returns (uint256) {
        (bool exists, uint256 sharePrice) = IEvmFactRegistryModule(address(this)).getApechainSharePriceSafe(chainId, blockNumber);
        require(exists, "STORAGE_PROOF_SHARE_PRICE_NOT_SAVED");
        return sharePrice;
    }

    // ========================= Internal functions ========================= //

    function _isApeChain(uint256 chainId) internal pure returns (bool) {
        return chainId == 33111 || chainId == 33139;
    }

    function _proveAccountEvm(uint256 chainId, address account, uint8 accountFieldsToSave, BlockHeaderProof calldata headerProof, bytes calldata accountTrieProof) internal {
        EvmFactRegistryModuleStorage storage ms = moduleStorage();
        Account storage accountData = ms.accountField[chainId][account][headerProof.blockNumber];

        // Verify the proof and decode the account fields
        (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot) = verifyAccount(chainId, account, headerProof, accountTrieProof);

        // Save the desired account properties to the storage
        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountField.NONCE))) {
            accountData.savedFields |= uint8(1 << uint8(AccountField.NONCE));
            accountData.fields[AccountField.NONCE] = bytes32(nonce);
        }

        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountField.BALANCE))) {
            accountData.savedFields |= uint8(1 << uint8(AccountField.BALANCE));
            accountData.fields[AccountField.BALANCE] = bytes32(accountBalance);
        }

        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountField.CODE_HASH))) {
            accountData.savedFields |= uint8(1 << uint8(AccountField.CODE_HASH));
            accountData.fields[AccountField.CODE_HASH] = codeHash;
        }

        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountField.STORAGE_ROOT))) {
            accountData.savedFields |= uint8(1 << uint8(AccountField.STORAGE_ROOT));
            accountData.fields[AccountField.STORAGE_ROOT] = storageRoot;
        }

        emit ProvenAccount(chainId, account, headerProof.blockNumber, accountFieldsToSave, nonce, accountBalance, codeHash, storageRoot, 0, 0, 0, 0, 0);
    }

    function _proveAccountApechain(uint256 chainId, address account, uint8 accountFieldsToSave, BlockHeaderProof calldata headerProof, bytes calldata accountTrieProof) internal {
        EvmFactRegistryModuleStorage storage ms = moduleStorage();
        Account storage accountData = ms.accountField[chainId][account][headerProof.blockNumber];

        // Verify the proof and decode the account fields
        (uint256 nonce, uint256 flags, uint256 fixed_, uint256 shares, uint256 debt, uint256 delegate, bytes32 codeHash, bytes32 storageRoot) = verifyAccountApechain(
            chainId,
            account,
            headerProof,
            accountTrieProof
        );

        // Save the desired account properties to the storage
        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountField.NONCE))) {
            accountData.savedFields |= uint8(1 << uint8(AccountField.NONCE));
            accountData.fields[AccountField.NONCE] = bytes32(nonce);
        }

        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountField.BALANCE))) {
            accountData.savedFields |= uint8(1 << uint8(AccountField.BALANCE));
            uint256 sharePrice = IEvmFactRegistryModule(address(this)).getApechainSharePrice(chainId, headerProof.blockNumber);
            accountData.fields[AccountField.BALANCE] = bytes32(shares * sharePrice + fixed_ - debt);
        }

        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountField.CODE_HASH))) {
            accountData.savedFields |= uint8(1 << uint8(AccountField.CODE_HASH));
            accountData.fields[AccountField.CODE_HASH] = codeHash;
        }

        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountField.STORAGE_ROOT))) {
            accountData.savedFields |= uint8(1 << uint8(AccountField.STORAGE_ROOT));
            accountData.fields[AccountField.STORAGE_ROOT] = storageRoot;
        }

        // Bit 4 is for all ApeChain fields so either all ApeChain fields are saved or none
        if (readBitAtIndexFromRight(accountFieldsToSave, 4)) {
            accountData.savedFields |= 1 << 4;
            accountData.fields[AccountField.APE_FLAGS] = bytes32(flags);
            accountData.fields[AccountField.APE_FIXED] = bytes32(fixed_);
            accountData.fields[AccountField.APE_SHARES] = bytes32(shares);
            accountData.fields[AccountField.APE_DEBT] = bytes32(debt);
            accountData.fields[AccountField.APE_DELEGATE] = bytes32(delegate);
        }

        emit ProvenAccount(chainId, account, headerProof.blockNumber, accountFieldsToSave, nonce, 0, codeHash, storageRoot, flags, fixed_, shares, debt, delegate);
    }

    function _verifyAccumulatedHeaderProof(uint256 chainId, BlockHeaderProof memory proof) internal view {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();
        bytes32 mmrRoot = s.mmrs[chainId][proof.treeId][KECCAK_HASHING_FUNCTION].mmrSizeToRoot[proof.mmrTreeSize];
        require(mmrRoot != bytes32(0), "STORAGE_PROOF_EMPTY_MMR_ROOT");

        bytes32 blockHeaderHash = keccak256(proof.provenBlockHeader);

        StatelessMmr.verifyProof(proof.blockProofLeafIndex, blockHeaderHash, proof.mmrElementInclusionProof, proof.mmrPeaks, proof.mmrTreeSize, mmrRoot);

        uint256 actualBlockNumber = _decodeBlockNumber(proof.provenBlockHeader);
        require(actualBlockNumber == proof.blockNumber, "STORAGE_PROOF_INVALID_BLOCK_NUMBER");
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

    function _decodeAccountFieldsApechain(
        bool doesAccountExist,
        bytes memory accountRLP
    ) internal pure returns (uint256 nonce, uint256 flags, uint256 fixed_, uint256 shares, uint256 debt, uint256 delegate, bytes32 storageRoot, bytes32 codeHash) {
        if (!doesAccountExist) {
            return (0, 0, 0, 0, 0, 0, EMPTY_TRIE_ROOT_HASH, EMPTY_CODE_HASH);
        }

        RLPReader.RLPItem[] memory accountFields = accountRLP.toRLPItem().readList();

        nonce = accountFields[APECHAIN_ACCOUNT_NONCE_INDEX].readUint256();
        flags = accountFields[APECHAIN_ACCOUNT_FLAGS_INDEX].readUint256();
        fixed_ = accountFields[APECHAIN_ACCOUNT_FIXED_INDEX].readUint256();
        shares = accountFields[APECHAIN_ACCOUNT_SHARES_INDEX].readUint256();
        debt = accountFields[APECHAIN_ACCOUNT_DEBT_INDEX].readUint256();
        delegate = accountFields[APECHAIN_ACCOUNT_DELEGATE_INDEX].readUint256();
        codeHash = accountFields[APECHAIN_ACCOUNT_CODE_HASH_INDEX].readBytes32();
        storageRoot = accountFields[APECHAIN_ACCOUNT_STORAGE_ROOT_INDEX].readBytes32();
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
        require(index < 8, "STORAGE_PROOF_INDEX_OUT_OF_RANGE");
        return (bitmap & (1 << index)) != 0;
    }
}
