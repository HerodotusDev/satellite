use cairo_lib::data_structures::mmr::mmr::{MMR, MMRImpl, MmrElement, MmrSize, Proof, Peaks};

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
    hashing_function: u256,
    root: u256,
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
        is_sibling_synced: bool,
    );

    fn _getInitialMmrRoot(self: @TContractState, hashing_function: u256) -> u256;
}

#[starknet::interface]
pub trait ICoreMmrExternal<TContractState> {
    fn get_mmr(self: @TContractState, chain_id: u256, mmr_id: u256) -> MMR;

    fn get_historical_root(self: @TContractState, chain_id: u256, mmr_id: u256, size: u256) -> u256;

    fn get_parent_hash(
        self: @TContractState, chain_id: u256, hashing_function: u256, block_number: u256,
    ) -> u256;

    fn verify_mmr_inclusion(
        self: @TContractState,
        chain_id: u256,
        mmr_id: u256,
        index: MmrSize,
        leaf_value: MmrElement,
        peaks: Peaks,
        proof: Proof,
    ) -> bool;

    fn verify_historical_mmr_inclusion(
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
    );
}

#[starknet::component]
pub mod mmr_core_component {
    use herodotus_starknet::state::state_component;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry};
    use super::*;

    #[storage]
    struct Storage {}

    #[derive(Drop, Serde)]
    enum CreatedFrom {
        FOREIGN,
        DOMESTIC,
    }

    #[derive(Drop, starknet::Event)]
    struct ReceivedParentHash {
        chain_id: u256,
        block_number: u256,
        parent_hash: u256,
        hashing_function: u256,
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
                            chain_id, block_number, parent_hash, hashing_function,
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
            is_sibling_synced: bool,
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
                mmr.is_sibling_synced.write(is_sibling_synced);
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
                        },
                    ),
                );
        }

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
        fn get_mmr(self: @ComponentState<TContractState>, chain_id: u256, mmr_id: u256) -> MMR {
            let state = get_dep_component!(self, State);
            let mmr = state.mmrs.entry(chain_id).entry(mmr_id).entry(POSEIDON_HASHING_FUNCTION);
            let size = mmr.latest_size.read();
            MMR {
                root: mmr.mmr_size_to_root.read(size).try_into().expect('ROOT_DOES_NOT_FIT'),
                last_pos: size,
            }
        }

        fn get_historical_root(
            self: @ComponentState<TContractState>, chain_id: u256, mmr_id: u256, size: u256,
        ) -> u256 {
            let state = get_dep_component!(self, State);
            let mmr = state.mmrs.entry(chain_id).entry(mmr_id).entry(POSEIDON_HASHING_FUNCTION);
            mmr.mmr_size_to_root.read(size)
        }

        fn get_parent_hash(
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

        fn verify_mmr_inclusion(
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

        fn verify_historical_mmr_inclusion(
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

        fn createMmrFromDomestic(
            ref self: ComponentState<TContractState>,
            new_mmr_id: u256,
            original_mmr_id: u256,
            accumulated_chain_id: u256,
            mut mmr_size: u256, // ignored when original_mmr_id is 0
            hashing_functions: Span<u256>,
        ) {
            assert(new_mmr_id != 0, 'NEW_MMR_ID_0_NOT_ALLOWED');
            assert(hashing_functions.len() != 0, 'INVALID_HASHING_FUNCTIONS_LEN');
            if original_mmr_id == 0 {
                mmr_size = 1;
            }

            let is_sibling_synced = hashing_functions.len() != 1;

            // TODO: is this right
            assert(!is_sibling_synced, 'SIBLING_SYNCED_NOT_SUPPORTED');

            let mut state = get_dep_component_mut!(ref self, State);
            let old_mmrs = state.mmrs.entry(accumulated_chain_id).entry(original_mmr_id);
            let mut new_mmrs = state.mmrs.entry(accumulated_chain_id).entry(new_mmr_id);
            let mut roots_for_hashing_functions = array![];

            for hashing_function in hashing_functions {
                assert(
                    new_mmrs.entry(*hashing_function).latest_size.read() == 0,
                    'NEW_MMR_ALREADY_EXISTS',
                );

                let root = if original_mmr_id == 0 {
                    self._getInitialMmrRoot(*hashing_function)
                } else {
                    let old_mmr = old_mmrs.entry(*hashing_function);
                    if is_sibling_synced {
                        assert(old_mmr.is_sibling_synced.read(), 'OLD_MMR_NOT_SYNCED');
                    }
                    old_mmr.mmr_size_to_root.read(mmr_size)
                };

                assert(root != 0, 'SRC_MMR_NOT_FOUND');

                let mut new_mmr = new_mmrs.entry(*hashing_function);
                new_mmr.latest_size.write(mmr_size);
                new_mmr.is_sibling_synced.write(is_sibling_synced);
                new_mmr.mmr_size_to_root.entry(mmr_size).write(root);
                roots_for_hashing_functions
                    .append(RootForHashingFunction { hashing_function: *hashing_function, root });
            };

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
                        },
                    ),
                );
        }
    }
}
