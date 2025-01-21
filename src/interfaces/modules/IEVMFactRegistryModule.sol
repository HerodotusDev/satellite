// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface IEVMFactRegistryModule {
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
        CODE_HASH
    }

    struct StorageSlot {
        bytes32 value;
        bool exists;
    }

    struct Account {
        /// @dev Bitmask of saved fields (4 bits)
        uint8 savedFields;
        mapping(AccountField => bytes32) fields;
    }

    struct EVMFactRegistryModuleStorage {
        /// @dev chain_id => address => block_number => Account
        mapping(uint256 => mapping(address => mapping(uint256 => Account))) accountField;
        /// @dev chain_id => address => block_number => slot => value
        mapping(uint256 => mapping(address => mapping(uint256 => mapping(bytes32 => StorageSlot)))) accountStorageSlotValues;
    }

    // ===================== Functions for End Users ===================== //

    /// @notice Returns nonce, balance, storage root or code hash of a given account, at a given block number and chainId
    function accountField(uint256 chainId, address account, uint256 blockNumber, AccountField field) external view returns (bytes32);

    /// @notice Returns value of a given storage slot of a given account, at a given block number and chainId
    function storageSlot(uint256 chainId, address account, uint256 blockNumber, bytes32 slot) external view returns (bytes32);

    // ========================= Core Functions ========================= //

    /// @notice Stores account fields after verifying the headerProof against saved MMRs
    function proveAccount(uint256 chainId, address account, uint8 accountFieldsToSave, BlockHeaderProof calldata headerProof, bytes calldata accountTrieProof) external;

    /// @notice Stores storage slot value after verifying the storageSlotTrieProof against saved MMRs
    function proveStorage(uint256 chainId, address account, uint256 blockNumber, bytes32 slot, bytes calldata storageSlotTrieProof) external;

    // ========================= View functions ========================= //

    /// @notice Verifies the headerProof against saved MMRs
    function verifyAccount(
        uint256 chainId,
        address account,
        BlockHeaderProof calldata headerProof,
        bytes calldata accountTrieProof
    ) external view returns (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot);

    /// @notice Verifies the storageSlotTrieProof against saved MMRs
    function verifyStorage(uint256 chainId, address account, uint256 blockNumber, bytes32 slot, bytes calldata storageSlotTrieProof) external view returns (bytes32 slotValue);

    // ========================= Events ========================= //

    /// @notice Emitted when account fields are proven
    event ProvenAccount(uint256 chainId, address account, uint256 blockNumber, uint256 nonce, uint256 balance, bytes32 codeHash, bytes32 storageHash);

    /// @notice Emitted when storage slot value is proven
    event ProvenStorage(uint256 chainId, address account, uint256 blockNumber, bytes32 slot, bytes32 slotValue);
}
