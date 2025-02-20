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


type MmrId = u256;

#[derive(Drop, Serde)]
enum AccountField {
    Nonce,
    Balance,
    StorageHash,
    CodeHash,
}

impl AccountFieldIntoU32 of Into<AccountField, u32> {
    fn into(self: AccountField) -> u32 {
        match self {
            AccountField::Nonce => 0,
            AccountField::Balance => 1,
            AccountField::StorageHash => 2,
            AccountField::CodeHash => 3,
        }
    }
}

impl ConstSizeArrayToDynamicArray<T, +Drop<T>, +Copy<T>> of TryInto<Span<T>, [T; 4]> {
    fn try_into(self: Span<T>) -> Option<[T; 4]> {
        if self.len() != 4 {
            return Option::None;
        }
        Option::Some([*self[0], *self[1], *self[2], *self[3]])
    }
}

#[derive(Drop, Serde)]
struct BlockHeaderProof {
    mmr_id: MmrId,
    mmr_size: MmrSize, //! renamed
    block_number: u256, //! new
    leaf_index: MmrSize,
    mmr_peaks: Peaks,
    mmr_proof: Proof,
    block_header_rlp: Words64,
}

#[starknet::interface]
pub trait IEvmFactRegistry<TContractState> {
    // @notice Returns a proven account field values
    // @param account: The account to query
    // @param block: The block number
    // @param field: The field to query
    // @return The value of the field, if the field is not proven, returns None
    fn accountField(
        self: @TContractState,
        chain_id: u256,
        account: EthAddress,
        block_number: u256,
        field: AccountField,
    ) -> Option<u256>;

    // @notice Returns a proven storage slot value
    // @param account: The account to query
    // @param block: The block number
    // @param slot: The slot to query
    // @return The value of the slot, if the slot is not proven, returns None
    fn storageSlot(
        self: @TContractState,
        chain_id: u256,
        account: EthAddress,
        block_number: u256,
        slot_index: u256,
    ) -> Option<u256>;

    // @notice Gets an account from a block
    // @param block_header_rlp: The RLP of the block header
    // @param account: The account to query
    // @param mpt_proof: The MPT proof of the account
    // @param mmr_index: The index of the block in the MMR
    // @param mmr_peaks: The peaks of the MMR
    // @param mmr_proof: The proof of inclusion of the blockhash in the MMR
    // @param mmr_id: The id of the MMR
    // @param last_pos The size of the MMR for which the proof was generated
    // @return The values of the fields
    fn verifyAccount(
        self: @TContractState,
        chain_id: u256,
        account: EthAddress,
        header_proof: BlockHeaderProof,
        account_mpt_proof: Span<Words64>,
    ) -> [u256; 4];

    // @notice Gets a storage slot from a proven account
    // @dev The account storage hash must be proven
    // @param block: The block number
    // @param account: The account to query
    // @param slot: The slot to query
    fn verifyStorage(
        self: @TContractState,
        chain_id: u256,
        account: EthAddress,
        block_number: u256,
        slot_index: u256,
        slot_mpt_proof: Span<Words64>,
    ) -> u256;

    // @notice Proves an account at a given block
    // @dev The proven fields are written to storage and can later be used
    // @param fields: The fields to prove
    // @param block_header_rlp: The RLP of the block header
    // @param account: The account to prove
    // @param mpt_proof: The MPT proof of the account
    // @param mmr_index: The index of the block in the MMR
    // @param mmr_peaks: The peaks of the MMR
    // @param mmr_proof: The proof of inclusion of the blockhash in the MMR
    // @param mmr_id: The id of the MMR
    // @param last_pos The size of the MMR for which the proof was generated
    fn proveAccount(
        ref self: TContractState,
        chain_id: u256,
        account: EthAddress,
        account_fields_to_save: u8,
        header_proof: BlockHeaderProof,
        account_mpt_proof: Span<Words64>,
    );
    // @notice Proves a storage slot at a given block
    // @dev The proven slot is written to storage and can later be used
    // @dev The account storage hash must be proven
    // @param block: The block number
    // @param account: The account to prove
    // @param slot: The slot to prove
    // @param mpt_proof: The MPT proof of the slot (storage proof)
    fn proveStorage(
        ref self: TContractState,
        chain_id: u256,
        account: EthAddress,
        block_number: u256,
        slot_index: u256,
        slot_mpt_proof: Span<Words64>,
    );
}

#[starknet::component]
pub mod evm_fact_registry_component {
    use herodotus_starknet::{
        state::state_component, mmr_core::mmr_core_component,
        mmr_core::mmr_core_component::MmrCoreExternalImpl, utils::header_rlp_index,
    };
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map,
    };
    use super::*;

    #[storage]
    struct Storage {
        // chain_id => address => block_number => Account
        account_fields: Map<u256, Map<EthAddress, Map<u256, [Option<u256>; 4]>>>,
        // chain_id => address => block_number => slot => value
        account_storage_slot_values: Map<u256, Map<EthAddress, Map<u256, Map<u256, Option<u256>>>>>,
    }

    #[derive(Drop, starknet::Event)]
    struct ProvenAccount {
        chain_id: u256,
        account: EthAddress,
        block_number: u256,
        account_fields_to_save: u8,
        nonce: u256,
        balance: u256,
        code_hash: u256,
        storage_hash: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct ProvenStorage {
        chain_id: u256,
        account: EthAddress,
        block_number: u256,
        slot_index: u256,
        slot_value: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ProvenAccount: ProvenAccount,
        ProvenStorage: ProvenStorage,
    }

    #[embeddable_as(EvmFactRegistry)]
    impl EvmFactRegistryImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl State: state_component::HasComponent<TContractState>,
        impl MmrCore: mmr_core_component::HasComponent<TContractState>,
    > of IEvmFactRegistry<ComponentState<TContractState>> {
        // @inheritdoc IEVMFactsRegistry
        fn accountField(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            account: EthAddress,
            block_number: u256,
            field: AccountField,
        ) -> Option<u256> {
            *self
                .account_fields
                .entry(chain_id)
                .entry(account)
                .entry(block_number)
                .read()
                .span()
                .at(field.into())
        }

        // @inheritdoc IEVMFactRegistry
        fn storageSlot(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            account: EthAddress,
            block_number: u256,
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
        fn verifyAccount(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            account: EthAddress,
            header_proof: BlockHeaderProof,
            account_mpt_proof: Span<Words64>,
            // self: @ContractState,
        // fields: Span<AccountField>,
        // block_header_rlp: Words64,
        // account: felt252,
        // mpt_proof: Span<Words64>,
        // mmr_index: MmrSize,
        // mmr_peaks: Peaks,
        // mmr_proof: Proof,
        // mmr_id: MmrId,
        // last_pos: MmrSize,
        ) -> [u256; 4] {
            let blockhash = hash_words64(header_proof.block_header_rlp);

            let mmr_core = get_dep_component!(self, MmrCore);
            let mmr_inclusion = mmr_core
                .verifyHistoricalMmrInclusion(
                    chain_id,
                    header_proof.mmr_id,
                    header_proof.mmr_size,
                    header_proof.leaf_index,
                    blockhash,
                    header_proof.mmr_proof,
                    header_proof.mmr_peaks,
                );
            assert(mmr_inclusion, 'INVALID_MMR_PROOF');

            let (decoded_rlp, _) = rlp_decode_list_lazy(
                header_proof.block_header_rlp,
                [header_rlp_index::STATE_ROOT, header_rlp_index::BLOCK_NUMBER].span(),
            )
                .expect('INVALID_HEADER_RLP');
            let mut state_root: u256 = 0;
            let mut block_number: u256 = 0;
            match decoded_rlp {
                RLPItem::Bytes(_) => panic!("INVALID_HEADER_RLP"),
                RLPItem::List(l) => {
                    let (state_root_words, _) = *l.at(0);
                    state_root = state_root_words.as_u256_le().unwrap();

                    let (block_number_words, block_number_byte_len) = *l.at(1);
                    assert(block_number_words.len() == 1, 'INVALID_BLOCK_NUMBER');

                    let block_number_le = *block_number_words.at(0);
                    block_number =
                        reverse_endianness_u64(block_number_le, Option::Some(block_number_byte_len))
                        .into();
                },
            };
            assert(block_number == header_proof.block_number, 'Block number mismatch');

            let mpt = MPTTrait::new(state_root);
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

            // TODO: what to do in this case?
            assert(!rlp_account.is_empty(), 'TODO');

            let (decoded_account, _) = rlp_decode(rlp_account).expect('INVALID_ACCOUNT_RLP');
            match decoded_account {
                RLPItem::Bytes(_) => panic!("INVALID_ACCOUNT_RLP"),
                RLPItem::List(l) => {
                    let (nonce_value, nonce_value_len) = *l.at(0);
                    let (balance_value, balance_value_len) = *l.at(1);
                    let (storage_hash_value, storage_hash_value_len) = *l.at(2);
                    let (code_hash_value, code_hash_value_len) = *l.at(3);

                    [
                        nonce_value.as_u256_be(nonce_value_len).unwrap(),
                        balance_value.as_u256_be(balance_value_len).unwrap(),
                        storage_hash_value.as_u256_be(storage_hash_value_len).unwrap(),
                        code_hash_value.as_u256_be(code_hash_value_len).unwrap(),
                    ]
                },
            }
        }

        // @inheritdoc IEVMFactsRegistry
        fn verifyStorage(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            account: EthAddress,
            block_number: u256,
            slot_index: u256,
            slot_mpt_proof: Span<Words64>,
        ) -> u256 {
            let storage_hash = reverse_endianness_u256(
                (*self
                    .account_fields
                    .entry(chain_id)
                    .entry(account)
                    .entry(block_number)
                    .read()
                    .span()
                    .at(AccountField::StorageHash.into()))
                    .expect('STORAGE_HASH_NOT_PROVEN'),
            );

            // Split the slot into 4 64 bit words
            let word0_pow2 = 0x1000000000000000000000000000000000000000000000000;
            let word1_pow2 = 0x100000000000000000000000000000000;
            let word2_pow2 = 0x10000000000000000;
            let words = array![
                reverse_endianness_u64((slot_index / word0_pow2).try_into().unwrap(), Option::None),
                reverse_endianness_u64(
                    ((slot_index / word1_pow2) & 0xffffffffffffffff).try_into().unwrap(),
                    Option::None,
                ),
                reverse_endianness_u64(
                    ((slot_index / word2_pow2) & 0xffffffffffffffff).try_into().unwrap(),
                    Option::None,
                ),
                reverse_endianness_u64(
                    (slot_index & 0xffffffffffffffff).try_into().unwrap(), Option::None,
                ),
            ]
                .span();
            let key = reverse_endianness_u256(keccak_cairo_words64(words, 8));

            let mpt = MPTTrait::new(storage_hash);
            let rlp_value = mpt.verify(key, 64, slot_mpt_proof).expect('MPT_VERIFICATION_FAILED');

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
        fn proveAccount(
            ref self: ComponentState<TContractState>,
            // fields: Span<AccountField>,
            // block_header_rlp: Words64,
            // account: felt252,
            // mpt_proof: Span<Words64>,
            // mmr_index: MmrSize,
            // mmr_peaks: Peaks,
            // mmr_proof: Proof,
            // mmr_id: MmrId,
            // last_pos: MmrSize,
            chain_id: u256,
            account: EthAddress,
            mut account_fields_to_save: u8,
            header_proof: BlockHeaderProof,
            account_mpt_proof: Span<Words64>,
        ) {
            let block_number = header_proof.block_number;
            let mut entry = self.account_fields.entry(chain_id).entry(account).entry(block_number);

            let field_values = self
                .verifyAccount(chain_id, account, header_proof, account_mpt_proof);

            let mut old_account_fields = entry.read().span();
            let mut new_account_fields: Array<Option<u256>> = ArrayTrait::new();
            for field_value in field_values.span() { // guaranteed to be length 4
                let old_value = old_account_fields
                    .pop_front()
                    .unwrap(); // guaranteed to be length 4

                let (new_account_fields_to_save, should_save_field) = DivRem::div_rem(
                    account_fields_to_save, 2,
                );
                let value = if should_save_field == 1 {
                    Option::Some(*field_value)
                } else {
                    *old_value
                };
                new_account_fields.append(value);
                account_fields_to_save = new_account_fields_to_save;
            };
            entry.write(new_account_fields.span().try_into().unwrap());

            let [nonce, balance, code_hash, storage_hash] = field_values;
            self
                .emit(
                    Event::ProvenAccount(
                        ProvenAccount {
                            chain_id,
                            account,
                            block_number,
                            account_fields_to_save,
                            nonce,
                            balance,
                            code_hash,
                            storage_hash,
                        },
                    ),
                );
        }

        // @inheritdoc IEVMFactsRegistry
        fn proveStorage(
            ref self: ComponentState<TContractState>,
            chain_id: u256,
            account: EthAddress,
            block_number: u256,
            slot_index: u256,
            slot_mpt_proof: Span<Words64>,
        ) {
            let value = self
                .verifyStorage(chain_id, account, block_number, slot_index, slot_mpt_proof);

            self
                .account_storage_slot_values
                .entry(chain_id)
                .entry(account)
                .entry(block_number)
                .entry(slot_index)
                .write(Option::Some(value));

            self
                .emit(
                    Event::ProvenStorage(
                        ProvenStorage {
                            chain_id, account, block_number, slot_index, slot_value: value,
                        },
                    ),
                );
        }
    }
}

