pub trait IReceiver {
    fn setL1MessageSender(
        l1_address: felt252,
    );
}

#[starknet::contract]
pub mod HerodotusStarknet {
    use herodotus_starknet::{
        evm_fact_registry::evm_fact_registry_component, mmr_core::mmr_core_component,
        state::state_component,
    };
    use herodotus_starknet::mmr_core::RootForHashingFunction;

    component!(path: state_component, storage: state, event: StateEvent);
    component!(
        path: evm_fact_registry_component, storage: evm_fact_registry, event: EvmFactRegistryEvent,
    );
    component!(path: mmr_core_component, storage: mmr_core, event: MmrCoreEvent);

    #[storage]
    struct Storage {
        l1_message_sender: felt252,
        #[substorage(v0)]
        state: state_component::Storage,
        #[substorage(v0)]
        evm_fact_registry: evm_fact_registry_component::Storage,
        #[substorage(v0)]
        mmr_core: mmr_core_component::Storage,
    }

    #[l1_handler]
    fn receiveParentHash(
        ref self: ContractState,
        from_address: felt252,
        chainId: u256,
        hashingFunction: u256,
        blockNumber: u256,
        parentHash: u256,
    ) {
        assert(from_address == self.l1_message_sender.read(), 'ONLY_L1_MESSAGE_SENDER');
        self._receiveParentHash(chainId, hashingFunction, blockNumber, parentHash);
    }

    #[l1_handler]
    fn receive_mmr(
        ref self: ContractState,
        from_address: felt252,
        newMmrId: u256,
        rootsForHashingFunctions: Span<RootForHashingFunction>,
        mmrSize: u256,
        accumulatedChainId: u256,
        originChainId: u256,
        originalMmrId: u256,
        isSiblingSynced: bool,
    ) {
        assert(from_address == self.l1_message_sender.read(), 'ONLY_L1_MESSAGE_SENDER');
        self._createMmrFromForeign(
            newMmrId,
            rootsForHashingFunctions,
            mmrSize,
            accumulatedChainId,
            originChainId,
            originalMmrId,
            isSiblingSynced,
        );
    }

    #[external(v0)]
    impl IReceiverImpl of IReceiver {
        fn setL1MessageSender(
            ref self: ContractState,
            l1_address: felt252,
        ) {
            // TODO: owner only
            self.l1_message_sender.write(l1_address);
        }
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StateEvent: state_component::Event,
        EvmFactRegistryEvent: evm_fact_registry_component::Event,
        MmrCoreEvent: mmr_core_component::Event,
    }

    #[abi(embed_v0)]
    impl EvmFactRegistryImpl =
        evm_fact_registry_component::EvmFactRegistry<ContractState>;

    impl MmrCoreInternalImpl = mmr_core_component::MmrCoreInternal<ContractState>;
}
