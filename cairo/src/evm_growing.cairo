use cairo_lib::data_structures::mmr::mmr::{MMR, MMRTrait, MmrSize};
use cairo_lib::data_structures::mmr::peaks::Peaks;
use cairo_lib::data_structures::mmr::proof::Proof;
use cairo_lib::hashing::keccak::keccak_cairo_words64;
use cairo_lib::hashing::poseidon::hash_words64;
use cairo_lib::utils::types::words64::Words64;

#[starknet::interface]
pub trait IEvmGrowing<TContractState> {
    fn onchainEvmAppendBlocksBatch(
        ref self: TContractState,
        chain_id: u256,
        headers_rlp: Span<Words64>,
        mmr_peaks: Peaks,
        mmr_id: u256,
        reference_block: Option<u256>,
        mmr_index: Option<MmrSize>,
        mmr_proof: Option<Proof>,
    );
}

#[starknet::component]
pub mod evm_growing_component {
    use starknet::storage::{StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess};
    use crate::mmr_core::{POSEIDON_HASHING_FUNCTION, RootForHashingFunction};
    use crate::state::state_component;
    use crate::utils::decoders::{decode_block_number, decode_parent_hash, decode_rlp};
    use crate::utils::header_rlp_index;
    use super::*;

    #[storage]
    struct Storage {}

    #[derive(Drop, Serde)]
    enum GrownBy {
        EvmOnChainGrowing,
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

    #[embeddable_as(EvmGrowing)]
    pub impl EvmGrowingImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl State: state_component::HasComponent<TContractState>,
    > of IEvmGrowing<ComponentState<TContractState>> {
        fn onchainEvmAppendBlocksBatch(
            ref self: ComponentState<TContractState>,
            chain_id: u256,
            mut headers_rlp: Span<Words64>,
            mmr_peaks: Peaks,
            mmr_id: u256,
            reference_block: Option<u256>,
            mmr_index: Option<MmrSize>,
            mmr_proof: Option<Proof>,
        ) {
            let mut state = get_dep_component_mut!(ref self, State);
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

            let headers_rlp_len = headers_rlp.len();
            let header_rlp_first = *headers_rlp.pop_front().unwrap();
            let poseidon_hash = hash_words64(header_rlp_first);
            let mut peaks = mmr_peaks;
            let mut start_block: u256 = 0;
            let mut end_block: u256 = 0;

            let mut previous_parent_hash: u256 = 0;

            if mmr_proof.is_some() {
                // Start from block that is present in different mmr
                // requires mmr_proof and mmr_index, reference_block to be None

                assert(reference_block.is_none(), 'PROOF_AND_REF_BLOCK_NOT_ALLOWED');
                assert(headers_rlp_len >= 2, 'INVALID_HEADER_RLP');

                let (d, _) = decode_rlp(
                    header_rlp_first,
                    [header_rlp_index::PARENT_HASH, header_rlp_index::BLOCK_NUMBER].span(),
                );
                previous_parent_hash = decode_parent_hash(*d.at(0));
                start_block = decode_block_number(*d.at(1)) - 1;

                mmr
                    .verify_proof(mmr_index.unwrap(), poseidon_hash, mmr_peaks, mmr_proof.unwrap())
                    .expect('INVALID_MMR_PROOF');

                end_block = (start_block + 2) - headers_rlp_len.into();
            } else {
                // Start from block for which we know the parent hash

                assert(headers_rlp_len >= 1, 'INVALID_HEADER_RLP');

                let (d, _) = decode_rlp(header_rlp_first, [header_rlp_index::PARENT_HASH].span());
                previous_parent_hash = decode_parent_hash(*d.at(0));

                let reference_block = reference_block.unwrap();
                start_block = reference_block - 1;
                end_block = (start_block + 1) - headers_rlp_len.into();

                let initial_blockhash = state
                    .received_parent_hashes
                    .entry(chain_id)
                    .entry(POSEIDON_HASHING_FUNCTION)
                    .entry(reference_block)
                    .read();

                assert(initial_blockhash != 0, 'BLOCK_NOT_RECEIVED');
                assert(initial_blockhash == poseidon_hash.into(), 'INVALID_INITIAL_HEADER_RLP');

                let (_, p) = mmr.append(poseidon_hash, mmr_peaks).expect('MMR_APPEND_FAILED');
                peaks = p;
            }

            for header_rlp in headers_rlp {
                let parent_hash = previous_parent_hash;

                let current_rlp = *header_rlp;

                let (d, last_word_byte_len) = decode_rlp(
                    current_rlp, [header_rlp_index::PARENT_HASH].span(),
                );
                previous_parent_hash = decode_parent_hash(*d.at(0));

                let current_hash = keccak_cairo_words64(current_rlp, last_word_byte_len);
                assert(current_hash == parent_hash, 'INVALID_HEADER_RLP');

                let poseidon_hash = hash_words64(current_rlp);

                let (_, p) = mmr.append(poseidon_hash, peaks).expect('MMR_APPEND_FAILED');
                peaks = p;
            }

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
                            grown_by: GrownBy::EvmOnChainGrowing,
                        },
                    ),
                );
        }
    }
}
