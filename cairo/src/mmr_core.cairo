use cairo_lib::data_structures::mmr::mmr::{MMR, MMRImpl, MmrElement, MmrSize, Proof, Peaks};
use cairo_lib::utils::types::words64::Words64;

pub const POSEIDON_HASHING_FUNCTION: u256 =
    0xd3764378578a6e2b5a09713c3e8d5015a802d8de808c962ff5c53384ac7b1450;
pub const POSEIDON_INITIAL_ROOT: u256 =
    0x06759138078831011e3bc0b4a135af21c008dda64586363531697207fb5a2bae;
pub const KECCAK_HASHING_FUNCTION: u256 =
    0xdf35a135a69c769066bbb4d17b2fa3ec922c028d4e4bf9d0402e6f7c12b31813;
pub const KECCAK_INITIAL_ROOT: u256 =
    0x5d8d23518dd388daa16925ff9475c5d1c06430d21e0422520d6a56402f42937b;

#[derive(Drop, Serde)]
pub struct RootForHashingFunction {
    pub root: u256,
    pub hashing_function: u256,
}

#[starknet::interface]
pub trait ICoreMmrInternal<TContractState> {
    fn _receiveParentHash(
        ref self: TContractState,
        chain_id: u256,
        hashing_function: u256,
        block_number: u256,
        parent_hash: u256,
    );

    fn _createMmrFromForeign(
        ref self: TContractState,
        new_mmr_id: u256,
        roots_for_hashing_functions: Span<RootForHashingFunction>,
        mmr_size: u256,
        accumulated_chain_id: u256,
        origin_chain_id: u256,
        original_mmr_id: u256,
        is_offchain_grown: bool,
    );

    fn _getInitialMmrRoot(self: @TContractState, hashing_function: u256) -> u256;
}

#[starknet::interface]
pub trait ICoreMmrExternal<TContractState> {
    fn getMmr(self: @TContractState, chain_id: u256, mmr_id: u256) -> MMR;

    fn getHistoricalRoot(self: @TContractState, chain_id: u256, mmr_id: u256, size: u256) -> u256;

    fn getParentHash(
        self: @TContractState, chain_id: u256, hashing_function: u256, block_number: u256,
    ) -> u256;

    fn isMmrOnlyOffchainGrown(
        self: @TContractState,
        chain_id: u256,
        mmr_id: u256,
        hashing_function: u256,
    ) -> bool;

    fn verifyMmrInclusion(
        self: @TContractState,
        chain_id: u256,
        mmr_id: u256,
        index: MmrSize,
        leaf_value: MmrElement,
        peaks: Peaks,
        proof: Proof,
    ) -> bool;

    fn verifyHistoricalMmrInclusion(
        self: @TContractState,
        chain_id: u256,
        mmr_id: u256,
        mmr_size: MmrSize,
        index: MmrSize,
        leaf_value: MmrElement,
        proof: Proof,
        peaks: Peaks,
    ) -> bool;

    fn createMmrFromDomestic(
        ref self: TContractState,
        new_mmr_id: u256,
        original_mmr_id: u256,
        accumulated_chain_id: u256,
        mmr_size: u256, // ignored when original_mmr_id is 0
        hashing_functions: Span<u256>,
        is_offchain_grown: bool,
    );

    fn translateParentHashFunction(
        ref self: TContractState, chain_id: u256, block_number: u256, header_rlp: Words64,
    );
}

#[starknet::component]
pub mod mmr_core_component {
    use herodotus_starknet::state::state_component;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry};
    use cairo_lib::{
        utils::bitwise::reverse_endianness_u256, hashing::keccak::keccak_cairo_words64,
        encoding::rlp::rlp_decode_list_lazy, hashing::poseidon::hash_words64,
    };
    use super::*;

    #[storage]
    struct Storage {}

    #[derive(Drop, Serde)]
    enum ReceivedFrom {
        MESSAGE,
        TRANSLATION,
    }

    #[derive(Drop, starknet::Event)]
    struct ReceivedParentHash {
        chain_id: u256,
        block_number: u256,
        parent_hash: u256,
        hashing_function: u256,
        received_from: ReceivedFrom,
    }

    #[derive(Drop, Serde)]
    enum CreatedFrom {
        FOREIGN,
        DOMESTIC,
    }

    #[derive(Drop, starknet::Event)]
    struct CreatedMmr {
        new_mmr_id: u256,
        mmr_size: u256,
        accumulated_chain_id: u256,
        original_mmr_id: u256,
        roots_for_hashing_functions: Span<RootForHashingFunction>,
        origin_chain_id: u256,
        created_from: CreatedFrom,
        is_offchain_grown: bool,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ReceivedParentHash: ReceivedParentHash,
        CreatedMmr: CreatedMmr,
    }

    #[embeddable_as(MmrCoreInternal)]
    pub impl MmrCoreInternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl State: state_component::HasComponent<TContractState>,
    > of ICoreMmrInternal<ComponentState<TContractState>> {
        // ========================= Other Satellite Modules Only Functions ========================= //

        fn _receiveParentHash(
            ref self: ComponentState<TContractState>,
            chain_id: u256,
            hashing_function: u256,
            block_number: u256,
            parent_hash: u256,
        ) {
            let mut state = get_dep_component_mut!(ref self, State);
            state
                .received_parent_hashes
                .entry(chain_id)
                .entry(hashing_function)
                .entry(block_number)
                .write(parent_hash);

            self
                .emit(
                    Event::ReceivedParentHash(
                        ReceivedParentHash {
                            chain_id,
                            block_number,
                            parent_hash,
                            hashing_function,
                            received_from: ReceivedFrom::MESSAGE,
                        },
                    ),
                );
        }

        fn _createMmrFromForeign(
            ref self: ComponentState<TContractState>,
            new_mmr_id: u256,
            roots_for_hashing_functions: Span<RootForHashingFunction>,
            mmr_size: u256,
            accumulated_chain_id: u256,
            origin_chain_id: u256,
            original_mmr_id: u256,
            is_offchain_grown: bool,
        ) {
            assert(new_mmr_id != 0, 'NEW_MMR_ID_0_NOT_ALLOWED');
            assert(roots_for_hashing_functions.len() != 0, 'INVALID_ROOTS_LENGTH');

            let mut state = get_dep_component_mut!(ref self, State);
            for r in roots_for_hashing_functions {
                assert(*r.root != 0, 'ROOT_0_NOT_ALLOWED');

                let mut mmr = state
                    .mmrs
                    .entry(accumulated_chain_id)
                    .entry(new_mmr_id)
                    .entry(*r.hashing_function);

                assert(mmr.latest_size.read() == 0, 'NEW_MMR_ALREADY_EXISTS');
                mmr.latest_size.write(mmr_size);
                mmr.is_offchain_grown.write(is_offchain_grown);
                mmr.mmr_size_to_root.entry(mmr_size).write(*r.root);
            };

            self
                .emit(
                    Event::CreatedMmr(
                        CreatedMmr {
                            new_mmr_id,
                            mmr_size,
                            accumulated_chain_id,
                            original_mmr_id,
                            roots_for_hashing_functions,
                            origin_chain_id,
                            created_from: CreatedFrom::FOREIGN,
                            is_offchain_grown,
                        },
                    ),
                );
        }

        // ========================= Internal functions ========================= //

        fn _getInitialMmrRoot(
            self: @ComponentState<TContractState>, hashing_function: u256,
        ) -> u256 {
            if hashing_function == POSEIDON_HASHING_FUNCTION {
                POSEIDON_INITIAL_ROOT
            } else if hashing_function == KECCAK_HASHING_FUNCTION {
                KECCAK_INITIAL_ROOT
            } else {
                panic!("INVALID_HASHING_FUNCTION");
                0
            }
        }
    }

    #[embeddable_as(MmrCoreExternal)]
    pub impl MmrCoreExternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl State: state_component::HasComponent<TContractState>,
    > of ICoreMmrExternal<ComponentState<TContractState>> {
        // ========================= Core Functions ========================= //

        fn createMmrFromDomestic(
            ref self: ComponentState<TContractState>,
            new_mmr_id: u256,
            original_mmr_id: u256,
            accumulated_chain_id: u256,
            mut mmr_size: u256, // ignored when original_mmr_id is 0
            hashing_functions: Span<u256>,
            is_offchain_grown: bool,
        ) {
            assert(new_mmr_id != 0, 'NEW_MMR_ID_0_NOT_ALLOWED');
            assert(hashing_functions.len() != 0, 'INVALID_HASHING_FUNCTIONS_LEN');
            if original_mmr_id == 0 {
                // Create an empty MMR
                mmr_size = 1;
            }

            let mut state = get_dep_component_mut!(ref self, State);

            let original_mmrs = state.mmrs.entry(accumulated_chain_id).entry(original_mmr_id);
            let mut new_mmrs = state.mmrs.entry(accumulated_chain_id).entry(new_mmr_id);

            let common_is_offchain_grown = original_mmrs.entry(*hashing_functions.at(0)).is_offchain_grown.read();
            let mut roots_for_hashing_functions = array![];

            for hashing_function in hashing_functions {
                assert(
                    new_mmrs.entry(*hashing_function).latest_size.read() == 0,
                    'NEW_MMR_ALREADY_EXISTS',
                );

                let root = if original_mmr_id == 0 {
                    // Create an empty MMR
                    self._getInitialMmrRoot(*hashing_function)
                } else {
                    // Load existing MMR data
                    let original_mmr = original_mmrs.entry(*hashing_function);

                    let mmr_root = original_mmr.mmr_size_to_root.read(mmr_size);
                    
                    // Ensure the given MMR exists
                    assert(mmr_root != 0, 'SRC_MMR_NOT_FOUND');

                    // Ensure the given MMR has the same isOffchainGrown value
                    assert(original_mmr.is_offchain_grown.read() == common_is_offchain_grown, 'IS_OFFCHAIN_GROWN_MISMATCH');

                    mmr_root
                };

                // Copy the MMR data to the new MMR
                let mut new_mmr = new_mmrs.entry(*hashing_function);
                new_mmr.latest_size.write(mmr_size);
                new_mmr.is_offchain_grown.write(common_is_offchain_grown);
                new_mmr.mmr_size_to_root.entry(mmr_size).write(root);
                roots_for_hashing_functions
                    .append(RootForHashingFunction { hashing_function: *hashing_function, root });
            };
    
            // Offchain growing can only be turned off, not on
            if original_mmr_id != 0 && is_offchain_grown == true {
                assert(common_is_offchain_grown == true, 'CANT_TURN_ON_OFFCHAIN_GROWING');
            }

            self
                .emit(
                    Event::CreatedMmr(
                        CreatedMmr {
                            new_mmr_id,
                            mmr_size,
                            accumulated_chain_id,
                            original_mmr_id,
                            roots_for_hashing_functions: roots_for_hashing_functions.span(),
                            origin_chain_id: state.chain_id.read(),
                            created_from: CreatedFrom::DOMESTIC,
                            is_offchain_grown,
                        },
                    ),
                );
        }

        // ========================= View functions ========================= //

        fn getMmr(self: @ComponentState<TContractState>, chain_id: u256, mmr_id: u256) -> MMR {
            let state = get_dep_component!(self, State);
            let mmr = state.mmrs.entry(chain_id).entry(mmr_id).entry(POSEIDON_HASHING_FUNCTION);
            let size = mmr.latest_size.read();
            MMR {
                root: mmr.mmr_size_to_root.read(size).try_into().expect('ROOT_DOES_NOT_FIT'),
                last_pos: size,
            }
        }

        fn getHistoricalRoot(
            self: @ComponentState<TContractState>, chain_id: u256, mmr_id: u256, size: u256,
        ) -> u256 {
            let state = get_dep_component!(self, State);
            let mmr = state.mmrs.entry(chain_id).entry(mmr_id).entry(POSEIDON_HASHING_FUNCTION);
            mmr.mmr_size_to_root.read(size)
        }

        fn getParentHash(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            hashing_function: u256,
            block_number: u256,
        ) -> u256 {
            let state = get_dep_component!(self, State);
            state
                .received_parent_hashes
                .entry(chain_id)
                .entry(hashing_function)
                .entry(block_number)
                .read()
        }

        fn isMmrOnlyOffchainGrown(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            mmr_id: u256,
            hashing_function: u256,
        ) -> bool {
            let state = get_dep_component!(self, State);
            state.mmrs.entry(chain_id).entry(mmr_id).entry(hashing_function).is_offchain_grown.read()
        }

        fn verifyMmrInclusion(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            mmr_id: u256,
            index: u256,
            leaf_value: MmrElement,
            peaks: Peaks,
            proof: Proof,
        ) -> bool {
            let state = get_dep_component!(self, State);

            let mmr_state = state
                .mmrs
                .entry(chain_id)
                .entry(mmr_id)
                .entry(POSEIDON_HASHING_FUNCTION);

            let mmr_size = mmr_state.latest_size.read();

            let root = mmr_state
                .mmr_size_to_root
                .read(mmr_size)
                .try_into()
                .expect('ROOT_DOES_NOT_FIT');

            let mmr = MMR { root, last_pos: mmr_size };
            mmr.verify_proof(index, leaf_value, peaks, proof).is_ok()
        }

        fn verifyHistoricalMmrInclusion(
            self: @ComponentState<TContractState>,
            chain_id: u256,
            mmr_id: u256,
            mmr_size: MmrSize,
            index: MmrSize,
            leaf_value: MmrElement,
            proof: Proof,
            peaks: Peaks,
        ) -> bool {
            let state = get_dep_component!(self, State);
            let mmr_state = state
                .mmrs
                .entry(chain_id)
                .entry(mmr_id)
                .entry(POSEIDON_HASHING_FUNCTION);

            let root = mmr_state
                .mmr_size_to_root
                .read(mmr_size)
                .try_into()
                .expect('ROOT_DOES_NOT_FIT');

            let mmr = MMR { root, last_pos: mmr_size };
            mmr.verify_proof(index, leaf_value, peaks, proof).is_ok()
        }

        fn translateParentHashFunction(
            ref self: ComponentState<TContractState>,
            chain_id: u256,
            block_number: u256,
            header_rlp: Words64,
        ) {
            let mut state = get_dep_component_mut!(ref self, State);

            let (_, byte_len) = rlp_decode_list_lazy(header_rlp, [].span())
                .expect('ERR_DECODE_RLP_LIST');

            let mut last_word_byte_len = byte_len % 8;
            if last_word_byte_len == 0 {
                last_word_byte_len = 8;
            }

            let rlp_keccak_hash = reverse_endianness_u256(
                keccak_cairo_words64(header_rlp, last_word_byte_len),
            );

            let rlp_poseidon_hash: u256 = hash_words64(header_rlp).into();

            let receive_parent_hashes_chain = state.received_parent_hashes.entry(chain_id);

            let saved_keccak_hash = receive_parent_hashes_chain
                .entry(KECCAK_HASHING_FUNCTION)
                .entry(block_number)
                .read();

            assert(saved_keccak_hash != 0, 'KECCAK_HASH_NOT_SAVED');
            assert(saved_keccak_hash == rlp_keccak_hash, 'KECCAK_HASH_MISMATCH');

            receive_parent_hashes_chain
                .entry(POSEIDON_HASHING_FUNCTION)
                .entry(block_number)
                .write(rlp_poseidon_hash);

            self
                .emit(
                    Event::ReceivedParentHash(
                        ReceivedParentHash {
                            chain_id,
                            block_number,
                            parent_hash: rlp_poseidon_hash,
                            hashing_function: POSEIDON_HASHING_FUNCTION,
                            received_from: ReceivedFrom::TRANSLATION,
                        },
                    ),
                );
        }
    }
}
