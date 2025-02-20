use cairo_lib::{
    data_structures::{mmr::{mmr::{MMR, MMRTrait, MmrSize}, peaks::Peaks, proof::Proof}},
    utils::{types::words64::{Words64, Words64Trait, reverse_endianness_u64}},
};
use cairo_lib::hashing::keccak::keccak_cairo_words64;
use cairo_lib::hashing::poseidon::hash_words64;
use cairo_lib::utils::bitwise::reverse_endianness_u256;
use cairo_lib::encoding::rlp::{RLPItem, rlp_decode_list_lazy};

#[starknet::interface]
pub trait IOnChainGrowing<TContractState> {
    fn onchainStarknetAppendBlocksBatch(
        ref self: TContractState,
        headers_rlp: Span<Words64>,
        mmr_peaks: Peaks,
        mmr_id: u256,
        reference_block: Option<u256>,
        mmr_index: Option<MmrSize>,
        mmr_proof: Option<Proof>,
    );
}

#[starknet::component]
pub mod on_chain_growing_component {
    use herodotus_starknet::{
        state::state_component,
        mmr_core::{POSEIDON_HASHING_FUNCTION, KECCAK_HASHING_FUNCTION, RootForHashingFunction},
        utils::header_rlp_index,
    };
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry};
    use super::*;

    #[storage]
    struct Storage {}

    #[derive(Drop, Serde)]
    enum GrownBy {
        StarknetOnChainGrowing,
    }

    #[derive(Drop, starknet::Event)]
    struct GrownMmr {
        first_appended_block: u256,
        last_appended_block: u256,
        roots_for_hashing_functions: Span<RootForHashingFunction>,
        mmr_size: u256,
        mmr_id: u256,
        accumulated_chain_id: u256,
        grown_by: GrownBy,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        GrownMmr: GrownMmr,
    }

    #[embeddable_as(OnChainGrowing)]
    pub impl OnChainGrowingImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl State: state_component::HasComponent<TContractState>,
    > of IOnChainGrowing<ComponentState<TContractState>> {
        fn onchainStarknetAppendBlocksBatch(
            ref self: ComponentState<TContractState>,
            headers_rlp: Span<Words64>,
            mmr_peaks: Peaks,
            mmr_id: u256,
            reference_block: Option<u256>,
            mmr_index: Option<MmrSize>,
            mmr_proof: Option<Proof>,
        ) {
            let mut state = get_dep_component_mut!(ref self, State);
            let chain_id = state.chain_id.read();
            let mut mmr_data = state
                .mmrs
                .entry(chain_id)
                .entry(mmr_id)
                .entry(POSEIDON_HASHING_FUNCTION);

            let mmr_size = mmr_data.latest_size.read();
            let mut mmr = MMR {
                last_pos: mmr_size,
                root: mmr_data
                    .mmr_size_to_root
                    .read(mmr_size)
                    .try_into()
                    .expect('ROOT_DOES_NOT_FIT'),
            };
            assert(mmr.root != 0, 'SRC_MMR_NOT_FOUND');
            let poseidon_hash = hash_words64(*headers_rlp.at(0));
            let mut peaks = mmr_peaks;
            let mut start_block: u256 = 0;
            let mut end_block: u256 = 0;

            let mut decoded_rlp = RLPItem::Bytes((array![].span(), 0));
            let mut rlp_byte_len = 0;

            if mmr_proof.is_some() {
                // Start from block that is present in different mmr
                // requires mmr_proof and mmr_index, reference_block to be None

                assert(reference_block.is_none(), 'PROOF_AND_REF_BLOCK_NOT_ALLOWED');
                assert(headers_rlp.len() >= 2, 'INVALID_HEADER_RLP');

                match rlp_decode_list_lazy(
                    *headers_rlp.at(0),
                    [header_rlp_index::PARENT_HASH, header_rlp_index::BLOCK_NUMBER].span(),
                ) {
                    Result::Ok((d, d_l)) => {
                        decoded_rlp = d;
                        rlp_byte_len = d_l;
                    },
                    Result::Err(_) => { panic!("INVALID_HEADER_RLP"); },
                };

                mmr
                    .verify_proof(mmr_index.unwrap(), poseidon_hash, mmr_peaks, mmr_proof.unwrap())
                    .expect('INVALID_MMR_PROOF');

                match @decoded_rlp {
                    RLPItem::Bytes(_) => panic!("INVALID_HEADER_RLP"),
                    RLPItem::List(l) => {
                        let (start_block_words, start_block_byte_len) = *(*l).at(1);
                        assert(start_block_words.len() == 1, 'INVALID_START_BLOCK');

                        let start_block_le = *start_block_words.at(0);
                        start_block =
                            reverse_endianness_u64(
                                start_block_le, Option::Some(start_block_byte_len),
                            )
                            .into()
                            - 1;

                        end_block = (start_block + 2) - headers_rlp.len().into();
                    },
                };
            } else {
                // Start from block for which we know the parent hash

                assert(headers_rlp.len() >= 1, 'INVALID_HEADER_RLP');

                match rlp_decode_list_lazy(
                    *headers_rlp.at(0), [header_rlp_index::PARENT_HASH].span(),
                ) {
                    Result::Ok((d, d_l)) => {
                        decoded_rlp = d;
                        rlp_byte_len = d_l;
                    },
                    Result::Err(_) => { panic!("INVALID_HEADER_RLP"); },
                };

                let reference_block = reference_block.unwrap();
                start_block = reference_block - 1;
                end_block = (start_block + 1) - headers_rlp.len().into();

                let initial_blockhash = state
                    .received_parent_hashes
                    .entry(chain_id)
                    .entry(KECCAK_HASHING_FUNCTION) //! changed to keccak
                    .entry(reference_block)
                    .read();
                assert(initial_blockhash != 0, 'BLOCK_NOT_RECEIVED');

                let mut last_word_byte_len = rlp_byte_len % 8;
                if last_word_byte_len == 0 {
                    last_word_byte_len = 8;
                }
                let rlp_hash = InternalFunctions::keccak_hash_rlp(
                    *headers_rlp.at(0), last_word_byte_len, true,
                );
                assert(rlp_hash == initial_blockhash, 'INVALID_INITIAL_HEADER_RLP');

                let (_, p) = mmr.append(poseidon_hash, mmr_peaks).expect('MMR_APPEND_FAILED');
                peaks = p;
            }

            let mut i: usize = 1;
            loop {
                if i == headers_rlp.len() {
                    break ();
                }

                let parent_hash: u256 = match decoded_rlp {
                    RLPItem::Bytes(_) => panic!("INVALID_HEADER_RLP"),
                    RLPItem::List(l) => {
                        let (words, words_byte_len) = *l.at(0);
                        assert(words.len() == 4 && words_byte_len == 32, 'INVALID_PARENT_HASH_RLP');
                        words.as_u256_le().unwrap()
                    },
                };

                let current_rlp = *headers_rlp.at(i);

                match rlp_decode_list_lazy(current_rlp, [header_rlp_index::PARENT_HASH].span()) {
                    Result::Ok((d, d_l)) => {
                        decoded_rlp = d;
                        rlp_byte_len = d_l;
                    },
                    Result::Err(_) => { panic!("INVALID_HEADER_RLP"); },
                };

                let mut last_word_byte_len = rlp_byte_len % 8;
                if last_word_byte_len == 0 {
                    last_word_byte_len = 8;
                }
                let current_hash = InternalFunctions::keccak_hash_rlp(
                    current_rlp, last_word_byte_len, false,
                );
                assert(current_hash == parent_hash, 'INVALID_HEADER_RLP');

                let poseidon_hash = hash_words64(current_rlp);

                let (_, p) = mmr.append(poseidon_hash, peaks).expect('MMR_APPEND_FAILED');
                peaks = p;

                i += 1;
            };

            mmr_data.mmr_size_to_root.write(mmr.last_pos, mmr.root.into());
            mmr_data.latest_size.write(mmr.last_pos);

            self
                .emit(
                    Event::GrownMmr(
                        GrownMmr {
                            first_appended_block: start_block,
                            last_appended_block: end_block,
                            roots_for_hashing_functions: [
                                RootForHashingFunction {
                                    hashing_function: POSEIDON_HASHING_FUNCTION,
                                    root: mmr.root.into(),
                                }
                            ]
                                .span(),
                            mmr_size: mmr.last_pos,
                            mmr_id,
                            accumulated_chain_id: chain_id,
                            grown_by: GrownBy::StarknetOnChainGrowing,
                        },
                    ),
                );
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        // @notice Hashes RLP-encoded header
        // @param rlp RLP-encoded header
        // @param last_word_bytes Number of bytes in the last word
        // @param big_endian Whether to reverse endianness of the hash
        // @return Hash of the header
        fn keccak_hash_rlp(rlp: Words64, last_word_bytes: usize, big_endian: bool) -> u256 {
            let mut hash = keccak_cairo_words64(rlp, last_word_bytes);
            if big_endian {
                reverse_endianness_u256(hash)
            } else {
                hash
            }
        }
    }
}
