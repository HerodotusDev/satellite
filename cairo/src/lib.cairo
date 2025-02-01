mod state;
pub mod evm_fact_registry;
pub mod hello2;

#[starknet::contract]
mod EvmFactRegistry {
    use herodotus_starknet::{
        evm_fact_registry::evm_fact_registry_component, hello2::hello_component2,
        state::state_component,
    };

    #[abi(embed_v0)]
    component!(path: state_component, storage: state, event: StateEvent);
    #[abi(embed_v0)]
    component!(
        path: evm_fact_registry_component, storage: evm_fact_registry, event: EvmFactRegistryEvent,
    );
    #[abi(embed_v0)]
    component!(path: hello_component2, storage: hello2, event: Hello2Event);

    #[storage]
    struct Storage {
        #[substorage(v0)]
        state: state_component::Storage,
        #[substorage(v0)]
        evm_fact_registry: evm_fact_registry_component::Storage,
        #[substorage(v0)]
        hello2: hello_component2::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StateEvent: state_component::Event,
        EvmFactRegistryEvent: evm_fact_registry_component::Event,
        Hello2Event: hello_component2::Event,
    }

    #[abi(embed_v0)]
    impl EvmFactRegistryImpl =
        evm_fact_registry_component::EvmFactRegistry<ContractState>;
    #[abi(embed_v0)]
    impl Hello2Impl = hello_component2::Hello2<ContractState>;
}
