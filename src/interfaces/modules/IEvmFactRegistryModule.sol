// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface IEvmFactRegistryModule {
    struct BlockHeaderProof {
        uint256 treeId;
        uint128 mmrTreeSize;
        uint256 blockNumber;
        uint256 blockProofLeafIndex;
        bytes32[] mmrPeaks;
        bytes32[] mmrElementInclusionProof;
        bytes provenBlockHeader;
    }

    enum AccountField {
        NONCE,
        BALANCE,
        STORAGE_ROOT,
        CODE_HASH,
        APE_FLAGS,
        APE_FIXED,
        APE_SHARES,
        APE_DEBT,
        APE_DELEGATE
    }

    struct StorageSlot {
        bytes32 value;
        bool exists;
    }

    struct Account {
        /// @dev Bitmask of saved fields (5 bits)
        /// @dev First 4 bits are for NONCE, BALANCE, STORAGE_ROOT, CODE_HASH
        /// @dev 5th bit (2^4) is for all ApeChain fields so either all ApeChain fields are saved or none
        uint8 savedFields;
        mapping(AccountField => bytes32) fields;
    }

    struct EvmFactRegistryModuleStorage {
        /// @dev chain_id => address => block_number => Account
        mapping(uint256 => mapping(address => mapping(uint256 => Account))) accountField;
        /// @dev chain_id => address => block_number => slot => value
        mapping(uint256 => mapping(address => mapping(uint256 => mapping(bytes32 => StorageSlot)))) accountStorageSlotValues;
        /// @dev chain_id => timestamp => block_number + 1 (0 means no data)
        mapping(uint256 => mapping(uint256 => uint256)) timestampToBlockNumber;
    }

    // ===================== Functions for End Users ===================== //

    /// @notice Returns nonce, balance, storage root or code hash of a given account, at a given block number and chainId
    function accountField(uint256 chainId, address account, uint256 blockNumber, AccountField field) external view returns (bytes32);

    /// @notice Returns value of a given storage slot of a given account, at a given block number and chainId
    function storageSlot(uint256 chainId, address account, uint256 blockNumber, bytes32 slot) external view returns (bytes32);

    /// @notice Returns block number of the closest block with timestamp less than or equal to the given timestamp
    function timestamp(uint256 chainId, uint256 timestamp) external view returns (uint256);

    // ========================= Core Functions ========================= //

    /// @notice Stores account fields after verifying the headerProof against saved MMRs
    /// @param chainId Chain ID where the account lives
    /// @param account Address of the account
    /// @param headerProof Header proof of the block that contains the account
    /// @param accountTrieProof MPT proof for the account (has to hash to the state root)
    function proveAccount(uint256 chainId, address account, uint8 accountFieldsToSave, BlockHeaderProof calldata headerProof, bytes calldata accountTrieProof) external;

    /// @notice Stores storage slot value after verifying the storageSlotTrieProof against saved MMRs
    /// @notice Account's storage root has to be proven before calling this function
    /// @param chainId Chain ID where the queried block lives
    /// @param account Address of the account that contains the storage slot
    /// @param blockNumber Block number at which the storage slot is stored
    /// @param slot Index of the storage slot
    /// @param storageSlotTrieProof MPT proof for the storage slot (has to hash to the storage root)
    function proveStorage(uint256 chainId, address account, uint256 blockNumber, bytes32 slot, bytes calldata storageSlotTrieProof) external;

    /// @notice Stores closest timestamp to a block after verifying header proofs of two consecutive blocks,
    /// @notice where the first block is the closest block with timestamp less than or equal to the given timestamp
    /// @param chainId Chain ID where the queried block lives
    /// @param timestamp Timestamp for which you are looking for the closest block
    /// @param headerProof Header proof of the block that is the answer for the given timestamp
    /// @param headerProofNext Header proof of the next block
    function proveTimestamp(uint256 chainId, uint256 timestamp, BlockHeaderProof calldata headerProof, BlockHeaderProof calldata headerProofNext) external;

    // ========================= View functions ========================= //

    /// @notice Verifies the headerProof against saved MMRs
    /// @param chainId Chain ID where the account lives
    /// @param account Address of the account
    /// @param headerProof Header proof of the block that contains the account
    /// @param accountTrieProof MPT proof for the account (has to hash to the state root)
    /// @return nonce
    /// @return accountBalance
    /// @return codeHash
    /// @return storageRoot
    function verifyAccount(
        uint256 chainId,
        address account,
        BlockHeaderProof calldata headerProof,
        bytes calldata accountTrieProof
    ) external view returns (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot);

    /// @notice Verifies the headerProof against saved MMRs but for ApeChain chains
    /// @notice ApeChain has different handling of accounts, e.i. balance is missing,
    /// @notice and ape_flags, ape_fixed, ape_shares, ape_debt, ape_delegate are added
    /// @param chainId Chain ID where the account lives
    /// @param account Address of the account
    /// @param headerProof Header proof of the block that contains the account
    /// @param accountTrieProof MPT proof for the account (has to hash to the state root)
    /// @return nonce
    /// @return flags
    /// @return fixed_
    /// @return shares
    /// @return debt
    /// @return delegate
    /// @return codeHash
    /// @return storageRoot
    function verifyAccountApechain(
        uint256 chainId,
        address account,
        BlockHeaderProof calldata headerProof,
        bytes calldata accountTrieProof
    ) external view returns (uint256 nonce, uint256 flags, uint256 fixed_, uint256 shares, uint256 debt, uint256 delegate, bytes32 codeHash, bytes32 storageRoot);

    /// @notice Verifies the storageSlotTrieProof against saved MMRs
    /// @notice Account's storage root has to be proven before calling this function
    /// @param chainId Chain ID where the queried block lives
    /// @param account Address of the account that contains the storage slot
    /// @param blockNumber Block number at which the storage slot is stored
    /// @param slot Index of the storage slot
    /// @param storageSlotTrieProof MPT proof for the storage slot (has to hash to the storage root)
    /// @return slotValue Value of the storage slot
    function verifyStorage(uint256 chainId, address account, uint256 blockNumber, bytes32 slot, bytes calldata storageSlotTrieProof) external view returns (bytes32 slotValue);

    /// @notice Verifies header proofs of two consecutive blocks, where the first block is the closest block with timestamp less than or equal to the given timestamp
    /// @param chainId Chain ID where the queried block lives
    /// @param timestamp Timestamp for which you are looking for the closest block
    /// @param headerProof Header proof of the block that is the answer for the given timestamp
    /// @param headerProofNext Header proof of the next block
    /// @return blockNumber Block number of the closest block with timestamp that is less than or equal to the given timestamp
    function verifyTimestamp(uint256 chainId, uint256 timestamp, BlockHeaderProof calldata headerProof, BlockHeaderProof calldata headerProofNext) external view returns (uint256);

    /// @notice Returns the share price of the ApeChain at a given block number,
    /// @notice reverts with "ERR_SLOT_NOT_SAVED" if the share price is not saved for the given block number
    /// @param chainId Chain ID of the ApeChain
    /// @param blockNumber Block number of the ApeChain
    function getApechainSharePrice(uint256 chainId, uint256 blockNumber) external view returns (uint256);

    // ========================= Events ========================= //

    /// @notice Emitted when account fields are proven
    event ProvenAccount(
        uint256 chainId,
        address account,
        uint256 blockNumber,
        uint8 savedFields,
        uint256 nonce,
        uint256 balance,
        bytes32 codeHash,
        bytes32 storageHash,
        uint256 flags,
        uint256 fixed_,
        uint256 shares,
        uint256 debt,
        uint256 delegate
    );

    /// @notice Emitted when storage slot value is proven
    event ProvenStorage(uint256 chainId, address account, uint256 blockNumber, bytes32 slot, bytes32 slotValue);

    /// @notice Emitted when timestamp is proven
    event ProvenTimestamp(uint256 chainId, uint256 timestamp, uint256 blockNumber);
}
