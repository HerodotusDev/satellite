use starknet::EthAddress;
use cairo_lib::{
    data_structures::{mmr::{mmr::MmrSize, peaks::Peaks, proof::Proof}, eth_mpt::MPTTrait},
    hashing::{poseidon::hash_words64, keccak::keccak_cairo_words64},
    encoding::rlp::{RLPItem, rlp_decode, rlp_decode_list_lazy},
    utils::{
        types::words64::{Words64, Words64Trait, reverse_endianness_u64},
        bitwise::reverse_endianness_u256,
    },
};
use core::num::traits::{Pow, Bounded};
use starknet::storage::Map;

type MmrId = u256;

#[derive(Drop, Serde)]
pub struct BlockHeaderProof {
    pub mmr_id: MmrId,
    pub mmr_size: MmrSize,
    pub mmr_leaf_index: MmrSize,
    pub mmr_peaks: Peaks,
    pub mmr_proof: Proof,
    pub block_header_rlp: Words64,
}

#[derive(Drop, Serde)]
pub enum BlockHeaderField {
    PARENT_HASH, // 0
    OMMERS_HASH, // 1
    BENEFICIARY, // 2
    STATE_ROOT, // 3
    TRANSACTIONS_ROOT, // 4
    RECEIPTS_ROOT, // 5
    LOGS_BLOOM, // 6 - not supported
    DIFFICULTY, // 7
    NUMBER, // 8 - not saved
    GAS_LIMIT, // 9
    GAS_USED, // 10
    TIMESTAMP, // 11
    EXTRA_DATA, // 12
    MIX_HASH, // 13
    NONCE // 14
}

impl BlockHeaderFieldIntoU32 of Into<BlockHeaderField, u32> {
    fn into(self: BlockHeaderField) -> u32 {
        match self {
            BlockHeaderField::PARENT_HASH => 0,
            BlockHeaderField::OMMERS_HASH => 1,
            BlockHeaderField::BENEFICIARY => 2,
            BlockHeaderField::STATE_ROOT => 3,
            BlockHeaderField::TRANSACTIONS_ROOT => 4,
            BlockHeaderField::RECEIPTS_ROOT => 5,
            BlockHeaderField::LOGS_BLOOM => 6,
            BlockHeaderField::DIFFICULTY => 7,
            BlockHeaderField::NUMBER => 8,
            BlockHeaderField::GAS_LIMIT => 9,
            BlockHeaderField::GAS_USED => 10,
            BlockHeaderField::TIMESTAMP => 11,
            BlockHeaderField::EXTRA_DATA => 12,
            BlockHeaderField::MIX_HASH => 13,
            BlockHeaderField::NONCE => 14,
        }
    }
}

#[starknet::storage_node]
struct BlockHeader {
    /// Bitmask of saved fields (15 bits) - i-th bit corresponds to i-th field in `BlockHeaderField`
    /// enum.
    saved_fields: u16,
    fields: Map<u32, u256>,
}

const BLOCK_HEADER_FIELD_COUNT: u32 = 15;
const BLOCK_HEADER_2_POW_FIELD_COUNT: u16 = 0x8000;
const ACCOUNT_FIELD_2_POW_LOGS_BLOOM: u16 = 0x40;
const ACCOUNT_FIELD_2_POW_NUMBER: u16 = 0x100;

#[derive(Drop, Serde)]
pub enum AccountField {
    NONCE,
    BALANCE,
    STORAGE_ROOT,
    CODE_HASH,
    APE_FLAGS,
    APE_FIXED,
    APE_SHARES,
    APE_DEBT,
    APE_DELEGATE,
}

impl AccountFieldIntoU32 of Into<AccountField, u32> {
    fn into(self: AccountField) -> u32 {
        match self {
            AccountField::NONCE => 0,
            AccountField::BALANCE => 1,
            AccountField::STORAGE_ROOT => 2,
            AccountField::CODE_HASH => 3,
            AccountField::APE_FLAGS => 4,
            AccountField::APE_FIXED => 5,
            AccountField::APE_SHARES => 6,
            AccountField::APE_DEBT => 7,
            AccountField::APE_DELEGATE => 8,
        }
    }
}

#[starknet::storage_node]
struct Account {
    /// Bitmask of saved fields (5 bits on Apechain, 4 bits otherwise).
    /// First 4 bits are for NONCE, BALANCE, STORAGE_ROOT, CODE_HASH.
    /// 5th bit (2^4) is for all ApeChain fields, so either all ApeChain fields are saved or none.
    saved_fields: u8,
    fields: Map<u32, u256>,
}

const APECHAIN_SHARE_PRICE_ADDRESS: felt252 = 0xA4b05FffffFffFFFFfFFfffFfffFFfffFfFfFFFf;
const APECHAIN_SHARE_PRICE_SLOT: u256 =
    0x15fed0451499512d95f3ec5a41c878b9de55f21878b5b4e190d4667ec709b432;

#[starknet::interface]
pub trait IEvmFactRegistry<TContractState> {
    // =============== Functions for End Users (Reads proven values) ============== //

    /// Fetches block header field (e.g. block hash, state root or timestamp) of a block with a
    /// given block number on a given chain id.
    /// Returns Some(value) if the field is saved, None otherwise.
    fn headerFieldSafe(
        self: @TContractState, chain_id: u256, block_number: u256, field: BlockHeaderField,
    ) -> Option<u256>;

    /// Returns block header field (e.g. block hash, state root or timestamp) of a block with a
    /// given block number on a given chain id.
    /// Reverts with "STORAGE_PROOF_HEADER_FIELD_NOT_SAVED" if the field is not saved.
    fn headerField(
        self: @TContractState, chain_id: u256, block_number: u256, field: BlockHeaderField,
    ) -> u256;

    /// Fetches account field (e.g. nonce, balance or storage root) of a given account, at a given
    /// block number on a given chain id.
    /// Returns Some(value) if the field is saved, None otherwise.
    fn accountFieldSafe(
        self: @TContractState,
        chain_id: u256,
        block_number: u256,
        account: EthAddress,
        field: AccountField,
    ) -> Option<u256>;

    /// Returns account field (e.g. nonce, balance or storage root) of a given account, at a given
    /// block number on a given chain id.
    /// Reverts with "STORAGE_PROOF_ACCOUNT_FIELD_NOT_SAVED" if the field is not saved.
    fn accountField(
        self: @TContractState,
        chain_id: u256,
        block_number: u256,
        account: EthAddress,
        field: AccountField,
    ) -> u256;

    /// Fetches value of a given storage slot of a given account, at a given block number on a given
    /// chain id.
    /// Returns Some(value) if the slot is saved, None otherwise.
    fn storageSlotSafe(
        self: @TContractState,
        chain_id: u256,
        block_number: u256,
        account: EthAddress,
        slot_index: u256,
    ) -> Option<u256>;

    /// Returns value of a given storage slot of a given account, at a given block number on a given
    /// chain id.
    /// Reverts with "STORAGE_PROOF_SLOT_NOT_SAVED" if the slot is not saved.
    fn storageSlot(
        self: @TContractState,
        chain_id: u256,
        block_number: u256,
        account: EthAddress,
        slot_index: u256,
    ) -> u256;

    /// Finds block number with a biggest timestamp that is less than or equal to the given
    /// timestamp.
    /// In other words, it answers what was the latest block at a given timestamp (including block
    /// with equal timestamp).
    /// Returns Some(block number) if the timestamp is saved, None otherwise.
    fn timestampSafe(self: @TContractState, chain_id: u256, timestamp: u256) -> Option<u256>;

    /// Returns block number with a biggest timestamp that is less than or equal to the given
    /// timestamp.
    /// In other words, it answers what was the latest block at a given timestamp (including block
    /// with equal timestamp).
    /// Reverts with "STORAGE_PROOF_TIMESTAMP_NOT_SAVED" if the timestamp is not saved.
    fn timestamp(self: @TContractState, chain_id: u256, timestamp: u256) -> u256;

    /// Fetches the ApeChain's share price at a given block number.
    /// Returns Some(share price) if the share price is saved for the given block number, None
    /// otherwise.
    /// Reverts with "STORAGE_PROOF_NOT_APECHAIN" if the given chain id does not support
    /// ApeChain-like account balances. TODO: add link
    fn getApechainSharePriceSafe(
        self: @TContractState, chain_id: u256, block_number: u256,
    ) -> Option<u256>;

    /// Returns the ApeChain's share price at a given block number.
    /// Reverts with "STORAGE_PROOF_SHARE_PRICE_NOT_SAVED" if the share price is not saved for the
    /// given block number.
    /// Reverts with "STORAGE_PROOF_NOT_APECHAIN" if the given chain id does not support
    /// ApeChain-like account balances. TODO: add link
    fn getApechainSharePrice(self: @TContractState, chain_id: u256, block_number: u256) -> u256;

    // ====================== Proving (Saves verified values) ===================== //

    /// Verifies the headerProof and saves selected fields in the satellite.
    /// Saved fields can be read with `headerFieldSafe` and `headerField` functions.
    /// headerFieldsToSave - Bitmask of fields to save. i-th bit corresponds to i-th field in
    /// `BlockHeaderField` enum.
    fn proveHeader(
        ref self: TContractState,
        chain_id: u256,
        header_fields_to_save: u16,
        header_proof: BlockHeaderProof,
    );

    /// Verifies the accountTrieProof and saves selected fields in the satellite.
    /// Saved fields can be read with `accountFieldSafe` and `accountField` functions.
    /// Requires desired block's STATE_ROOT to be proven first with `proveHeader` function.
    /// Additionally, if chainId is ApeChain and BALANCE bit is set, ApeChain's share price also has
    /// to be proven before calling this function.
    /// To prove share price, storage slot with index `APECHAIN_SHARE_PRICE_SLOT` of account
    /// `APECHAIN_SHARE_PRICE_ADDRESS` at desired block has to be proven first with `proveStorage`
    /// function.
    /// accountFieldsToSave - Bitmask of fields to save. First 4 bits correspond to NONCE, BALANCE,
    /// STORAGE_ROOT and CODE_HASH fields. Last bit (2^4) is responsible for all ApeChain fields,
    /// i.e. APE_FLAGS, APE_FIXED, APE_SHARES, APE_DEBT, APE_DELEGATE.
    fn proveAccount(
        ref self: TContractState,
        chain_id: u256,
        block_number: u256,
        account: EthAddress,
        account_fields_to_save: u8,
        account_trie_proof: Span<Words64>,
    );

    /// Verifies the storageSlotMptProof and saves the storage slot value in the satellite.
    /// Saved value can be read with `storageSlotSafe` and `storageSlot` functions.
    /// Requires account's STORAGE_ROOT to be proven first with `proveAccount` function.
    fn proveStorage(
        ref self: TContractState,
        chain_id: u256,
        block_number: u256,
        account: EthAddress,
        slot: u256,
        storage_slot_mpt_proof: Span<Words64>,
    );

    /// Verifies that block with number blockNumberLow is the latest block with timestamp less than
    /// or equal to the given timestamp.
    /// Requires timestamps of block with number blockNumberLow and blockNumberLow + 1 to be proven
    /// first with `proveHeader` function.
    fn proveTimestamp(
        ref self: TContractState, chain_id: u256, timestamp: u256, block_number_low: u256,
    );

    // ============ Verifying (Verifies that storage proof is correct) ============ //

    /// Verifies whether block header given by headerProof is present in MMR at given chain id,
    /// which means that it is a valid block.
    /// Returns array of block header fields.
    /// After successful verification, it can be assumed that block header with fields returned from
    /// this function is part of the chain with given chain id.
    /// Output span is guaranteed to have exactly 15 elements.
    fn verifyHeader(
        self: @TContractState, chain_id: u256, header_proof: BlockHeaderProof,
    ) -> Span<u256>;

    /// Verifies the accountMptProof against block's state root.
    /// Returns account fields.
    /// Reverts with "STORAGE_PROOF_SHOULD_BE_NON_APECHAIN" if the given chain id is ApeChain. (For
    /// ApeChain, use verifyOnlyAccountApechain instead)
    /// IMPORTANT: It DOES NOT check whether state root is valid given the chain id, block number
    /// and account address.
    /// To verify state root, use verifyHeader function.
    fn verifyOnlyAccount(
        self: @TContractState,
        chain_id: u256,
        account: EthAddress,
        state_root: u256,
        account_mpt_proof: Span<Words64>,
    ) -> (u256, u256, u256, u256);

    /// Verifies the accountMptProof and whether block given by headerProof is present in MMR at
    /// given chain id.
    /// Returns account fields.
    /// After successful verification, it can be assumed that account at given block number and
    /// chain id has field values returned from this function.
    fn verifyAccount(
        self: @TContractState,
        chain_id: u256,
        block_number: u256,
        account: EthAddress,
        header_proof: BlockHeaderProof,
        account_mpt_proof: Span<Words64>,
    ) -> (u256, u256, u256, u256);

    /// Verifies the accountMptProof against block's state root.
    /// Returns account fields.
    /// IMPORTANT: It DOES NOT check whether state root is valid given the chain id, block number
    /// and account address.
    /// To verify state root, use verifyHeader function.
    /// Reverts with "STORAGE_PROOF_SHOULD_BE_APECHAIN" if the given chain id is not ApeChain. (For
    /// non-ApeChain, use verifyOnlyAccount instead)
    fn verifyOnlyAccountApechain(
        self: @TContractState,
        chain_id: u256,
        account: EthAddress,
        state_root: u256,
        account_mpt_proof: Span<Words64>,
    ) -> (u256, u256, u256, u256, u256, u256, u256, u256);

    /// Verifies the accountMptProof and whether block given by headerProof is present in MMR at
    /// given chain id.
    /// Returns account fields.
    /// After successful verification, it can be assumed that account at given block number and
    /// chain id has field values returned from this function.
    fn verifyAccountApechain(
        self: @TContractState,
        chain_id: u256,
        block_number: u256,
        account: EthAddress,
        header_proof: BlockHeaderProof,
        account_mpt_proof: Span<Words64>,
    ) -> (u256, u256, u256, u256, u256, u256, u256, u256);

    /// Verifies the storageSlotMptProof against account's storage root.
    /// Returns storage slot value.
    /// IMPORTANT: It DOES NOT check whether storage root is valid given the chain id, block number,
    /// account address and slot index.
    /// To verify storage root, use verifyOnlyAccount function.
    fn verifyOnlyStorage(
        self: @TContractState,
        slot: u256,
        storage_root: u256,
        storage_slot_mpt_proof: Span<Words64>,
    ) -> u256;

    /// Verifies the storageSlotMptProof, accountMptProof and whether block given by headerProof is
    /// present in MMR at given chain id.
    /// Returns storage slot value.
    /// After successful verification, it can be assumed that given slot index of the account at
    /// block number and chain id has value returned from this function.
    fn verifyStorage(
        self: @TContractState,
        chain_id: u256,
        block_number: u256,
        account: EthAddress,
        slot: u256,
        header_proof: BlockHeaderProof,
        account_mpt_proof: Span<Words64>,
        storage_slot_mpt_proof: Span<Words64>,
    ) -> u256;

    /// Verifies that block with number blockNumberLow is the latest block with timestamp less than
    /// or equal to the given timestamp.
    /// IMPORTANT: It DOES NOT check if blockTimestampLow and High correspond to blockNumberLow and
    /// blockNumberLow + 1.
    /// Additionally, following has to be verified:
    /// - blockTimestampLow is the timestamp of block with number blockNumberLow -
    /// `headerField(chainId, blockNumberLow, BlockHeaderField.TIMESTAMP) == blockTimestampLow`
    /// - blockTimestampHigh is the timestamp of block with number blockNumberLow + 1 -
    /// `headerField(chainId, blockNumberLow + 1, BlockHeaderField.TIMESTAMP) == blockTimestampHigh`
    /// Both checks above can be done with `verifyHeader` (without needing to use additional storage
    /// in satellite contract).
    fn verifyOnlyTimestamp(
        self: @TContractState,
        timestamp: u256,
        block_number_low: u256,
        block_timestamp_low: u256,
        block_timestamp_high: u256,
    );

    /// Verifies that block with number blockNumberLow is the latest block with timestamp less than
    /// or equal to the given timestamp and that both header proofs are present in MMR.
    /// Returns block number.
    fn verifyTimestamp(
        self: @TContractState,
        chain_id: u256,
        timestamp: u256,
        header_proof_low: BlockHeaderProof,
        header_proof_high: BlockHeaderProof,
    ) -> u256;
}

#[starknet::interface]
pub trait IEvmFactRegistryInternal<TContractState> {
    fn _isApeChain(self: @TContractState, chain_id: u256) -> bool;

    fn _proveAccount(
        ref self: TContractState,
        chain_id: u256,
        block_number: u256,
        account: EthAddress,
        account_fields_to_save: u8,
        account_trie_proof: Span<Words64>,
    );

    fn _proveAccountApechain(
        ref self: TContractState,
        chain_id: u256,
        block_number: u256,
        account: EthAddress,
        account_fields_to_save: u8,
        account_trie_proof: Span<Words64>,
    );

    fn _readBlockHeaderFields(self: @TContractState, header_rlp: Words64) -> Span<u256>;

    fn _decodeAccount(
        self: @TContractState,
        state_root: u256,
        account: EthAddress,
        account_mpt_proof: Span<Words64>,
    ) -> Span<(Words64, usize)>;
}

#[starknet::component]
pub mod evm_fact_registry_component {
    use herodotus_starknet::{
        state::state_component, mmr_core::mmr_core_component,
        mmr_core::mmr_core_component::MmrCoreExternalImpl,
    };
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map,
    };
    use super::*;

    #[storage]
    struct Storage {
        // chain_id => address => block_number => Account
        account_fields: Map<u256, Map<EthAddress, Map<u256, Account>>>,
        // chain_id => address => block_number => slot => value
        account_storage_slot_values: Map<u256, Map<EthAddress, Map<u256, Map<u256, Option<u256>>>>>,
        // chain_id =>  timestamp => block_number
        timestamp_to_block_number: Map<u256, Map<u256, u256>>,
        // chain_id => block_number => block_header
        block_headers: Map<u256, Map<u256, BlockHeader>>,
    }

    #[derive(Drop, starknet::Event)]
    struct ProvenHeader {
        chain_id: u256,
        block_number: u256,
        saved_fields: u16,
    }

    #[derive(Drop, starknet::Event)]
    struct ProvenAccount {
        chain_id: u256,
        block_number: u256,
        account: EthAddress,
        saved_fields: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct ProvenStorage {
        chain_id: u256,
        block_number: u256,
        account: EthAddress,
        slot: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct ProvenTimestamp {
        chain_id: u256,
        timestamp: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ProvenHeader: ProvenHeader,
        ProvenAccount: ProvenAccount,
        ProvenStorage: ProvenStorage,
        ProvenTimestamp: ProvenTimestamp,
    }

    #[embeddable_as(EvmFactRegistry)]
    pub impl EvmFactRegistryImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl State: state_component::HasComponent<TContractState>,
        impl MmrCore: mmr_core_component::HasComponent<TContractState>,
    > of IEvmFactRegistry<ComponentState<TContractState>> {
        // =============== Functions for End Users (Reads proven values) ============== //

        // @inheritdoc IEVMFactsRegistry
        fn headerFieldSafe(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            block_number: u256,
            field: BlockHeaderField,
        ) -> Option<u256> {
            let header = self.block_headers.entry(chain_id).entry(block_number);

            let field_index = field.into();
            if header.saved_fields.read() & (2_u16.pow(field_index)) == 0 {
                Option::None
            } else {
                Option::Some(header.fields.entry(field_index).read())
            }
        }

        // @inheritdoc IEVMFactsRegistry
        fn headerField(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            block_number: u256,
            field: BlockHeaderField,
        ) -> u256 {
            self.headerFieldSafe(chain_id, block_number, field).expect('SP_HEADER_FIELD_NOT_SAVED')
        }

        // @inheritdoc IEVMFactsRegistry
        fn accountFieldSafe(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            block_number: u256,
            account: EthAddress,
            field: AccountField,
        ) -> Option<u256> {
            let mut field_index: u32 = field.into();
            if field_index > 4 {
                field_index = 4;
            }

            let account_data = self
                .account_fields
                .entry(chain_id)
                .entry(account)
                .entry(block_number);

            if account_data.saved_fields.read() & (2_u8.pow(field_index)) == 0 {
                Option::None
            } else {
                Option::Some(account_data.fields.entry(field_index).read())
            }
        }

        // @inheritdoc IEVMFactsRegistry
        fn accountField(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            block_number: u256,
            account: EthAddress,
            field: AccountField,
        ) -> u256 {
            self
                .accountFieldSafe(chain_id, block_number, account, field)
                .expect('SP_ACCOUNT_FIELD_NOT_SAVED')
        }

        // @inheritdoc IEVMFactsRegistry
        fn storageSlotSafe(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            block_number: u256,
            account: EthAddress,
            slot_index: u256,
        ) -> Option<u256> {
            self
                .account_storage_slot_values
                .entry(chain_id)
                .entry(account)
                .entry(block_number)
                .entry(slot_index)
                .read()
        }

        // @inheritdoc IEVMFactsRegistry
        fn storageSlot(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            block_number: u256,
            account: EthAddress,
            slot_index: u256,
        ) -> u256 {
            self
                .storageSlotSafe(chain_id, block_number, account, slot_index)
                .expect('SP_SLOT_NOT_SAVED')
        }

        // @inheritdoc IEVMFactsRegistry
        fn timestampSafe(
            self: @ComponentState<TContractState>, chain_id: u256, timestamp: u256,
        ) -> Option<u256> {
            let v = self.timestamp_to_block_number.entry(chain_id).entry(timestamp).read();
            if v == 0 {
                Option::None
            } else {
                Option::Some(v - 1)
            }
        }

        // @inheritdoc IEVMFactsRegistry
        fn timestamp(
            self: @ComponentState<TContractState>, chain_id: u256, timestamp: u256,
        ) -> u256 {
            self.timestampSafe(chain_id, timestamp).expect('SP_TIMESTAMP_NOT_SAVED')
        }

        // @inheritdoc IEVMFactsRegistry
        fn getApechainSharePriceSafe(
            self: @ComponentState<TContractState>, chain_id: u256, block_number: u256,
        ) -> Option<u256> {
            self
                .storageSlotSafe(
                    chain_id,
                    block_number,
                    APECHAIN_SHARE_PRICE_ADDRESS.try_into().unwrap(),
                    APECHAIN_SHARE_PRICE_SLOT,
                )
        }

        // @inheritdoc IEVMFactsRegistry
        fn getApechainSharePrice(
            self: @ComponentState<TContractState>, chain_id: u256, block_number: u256,
        ) -> u256 {
            self
                .getApechainSharePriceSafe(chain_id, block_number)
                .expect('SP_SHARE_PRICE_NOT_SAVED')
        }

        // ====================== Proving (Saves verified values) ===================== //

        // @inheritdoc IEVMFactsRegistry
        fn proveHeader(
            ref self: ComponentState<TContractState>,
            chain_id: u256,
            mut header_fields_to_save: u16,
            header_proof: BlockHeaderProof,
        ) {
            assert(
                header_fields_to_save / BLOCK_HEADER_2_POW_FIELD_COUNT == 0,
                'SP_INVALID_FIELDS_TO_SAVE',
            );
            assert(
                header_fields_to_save & ACCOUNT_FIELD_2_POW_LOGS_BLOOM == 0,
                'SP_LOGS_BLOOM_NOT_SUPPORTED',
            );
            // Block number is the key in the mapping, so it's pointless to save it.
            assert(
                header_fields_to_save & ACCOUNT_FIELD_2_POW_NUMBER == 0,
                'SP_BLOCK_NUMBER_NOT_SUPPORTED',
            );

            let mut fields = self.verifyHeader(chain_id, header_proof);
            let block_number = *fields[BlockHeaderField::NUMBER.into()];

            let header = self.block_headers.entry(chain_id).entry(block_number);

            let new_saved_fields = header.saved_fields.read()
                | header_fields_to_save; // Mark additional fields as saved
            header.saved_fields.write(new_saved_fields);

            for i in 0..BLOCK_HEADER_FIELD_COUNT {
                let value = *fields.pop_front().unwrap();
                if (header_fields_to_save & 1 == 1) {
                    header.fields.entry(i).write(value);
                }
                header_fields_to_save /= 2;
            };

            self
                .emit(
                    Event::ProvenHeader(
                        ProvenHeader { chain_id, block_number, saved_fields: new_saved_fields },
                    ),
                );
        }

        // @inheritdoc IEVMFactsRegistry
        fn proveAccount(
            ref self: ComponentState<TContractState>,
            chain_id: u256,
            block_number: u256,
            account: EthAddress,
            account_fields_to_save: u8,
            account_trie_proof: Span<Words64>,
        ) {
            if self._isApeChain(chain_id) {
                self
                    ._proveAccountApechain(
                        chain_id, block_number, account, account_fields_to_save, account_trie_proof,
                    );
            } else {
                self
                    ._proveAccount(
                        chain_id, block_number, account, account_fields_to_save, account_trie_proof,
                    );
            }
        }

        // @inheritdoc IEVMFactsRegistry
        fn proveStorage(
            ref self: ComponentState<TContractState>,
            chain_id: u256,
            block_number: u256,
            account: EthAddress,
            slot: u256,
            storage_slot_mpt_proof: Span<Words64>,
        ) {
            // Read proven storage root
            let storage_root = self
                .accountField(chain_id, block_number, account, AccountField::STORAGE_ROOT);

            // Verify the proof and decode the slot value
            let slot_value = self.verifyOnlyStorage(slot, storage_root, storage_slot_mpt_proof);

            // Save the slot value to the storage
            self
                .account_storage_slot_values
                .entry(chain_id)
                .entry(account)
                .entry(block_number)
                .entry(slot)
                .write(Option::Some(slot_value));

            self
                .emit(
                    Event::ProvenStorage(ProvenStorage { chain_id, block_number, account, slot }),
                );
        }

        // @inheritdoc IEVMFactsRegistry
        fn proveTimestamp(
            ref self: ComponentState<TContractState>,
            chain_id: u256,
            timestamp: u256,
            block_number_low: u256,
        ) {
            // Read proven timestamps
            let block_timestamp_low = self
                .headerField(chain_id, block_number_low, BlockHeaderField::TIMESTAMP);
            let block_timestamp_high = self
                .headerField(chain_id, block_number_low + 1, BlockHeaderField::TIMESTAMP);

            // Verify that blockNumberLow is the answer for given timestamp
            self
                .verifyOnlyTimestamp(
                    timestamp, block_number_low, block_timestamp_low, block_timestamp_high,
                );

            // blockNumber + 1 is stored, blockNumber cannot overflow because of check in
            self
                .timestamp_to_block_number
                .entry(chain_id)
                .entry(timestamp)
                .write(block_number_low + 1);

            self.emit(Event::ProvenTimestamp(ProvenTimestamp { chain_id, timestamp }));
        }

        // ============ Verifying (Verifies that storage proof is correct) ============ //

        // @inheritdoc IEVMFactsRegistry
        fn verifyHeader(
            self: @ComponentState<TContractState>, chain_id: u256, header_proof: BlockHeaderProof,
        ) -> Span<u256> {
            // Ensure provided header is a valid one by making sure it is present in saved MMRs

            let blockhash = hash_words64(header_proof.block_header_rlp);

            let mmr_core = get_dep_component!(self, MmrCore);
            let mmr_inclusion = mmr_core
                .verifyHistoricalMmrInclusion(
                    chain_id,
                    header_proof.mmr_id,
                    header_proof.mmr_size,
                    header_proof.mmr_leaf_index,
                    blockhash,
                    header_proof.mmr_proof,
                    header_proof.mmr_peaks,
                );
            assert(mmr_inclusion, 'INVALID_MMR_PROOF');

            // Decode the header fields

            self._readBlockHeaderFields(header_proof.block_header_rlp)
        }

        // @inheritdoc IEVMFactsRegistry
        fn verifyOnlyAccount(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            account: EthAddress,
            state_root: u256,
            account_mpt_proof: Span<Words64>,
        ) -> (u256, u256, u256, u256) {
            assert(!self._isApeChain(chain_id), 'SP_SHOULD_BE_NON_APECHAIN');

            let l = self._decodeAccount(state_root, account, account_mpt_proof);
            let (nonce_value, nonce_value_len) = *l.at(0);
            let (balance_value, balance_value_len) = *l.at(1);
            let (storage_hash_value, storage_hash_value_len) = *l.at(2);
            let (code_hash_value, code_hash_value_len) = *l.at(3);
            (
                nonce_value.as_u256_be(nonce_value_len).unwrap(),
                balance_value.as_u256_be(balance_value_len).unwrap(),
                storage_hash_value.as_u256_be(storage_hash_value_len).unwrap(),
                code_hash_value.as_u256_be(code_hash_value_len).unwrap(),
            )
        }

        // @inheritdoc IEVMFactsRegistry
        fn verifyAccount(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            block_number: u256,
            account: EthAddress,
            header_proof: BlockHeaderProof,
            account_mpt_proof: Span<Words64>,
        ) -> (u256, u256, u256, u256) {
            let header_fields = self.verifyHeader(chain_id, header_proof);

            assert(
                *header_fields[BlockHeaderField::NUMBER.into()] == block_number,
                'SP_BLOCK_NUMBER_NOT_MATCH',
            );
            let state_root = *header_fields[BlockHeaderField::STATE_ROOT.into()];

            self.verifyOnlyAccount(chain_id, account, state_root, account_mpt_proof)
        }

        // @inheritdoc IEVMFactsRegistry
        fn verifyOnlyAccountApechain(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            account: EthAddress,
            state_root: u256,
            account_mpt_proof: Span<Words64>,
        ) -> (u256, u256, u256, u256, u256, u256, u256, u256) {
            assert(self._isApeChain(chain_id), 'SP_SHOULD_BE_APECHAIN');

            let l = self._decodeAccount(state_root, account, account_mpt_proof);
            let (nonce_value, nonce_value_len) = *l.at(0);
            let (flags_value, flags_value_len) = *l.at(1);
            let (fixed_value, fixed_value_len) = *l.at(2);
            let (shares_value, shares_value_len) = *l.at(3);
            let (debt_value, debt_value_len) = *l.at(4);
            let (delegate_value, delegate_value_len) = *l.at(5);
            let (storage_root_value, storage_root_value_len) = *l.at(6);
            let (code_hash_value, code_hash_value_len) = *l.at(7);

            (
                nonce_value.as_u256_be(nonce_value_len).unwrap(),
                flags_value.as_u256_be(flags_value_len).unwrap(),
                fixed_value.as_u256_be(fixed_value_len).unwrap(),
                shares_value.as_u256_be(shares_value_len).unwrap(),
                debt_value.as_u256_be(debt_value_len).unwrap(),
                delegate_value.as_u256_be(delegate_value_len).unwrap(),
                storage_root_value.as_u256_be(storage_root_value_len).unwrap(),
                code_hash_value.as_u256_be(code_hash_value_len).unwrap(),
            )
        }

        // @inheritdoc IEVMFactsRegistry
        fn verifyAccountApechain(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            block_number: u256,
            account: EthAddress,
            header_proof: BlockHeaderProof,
            account_mpt_proof: Span<Words64>,
        ) -> (u256, u256, u256, u256, u256, u256, u256, u256) {
            let header_fields = self.verifyHeader(chain_id, header_proof);

            assert(
                *header_fields[BlockHeaderField::NUMBER.into()] == block_number,
                'SP_BLOCK_NUMBER_NOT_MATCH',
            );
            let state_root = *header_fields[BlockHeaderField::STATE_ROOT.into()];

            self.verifyOnlyAccountApechain(chain_id, account, state_root, account_mpt_proof)
        }

        // @inheritdoc IEVMFactsRegistry
        fn verifyOnlyStorage(
            self: @ComponentState<TContractState>,
            slot: u256,
            storage_root: u256,
            storage_slot_mpt_proof: Span<Words64>,
        ) -> u256 {
            // Split the slot into 4 64 bit words
            let word0_pow2 = 0x1000000000000000000000000000000000000000000000000;
            let word1_pow2 = 0x100000000000000000000000000000000;
            let word2_pow2 = 0x10000000000000000;
            let words = array![
                reverse_endianness_u64((slot / word0_pow2).try_into().unwrap(), Option::None),
                reverse_endianness_u64(
                    ((slot / word1_pow2) & 0xffffffffffffffff).try_into().unwrap(), Option::None,
                ),
                reverse_endianness_u64(
                    ((slot / word2_pow2) & 0xffffffffffffffff).try_into().unwrap(), Option::None,
                ),
                reverse_endianness_u64(
                    (slot & 0xffffffffffffffff).try_into().unwrap(), Option::None,
                ),
            ]
                .span();
            let key = reverse_endianness_u256(keccak_cairo_words64(words, 8));

            let mpt = MPTTrait::new(reverse_endianness_u256(storage_root));
            let rlp_value = mpt
                .verify(key, 64, storage_slot_mpt_proof)
                .expect('MPT_VERIFICATION_FAILED');

            if rlp_value.is_empty() {
                return 0;
            }

            let (item, _) = rlp_decode(rlp_value).expect('INVALID_RLP_VALUE');

            match item {
                RLPItem::Bytes((value, value_len)) => value
                    .as_u256_be(value_len)
                    .expect('INVALID_RLP_VALUE'),
                RLPItem::List(_) => panic!("INVALID_HEADER_RLP"),
            }
        }

        // @inheritdoc IEVMFactsRegistry
        fn verifyStorage(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            block_number: u256,
            account: EthAddress,
            slot: u256,
            header_proof: BlockHeaderProof,
            account_mpt_proof: Span<Words64>,
            storage_slot_mpt_proof: Span<Words64>,
        ) -> u256 {
            let storage_root = if self._isApeChain(chain_id) {
                let (_, _, _, _, _, _, _, storage_root) = self
                    .verifyAccountApechain(
                        chain_id, block_number, account, header_proof, account_mpt_proof,
                    );
                storage_root
            } else {
                let (_, _, _, storage_root) = self
                    .verifyAccount(
                        chain_id, block_number, account, header_proof, account_mpt_proof,
                    );
                storage_root
            };

            self.verifyOnlyStorage(slot, storage_root, storage_slot_mpt_proof)
        }

        // @inheritdoc IEVMFactsRegistry
        fn verifyOnlyTimestamp(
            self: @ComponentState<TContractState>,
            timestamp: u256,
            block_number_low: u256,
            block_timestamp_low: u256,
            block_timestamp_high: u256,
        ) {
            assert(block_number_low != Bounded::<u256>::MAX, 'SP_BLOCK_NUMBER_TOO_HIGH');
            assert(
                block_timestamp_low <= timestamp && timestamp < block_timestamp_high,
                'SP_TIMESTAMP_NOT_BETWEEN_BLOCKS',
            );
        }

        // @inheritdoc IEVMFactsRegistry
        fn verifyTimestamp(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            timestamp: u256,
            header_proof_low: BlockHeaderProof,
            header_proof_high: BlockHeaderProof,
        ) -> u256 {
            let header_fields_low = self.verifyHeader(chain_id, header_proof_low);
            let block_number_low = *header_fields_low[BlockHeaderField::NUMBER.into()];
            let block_timestamp_low = *header_fields_low[BlockHeaderField::TIMESTAMP.into()];

            let header_fields_high = self.verifyHeader(chain_id, header_proof_high);
            let block_number_high = *header_fields_high[BlockHeaderField::NUMBER.into()];
            let block_timestamp_high = *header_fields_high[BlockHeaderField::TIMESTAMP.into()];

            assert(block_number_low + 1 == block_number_high, 'SP_BLOCK_NUMBER_NOT_CONTINUOUS');

            self
                .verifyOnlyTimestamp(
                    timestamp, block_number_low, block_timestamp_low, block_timestamp_high,
                );

            block_number_low
        }
    }

    #[embeddable_as(EvmFactRegistryInternal)]
    pub impl EvmFactRegistryInternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl State: state_component::HasComponent<TContractState>,
        impl MmrCore: mmr_core_component::HasComponent<TContractState>,
    > of IEvmFactRegistryInternal<ComponentState<TContractState>> {
        fn _isApeChain(self: @ComponentState<TContractState>, chain_id: u256) -> bool {
            chain_id == 33111 || chain_id == 33139
        }

        fn _proveAccount(
            ref self: ComponentState<TContractState>,
            chain_id: u256,
            block_number: u256,
            account: EthAddress,
            mut account_fields_to_save: u8,
            account_trie_proof: Span<Words64>,
        ) {
            assert(
                account_fields_to_save / 0b10000 == 0, 'SP_INVALID_FIELDS_TO_SAVE',
            ); // Shift 4 bits to the right

            let account_data = self
                .account_fields
                .entry(chain_id)
                .entry(account)
                .entry(block_number);

            // Read proven state root
            let state_root = self.headerField(chain_id, block_number, BlockHeaderField::STATE_ROOT);

            // Verify the proof and decode the account fields
            let (nonce, balance, storage_root, code_hash) = self
                .verifyOnlyAccount(chain_id, account, state_root, account_trie_proof);

            // Save the desired account properties to the storage

            let new_saved_fields = account_fields_to_save | account_data.saved_fields.read();
            account_data.saved_fields.write(new_saved_fields);

            if account_fields_to_save & 1 != 0 { // AccountField::NONCE - 0
                account_data.fields.entry(AccountField::NONCE.into()).write(nonce);
            }
            account_fields_to_save /= 2;

            if account_fields_to_save & 1 != 0 { // AccountField::BALANCE - 1
                account_data.fields.entry(AccountField::BALANCE.into()).write(balance);
            }
            account_fields_to_save /= 2;

            if account_fields_to_save & 1 != 0 { // AccountField::STORAGE_ROOT - 2
                account_data.fields.entry(AccountField::STORAGE_ROOT.into()).write(storage_root);
            }
            account_fields_to_save /= 2;

            if account_fields_to_save & 1 != 0 { // AccountField::CODE_HASH - 3
                account_data.fields.entry(AccountField::CODE_HASH.into()).write(code_hash);
            }

            self
                .emit(
                    Event::ProvenAccount(
                        ProvenAccount {
                            chain_id, block_number, account, saved_fields: new_saved_fields,
                        },
                    ),
                );
        }

        fn _proveAccountApechain(
            ref self: ComponentState<TContractState>,
            chain_id: u256,
            block_number: u256,
            account: EthAddress,
            mut account_fields_to_save: u8,
            account_trie_proof: Span<Words64>,
        ) {
            assert(
                account_fields_to_save / 0b100000 == 0, 'SP_INVALID_FIELDS_TO_SAVE',
            ); // Shift 5 bits to the right

            let account_data = self
                .account_fields
                .entry(chain_id)
                .entry(account)
                .entry(block_number);

            // Read proven state root
            let state_root = self.headerField(chain_id, block_number, BlockHeaderField::STATE_ROOT);

            // Verify the proof and decode the account fields
            let (nonce, flags, fixed, shares, debt, delegate, storage_root, code_hash) = self
                .verifyOnlyAccountApechain(chain_id, account, state_root, account_trie_proof);

            // Save the desired account properties to the storage

            let new_saved_fields = account_fields_to_save | account_data.saved_fields.read();
            account_data.saved_fields.write(new_saved_fields);

            if account_fields_to_save & 1 != 0 { // AccountField::NONCE - 0
                account_data.fields.entry(AccountField::NONCE.into()).write(nonce);
            }
            account_fields_to_save /= 2;

            if account_fields_to_save & 1 != 0 { // AccountField::BALANCE - 1
                let share_price = self.getApechainSharePrice(chain_id, block_number);
                let balance = shares * share_price + fixed - debt;
                account_data.fields.entry(AccountField::BALANCE.into()).write(balance);
            }
            account_fields_to_save /= 2;

            if account_fields_to_save & 1 != 0 { // AccountField::STORAGE_ROOT - 2
                account_data.fields.entry(AccountField::STORAGE_ROOT.into()).write(storage_root);
            }
            account_fields_to_save /= 2;

            if account_fields_to_save & 1 != 0 { // AccountField::CODE_HASH - 3
                account_data.fields.entry(AccountField::CODE_HASH.into()).write(code_hash);
            }
            account_fields_to_save /= 2;

            // Bit 4 is for all ApeChain fields so either all ApeChain fields are saved or none
            if account_fields_to_save & 1 != 0 {
                account_data.fields.entry(AccountField::APE_FLAGS.into()).write(flags);
                account_data.fields.entry(AccountField::APE_FIXED.into()).write(fixed);
                account_data.fields.entry(AccountField::APE_SHARES.into()).write(shares);
                account_data.fields.entry(AccountField::APE_DEBT.into()).write(debt);
                account_data.fields.entry(AccountField::APE_DELEGATE.into()).write(delegate);
            }

            self
                .emit(
                    Event::ProvenAccount(
                        ProvenAccount {
                            chain_id, block_number, account, saved_fields: new_saved_fields,
                        },
                    ),
                );
        }

        // Returned Span is guaranteed to be 15 long.
        // Each element is value of i-th field in the block header,
        // except that 7-th element (index 6) is 0, because LOGS_BLOOM is not supported.
        fn _readBlockHeaderFields(
            self: @ComponentState<TContractState>, header_rlp: Words64,
        ) -> Span<u256> {
            let (decoded_rlp, _) = rlp_decode_list_lazy(
                header_rlp, [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14].span(),
            )
                .expect('INVALID_HEADER_RLP');

            let mut decoded_list = match decoded_rlp {
                RLPItem::Bytes(_) => panic!("INVALID_HEADER_RLP"),
                RLPItem::List(l) => l,
            };

            let mut output = ArrayTrait::new();
            loop {
                if output.len() == 6 {
                    output.append(0);
                }
                let (field_words, field_byte_len) = *decoded_list
                    .pop_front()
                    .expect('HEADER_RLP_DECODED_TOO_SHORT');

                output.append(field_words.as_u256_be(field_byte_len).unwrap());
                if output.len() == 15 {
                    break output.span();
                }
            }
        }

        fn _decodeAccount(
            self: @ComponentState<TContractState>,
            state_root: u256,
            account: EthAddress,
            account_mpt_proof: Span<Words64>,
        ) -> Span<(Words64, usize)> {
            let mpt = MPTTrait::new(reverse_endianness_u256(state_root));
            let account_u256: u256 = Into::<felt252>::into(account.into());

            // Split the address into 3 64 bit words
            let word0_pow2 = 0x1000000000000000000000000;
            let word1_pow2 = 0x100000000;
            let words = array![
                reverse_endianness_u64(
                    (account_u256 / word0_pow2).try_into().unwrap(), Option::None,
                ),
                reverse_endianness_u64(
                    ((account_u256 / word1_pow2) & 0xffffffffffffffff).try_into().unwrap(),
                    Option::None,
                ),
                reverse_endianness_u64(
                    (account_u256 & 0xffffffff).try_into().unwrap(), Option::Some(4),
                ),
            ]
                .span();
            let key = reverse_endianness_u256(keccak_cairo_words64(words, 4));

            let rlp_account = mpt
                .verify(key, 64, account_mpt_proof)
                .expect('MPT_VERIFICATION_FAILED');

            assert(!rlp_account.is_empty(), 'EMPTY_ACCOUNT_RLP');

            let (decoded_account, _) = rlp_decode(rlp_account).expect('INVALID_ACCOUNT_RLP');
            match decoded_account {
                RLPItem::Bytes(_) => panic!("INVALID_ACCOUNT_RLP"),
                RLPItem::List(l) => l,
            }
        }
    }
}
