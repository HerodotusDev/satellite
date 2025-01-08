// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface IEVMFactRegistryModule {
    event ProvenAccount(uint256 chainId, address account, uint256 blockNumber, uint256 nonce, uint256 balance, bytes32 codeHash, bytes32 storageHash);
    event ProvenStorage(uint256 chainId, address account, uint256 blockNumber, bytes32 slot, bytes32 slotValue);

    struct BlockHeaderProof {
        uint256 treeId;
        uint128 mmrTreeSize;
        uint256 blockNumber;
        uint256 blockProofLeafIndex;
        bytes32[] mmrPeaks;
        bytes32[] mmrElementInclusionProof;
        bytes provenBlockHeader;
    }

    enum AccountFields {
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
        uint8 savedFields; // Bitmask of saved fields (4 bits)
        mapping(AccountFields => bytes32) fields;
    }

    function accountField(uint256 chainId, address account, uint256 blockNumber, AccountFields field) external view returns (bytes32);

    function storageSlot(uint256 chainId, address account, uint256 blockNumber, bytes32 slot) external view returns (bytes32);


    function proveAccount(uint256 chainId, address account, uint8 accountFieldsToSave, BlockHeaderProof calldata headerProof, bytes calldata accountTrieProof) external;

    function proveStorage(uint256 chainId, address account, uint256 blockNumber, bytes32 slot, bytes calldata storageSlotTrieProof) external;


    function verifyAccount(uint256 chainId, address account, BlockHeaderProof calldata headerProof, bytes calldata accountTrieProof ) external view returns (uint256 nonce, uint256 accountBalance, bytes32 codeHash, bytes32 storageRoot);

    function verifyStorage(uint256 chainId, address account, uint256 blockNumber, bytes32 slot, bytes calldata storageSlotTrieProof) external view returns (bytes32 slotValue);
}
