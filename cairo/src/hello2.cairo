#[starknet::interface]
pub trait IHello2<TContractState> {
    fn read(self: @TContractState) -> felt252;
}

#[starknet::component]
pub mod hello_component2 {
    use herodotus_starknet::state::state_component;

    #[storage]
    struct Storage {}

    #[embeddable_as(Hello2)]
    impl Hello2Impl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl State: state_component::HasComponent<TContractState>,
    > of super::IHello2<ComponentState<TContractState>> {
        fn read(self: @ComponentState<TContractState>) -> felt252 {
            let state = get_dep_component!(self, State);
            state.testvar.read()
        }
    }
}