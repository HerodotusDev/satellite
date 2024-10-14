// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

interface INativeFactsRegistryModule {
    event NativeAccountProven(address account, uint256 blockNumber, uint256 nonce, uint256 balance, bytes32 codeHash, bytes32 storageHash);
    event NativeStorageSlotProven(address account, uint256 blockNumber, bytes32 slot, bytes32 slotValue);

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

    function proveNativeAccount(address account, uint16 accountFieldsToSave, BlockHeaderProof calldata headerProof, bytes calldata accountTrieProof) external;

    function proveNativeStorage(address account, uint256 blockNumber, bytes32 slot, bytes calldata storageSlotTrieProof) external;

    function verifyNativeStorage(address account, uint256 blockNumber, bytes32 slot, bytes calldata storageSlotTrieProof) external view returns (bytes32 slotValue);

    function nativeAccountField(address account, uint256 blockNumber, AccountFields field) external view returns (bytes32);

    function nativeAccountStorageSlotValues(address account, uint256 blockNumber, bytes32 slot) external view returns (bytes32);
}
