#[starknet::interface]
pub trait ICoreMmr<TContractState> { // fn read(self: @TContractState) -> felt252;
}

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
        newMmrId: u256,
        rootsForHashingFunctions: Span<RootForHashingFunction>,
        mmrSize: u256,
        accumulatedChainId: u256,
        originChainId: u256,
        originalMmrId: u256,
        isSiblingSynced: bool,
    );
}

#[starknet::component]
pub mod mmr_core_component {
    use herodotus_starknet::state::state_component;
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map,
    };
    use super::*;

    #[storage]
    struct Storage {}

    #[l1_handler]
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
        }

        fn _createMmrFromForeign(
            ref self: ComponentState<TContractState>,
            newMmrId: u256,
            rootsForHashingFunctions: Span<RootForHashingFunction>,
            mmrSize: u256,
            accumulatedChainId: u256,
            originChainId: u256,
            originalMmrId: u256,
            isSiblingSynced: bool,
        ) {}
    }
}
