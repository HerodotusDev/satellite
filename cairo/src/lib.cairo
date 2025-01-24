mod hello;

#[starknet::contract]
mod HelloStarknet {
    use super::hello::hello_component;

    #[abi(embed_v0)]
    component!(path: hello_component, storage: hello, event: HelloEvent);

    #[storage]
    struct Storage {
        #[substorage(v0)]
        hello: hello_component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        HelloEvent: hello_component::Event,
    }

    #[abi(embed_v0)]
    impl HelloImpl = hello_component::Hello<ContractState>;

}
