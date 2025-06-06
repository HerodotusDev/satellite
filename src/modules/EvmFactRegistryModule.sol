// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {StatelessMmr} from "@solidity-mmr/lib/StatelessMmr.sol";
import {Lib_SecureMerkleTrie as SecureMerkleTrie} from "src/libraries/external/optimism/trie/Lib_SecureMerkleTrie.sol";
import {Lib_RLPReader as RLPReader} from "src/libraries/external/optimism/rlp/Lib_RLPReader.sol";
import {IEvmFactRegistryModule} from "src/interfaces/modules/IEvmFactRegistryModule.sol";
import {LibSatellite} from "src/libraries/LibSatellite.sol";
import {ISatellite} from "src/interfaces/ISatellite.sol";
import {console} from "forge-std/console.sol";

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

    uint8 private constant BLOCK_HEADER_FIELD_COUNT = 15;

    bytes32 private constant EMPTY_TRIE_ROOT_HASH = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;
    bytes32 private constant EMPTY_CODE_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    bytes32 public constant KECCAK_HASHING_FUNCTION = keccak256("keccak");

    address public constant APECHAIN_SHARE_PRICE_ADDRESS = 0xA4b05FffffFffFFFFfFFfffFfffFFfffFfFfFFFf;
    bytes32 public constant APECHAIN_SHARE_PRICE_SLOT = bytes32(0x15fed0451499512d95f3ec5a41c878b9de55f21878b5b4e190d4667ec709b432);

    // ========================= Satellite Module Storage ========================= //

    bytes32 constant MODULE_STORAGE_POSITION = keccak256("diamond.standard.satellite.module.storage.evm-fact-registry");

    function moduleStorage() internal pure returns (EvmFactRegistryModuleStorage storage s) {
        bytes32 position = MODULE_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // =============== Functions for End Users (Reads proven values) ============== //

    /// @inheritdoc IEvmFactRegistryModule
    function headerFieldSafe(uint256 chainId, uint256 blockNumber, BlockHeaderField field) public view returns (bool, bytes32) {
        BlockHeader storage header = moduleStorage().blockHeader[chainId][blockNumber];
        if ((header.savedFields >> uint8(field)) & 1 == 0) return (false, bytes32(0));
        return (true, header.fields[field]);
    }

    /// @inheritdoc IEvmFactRegistryModule
    function headerField(uint256 chainId, uint256 blockNumber, BlockHeaderField field) public view returns (bytes32) {
        (bool exists, bytes32 value) = headerFieldSafe(chainId, blockNumber, field);
        require(exists, "STORAGE_PROOF_HEADER_FIELD_NOT_SAVED");
        return value;
    }

    /// @inheritdoc IEvmFactRegistryModule
    function accountFieldSafe(uint256 chainId, uint256 blockNumber, address account, AccountField field) public view returns (bool, bytes32) {
        Account storage accountData = moduleStorage().accountField[chainId][account][blockNumber];
        uint8 savedFieldIndex = uint8(field) < 4 ? uint8(field) : 4;
        if ((accountData.savedFields >> savedFieldIndex) & 1 == 0) return (false, bytes32(0));
        return (true, accountData.fields[field]);
    }

    /// @inheritdoc IEvmFactRegistryModule
    function accountField(uint256 chainId, uint256 blockNumber, address account, AccountField field) public view returns (bytes32) {
        (bool exists, bytes32 value) = accountFieldSafe(chainId, blockNumber, account, field);
        require(exists, "STORAGE_PROOF_ACCOUNT_FIELD_NOT_SAVED");
        return value;
    }

    /// @inheritdoc IEvmFactRegistryModule
    function storageSlotSafe(uint256 chainId, uint256 blockNumber, address account, bytes32 slot) public view returns (bool, bytes32) {
        StorageSlot storage valueRaw = moduleStorage().accountStorageSlotValues[chainId][account][blockNumber][slot];
        if (!valueRaw.exists) return (false, bytes32(0));
        return (true, valueRaw.value);
    }

    /// @inheritdoc IEvmFactRegistryModule
    function storageSlot(uint256 chainId, uint256 blockNumber, address account, bytes32 slot) public view returns (bytes32) {
        (bool exists, bytes32 value) = storageSlotSafe(chainId, blockNumber, account, slot);
        require(exists, "STORAGE_PROOF_SLOT_NOT_SAVED");
        return value;
    }

    /// @inheritdoc IEvmFactRegistryModule
    function timestampSafe(uint256 chainId, uint256 timestamp_) public view returns (bool, uint256) {
        // block number stored is blockNumber + 1 and 0 means no data
        uint256 blockNumberStored = moduleStorage().timestampToBlockNumber[chainId][timestamp_];
        if (blockNumberStored == 0) return (false, 0);
        return (true, blockNumberStored - 1);
    }

    /// @inheritdoc IEvmFactRegistryModule
    function timestamp(uint256 chainId, uint256 timestamp_) public view returns (uint256) {
        (bool exists, uint256 blockNumber) = timestampSafe(chainId, timestamp_);
        require(exists, "STORAGE_PROOF_TIMESTAMP_NOT_SAVED");
        return blockNumber;
    }

    function getApechainSharePriceSafe(uint256 chainId, uint256 blockNumber) public view returns (bool, uint256) {
        require(_isApeChain(chainId), "STORAGE_PROOF_NOT_APECHAIN");
        (bool exists, bytes32 slotValue) = storageSlotSafe(chainId, blockNumber, APECHAIN_SHARE_PRICE_ADDRESS, APECHAIN_SHARE_PRICE_SLOT);
        return (exists, uint256(slotValue));
    }

    function getApechainSharePrice(uint256 chainId, uint256 blockNumber) public view returns (uint256) {
        (bool exists, uint256 sharePrice) = getApechainSharePriceSafe(chainId, blockNumber);
        require(exists, "STORAGE_PROOF_SHARE_PRICE_NOT_SAVED");
        return sharePrice;
    }

    // ====================== Proving (Saves verified values) ===================== //

    function proveHeader(uint256 chainId, uint16 headerFieldsToSave, BlockHeaderProof calldata headerProof) external {
        require(headerFieldsToSave >> uint16(BLOCK_HEADER_FIELD_COUNT) == 0, "STORAGE_PROOF_INVALID_FIELDS_TO_SAVE");
        require((headerFieldsToSave >> uint8(BlockHeaderField.LOGS_BLOOM)) & 1 == 0, "STORAGE_PROOF_LOGS_BLOOM_NOT_SUPPORTED");
        // Block number is the key in the mapping, so it's pointless to save it.
        require((headerFieldsToSave >> uint8(BlockHeaderField.NUMBER)) & 1 == 0, "STORAGE_PROOF_BLOCK_NUMBER_NOT_SUPPORTED");

        bytes32[BLOCK_HEADER_FIELD_COUNT] memory fields = verifyHeader(chainId, headerProof);
        uint256 blockNumber = uint256(fields[uint8(BlockHeaderField.NUMBER)]);

        BlockHeader storage header = moduleStorage().blockHeader[chainId][blockNumber];

        header.savedFields |= headerFieldsToSave; // Mark additional fields as saved
        for (uint8 i = 0; i < BLOCK_HEADER_FIELD_COUNT; i++) {
            if (headerFieldsToSave & 1 == 1) {
                header.fields[BlockHeaderField(i)] = fields[i];
            }
            headerFieldsToSave >>= 1;
        }

        emit ProvenHeader(chainId, blockNumber, header.savedFields);
    }

    function proveAccount(uint256 chainId, uint256 blockNumber, address account, uint8 accountFieldsToSave, bytes calldata accountMptProof) external {
        if (_isApeChain(chainId)) {
            _proveAccountApechain(chainId, blockNumber, account, accountFieldsToSave, accountMptProof);
        } else {
            _proveAccount(chainId, blockNumber, account, accountFieldsToSave, accountMptProof);
        }
    }

    /// @inheritdoc IEvmFactRegistryModule
    function proveStorage(uint256 chainId, uint256 blockNumber, address account, bytes32 slot, bytes calldata storageSlotMptProof) external {
        // Read proven storage root
        bytes32 storageRoot = accountField(chainId, blockNumber, account, AccountField.STORAGE_ROOT);

        // Verify the proof and decode the slot value
        bytes32 slotValue = verifyOnlyStorage(slot, storageRoot, storageSlotMptProof);

        // Save the slot value to the storage
        moduleStorage().accountStorageSlotValues[chainId][account][blockNumber][slot] = StorageSlot(slotValue, true);

        emit ProvenStorage(chainId, blockNumber, account, slot);
    }

    /// @inheritdoc IEvmFactRegistryModule
    function proveTimestamp(uint256 chainId, uint256 timestamp_, uint256 blockNumberLow) external {
        // Read proven timestamps
        uint256 blockTimestampLow = uint256(headerField(chainId, blockNumberLow, BlockHeaderField.TIMESTAMP));
        uint256 blockTimestampHigh = uint256(headerField(chainId, blockNumberLow + 1, BlockHeaderField.TIMESTAMP));

        // Verify that blockNumberLow is the answer for given timestamp
        verifyOnlyTimestamp(timestamp_, blockNumberLow, blockTimestampLow, blockTimestampHigh);

        // blockNumber + 1 is stored, blockNumber cannot overflow because of check in verifyOnlyTimestamp
        moduleStorage().timestampToBlockNumber[chainId][timestamp_] = blockNumberLow + 1;

        emit ProvenTimestamp(chainId, timestamp_);
    }

    // ============ Verifying (Verifies that storage proof is correct) ============ //

    /// @inheritdoc IEvmFactRegistryModule
    function verifyHeader(uint256 chainId, BlockHeaderProof calldata headerProof) public view returns (bytes32[BLOCK_HEADER_FIELD_COUNT] memory fields) {
        ISatellite.SatelliteStorage storage s = LibSatellite.satelliteStorage();

        fields = _readBlockHeaderFields(headerProof.blockHeaderRlp);

        // Ensure provided header is a valid one by making sure it is present in saved MMRs

        bytes32 mmrRoot = s.mmrs[chainId][headerProof.mmrId][KECCAK_HASHING_FUNCTION].mmrSizeToRoot[headerProof.mmrSize];
        require(mmrRoot != bytes32(0), "STORAGE_PROOF_EMPTY_MMR_ROOT");

        bytes32 blockHeaderHash = keccak256(headerProof.blockHeaderRlp);

        StatelessMmr.verifyProof(headerProof.mmrLeafIndex, blockHeaderHash, headerProof.mmrInclusionProof, headerProof.mmrPeaks, headerProof.mmrSize, mmrRoot);
    }

    /// @inheritdoc IEvmFactRegistryModule
    function verifyOnlyAccount(
        uint256 chainId,
        address account,
        bytes32 stateRoot,
        bytes calldata accountMptProof
    ) public pure returns (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot) {
        require(!_isApeChain(chainId), "STORAGE_PROOF_SHOULD_BE_NON_APECHAIN");

        (bool doesAccountExist, bytes memory accountRLP) = SecureMerkleTrie.get(abi.encodePacked(account), accountMptProof, stateRoot);

        (nonce, accountBalance, storageRoot, codeHash) = _decodeAccountFields(doesAccountExist, accountRLP);
    }

    function verifyAccount(
        uint256 chainId,
        uint256 blockNumber,
        address account,
        BlockHeaderProof calldata headerProof,
        bytes calldata accountMptProof
    ) public view returns (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot) {
        bytes32[BLOCK_HEADER_FIELD_COUNT] memory headerFields = verifyHeader(chainId, headerProof);

        require(uint256(headerFields[uint8(BlockHeaderField.NUMBER)]) == blockNumber, "STORAGE_PROOF_BLOCK_NUMBER_NOT_MATCH");
        bytes32 stateRoot = headerFields[uint8(BlockHeaderField.STATE_ROOT)];

        return verifyOnlyAccount(chainId, account, stateRoot, accountMptProof);
    }

    /// @inheritdoc IEvmFactRegistryModule
    function verifyOnlyAccountApechain(
        uint256 chainId,
        address account,
        bytes32 stateRoot,
        bytes calldata accountMptProof
    ) public pure returns (uint256 nonce, uint256 flags, uint256 fixed_, uint256 shares, uint256 debt, uint256 delegate, bytes32 codeHash, bytes32 storageRoot) {
        require(_isApeChain(chainId), "STORAGE_PROOF_SHOULD_BE_APECHAIN");

        (bool doesAccountExist, bytes memory accountRLP) = SecureMerkleTrie.get(abi.encodePacked(account), accountMptProof, stateRoot);

        (nonce, flags, fixed_, shares, debt, delegate, codeHash, storageRoot) = _decodeAccountFieldsApechain(doesAccountExist, accountRLP);
    }

    function verifyAccountApechain(
        uint256 chainId,
        uint256 blockNumber,
        address account,
        BlockHeaderProof calldata headerProof,
        bytes calldata accountMptProof
    ) public view returns (uint256 nonce, uint256 flags, uint256 fixed_, uint256 shares, uint256 debt, uint256 delegate, bytes32 codeHash, bytes32 storageRoot) {
        bytes32[BLOCK_HEADER_FIELD_COUNT] memory headerFields = verifyHeader(chainId, headerProof);

        require(uint256(headerFields[uint8(BlockHeaderField.NUMBER)]) == blockNumber, "STORAGE_PROOF_BLOCK_NUMBER_NOT_MATCH");
        bytes32 stateRoot = headerFields[uint8(BlockHeaderField.STATE_ROOT)];

        return verifyOnlyAccountApechain(chainId, account, stateRoot, accountMptProof);
    }

    /// @inheritdoc IEvmFactRegistryModule
    function verifyOnlyStorage(bytes32 slot, bytes32 storageRoot, bytes calldata storageSlotMptProof) public pure returns (bytes32 slotValue) {
        (, bytes memory slotValueRLP) = SecureMerkleTrie.get(abi.encode(slot), storageSlotMptProof, storageRoot);

        slotValue = slotValueRLP.toRLPItem().readBytes32();
    }

    function verifyStorage(
        uint256 chainId,
        uint256 blockNumber,
        address account,
        bytes32 slot,
        BlockHeaderProof calldata headerProof,
        bytes calldata accountMptProof,
        bytes calldata storageSlotMptProof
    ) external view returns (bytes32 slotValue) {
        bytes32 storageRoot;
        if (_isApeChain(chainId)) {
            (, , , , , , , storageRoot) = verifyAccountApechain(chainId, blockNumber, account, headerProof, accountMptProof);
        } else {
            (, , , storageRoot) = verifyAccount(chainId, blockNumber, account, headerProof, accountMptProof);
        }
        return verifyOnlyStorage(slot, storageRoot, storageSlotMptProof);
    }

    /// @inheritdoc IEvmFactRegistryModule
    function verifyOnlyTimestamp(uint256 timestamp_, uint256 blockNumberLow, uint256 blockTimestampLow, uint256 blockTimestampHigh) public pure {
        require(blockNumberLow != type(uint256).max, "STORAGE_PROOF_BLOCK_NUMBER_TOO_HIGH");
        require(blockTimestampLow <= timestamp_ && timestamp_ < blockTimestampHigh, "STORAGE_PROOF_TIMESTAMP_NOT_BETWEEN_BLOCKS");
    }

    function verifyTimestamp(
        uint256 chainId,
        uint256 timestamp_,
        BlockHeaderProof calldata headerProofLow,
        BlockHeaderProof calldata headerProofHigh
    ) external view returns (uint256 blockNumber) {
        bytes32[BLOCK_HEADER_FIELD_COUNT] memory headerFieldsLow = verifyHeader(chainId, headerProofLow);
        uint256 blockNumberLow = uint256(headerFieldsLow[uint8(BlockHeaderField.NUMBER)]);
        uint256 blockTimestampLow = uint256(headerFieldsLow[uint8(BlockHeaderField.TIMESTAMP)]);

        bytes32[BLOCK_HEADER_FIELD_COUNT] memory headerFieldsHigh = verifyHeader(chainId, headerProofHigh);
        uint256 blockNumberHigh = uint256(headerFieldsHigh[uint8(BlockHeaderField.NUMBER)]);
        uint256 blockTimestampHigh = uint256(headerFieldsHigh[uint8(BlockHeaderField.TIMESTAMP)]);

        require(blockNumberLow + 1 == blockNumberHigh, "STORAGE_PROOF_BLOCK_NUMBER_NOT_CONTIGUOUS");

        verifyOnlyTimestamp(timestamp_, blockNumberLow, blockTimestampLow, blockTimestampHigh);

        return blockNumberLow;
    }

    // ============================ Internal functions ============================ //

    function _isApeChain(uint256 chainId) internal pure returns (bool) {
        return chainId == 33111 || chainId == 33139;
    }

    function _proveAccount(uint256 chainId, uint256 blockNumber, address account, uint8 accountFieldsToSave, bytes calldata accountTrieProof) internal {
        require(accountFieldsToSave >> 4 == 0, "STORAGE_PROOF_INVALID_FIELDS_TO_SAVE");

        // Read proven state root
        bytes32 stateRoot = headerField(chainId, blockNumber, BlockHeaderField.STATE_ROOT);

        // Verify the proof and decode the account fields
        (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot) = verifyOnlyAccount(chainId, account, stateRoot, accountTrieProof);

        Account storage accountData = moduleStorage().accountField[chainId][account][blockNumber];

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

        emit ProvenAccount(chainId, blockNumber, account, accountData.savedFields);
    }

    function _proveAccountApechain(uint256 chainId, uint256 blockNumber, address account, uint8 accountFieldsToSave, bytes calldata accountTrieProof) internal {
        require(accountFieldsToSave >> 5 == 0, "STORAGE_PROOF_INVALID_FIELDS_TO_SAVE");

        Account storage accountData = moduleStorage().accountField[chainId][account][blockNumber];

        // Read proven state root
        bytes32 stateRoot = headerField(chainId, blockNumber, BlockHeaderField.STATE_ROOT);

        // Verify the proof and decode the account fields
        (uint256 nonce, uint256 flags, uint256 fixed_, uint256 shares, uint256 debt, uint256 delegate, bytes32 codeHash, bytes32 storageRoot) = verifyOnlyAccountApechain(
            chainId,
            account,
            stateRoot,
            accountTrieProof
        );

        // Save the desired account properties to the storage
        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountField.NONCE))) {
            accountData.savedFields |= uint8(1 << uint8(AccountField.NONCE));
            accountData.fields[AccountField.NONCE] = bytes32(nonce);
        }

        if (readBitAtIndexFromRight(accountFieldsToSave, uint8(AccountField.BALANCE))) {
            accountData.savedFields |= uint8(1 << uint8(AccountField.BALANCE));
            uint256 sharePrice = getApechainSharePrice(chainId, blockNumber);
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

        emit ProvenAccount(chainId, blockNumber, account, accountData.savedFields);
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

    function _readBlockHeaderFields(bytes memory headerRlp) internal pure returns (bytes32[BLOCK_HEADER_FIELD_COUNT] memory fields) {
        RLPReader.RLPItem[] memory headerFields = RLPReader.toRLPItem(headerRlp).readList();
        for (uint8 i = 0; i < BLOCK_HEADER_FIELD_COUNT; i++) {
            // Logs bloom is longer than 32 bytes, so it's not supported
            if (i == uint8(BlockHeaderField.LOGS_BLOOM)) continue;
            fields[i] = headerFields[i].readBytes32();
        }
    }

    function readBitAtIndexFromRight(uint8 bitmap, uint8 index) internal pure returns (bool value) {
        require(index < 8, "STORAGE_PROOF_INDEX_OUT_OF_RANGE");
        return (bitmap & (1 << index)) != 0;
    }
}
