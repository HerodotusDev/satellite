mod state;
pub mod hello;
pub mod hello2;

#[starknet::contract]
mod HelloStarknet {
    use herodotus_starknet::{
        hello::hello_component,
        hello2::hello_component2,
        state::state_component,
    };

    #[abi(embed_v0)]
    component!(path: state_component, storage: state, event: StateEvent);
    #[abi(embed_v0)]
    component!(path: hello_component, storage: hello, event: HelloEvent);
    #[abi(embed_v0)]
    component!(path: hello_component2, storage: hello2, event: Hello2Event);

    #[storage]
    struct Storage {
        #[substorage(v0)]
        state: state_component::Storage,
        #[substorage(v0)]
        hello: hello_component::Storage,
        #[substorage(v0)]
        hello2: hello_component2::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StateEvent: state_component::Event,
        HelloEvent: hello_component::Event,
        Hello2Event: hello_component2::Event,
    }

    #[abi(embed_v0)]
    impl HelloImpl = hello_component::Hello<ContractState>;
    #[abi(embed_v0)]
    impl Hello2Impl = hello_component2::Hello2<ContractState>;

}
