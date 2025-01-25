#[starknet::interface]
pub trait IHello<TContractState> {
    fn write(ref self: TContractState, value: felt252);
}

#[starknet::component]
pub mod hello_component {
    use herodotus_starknet::state::state_component;

    #[storage]
    struct Storage {
        balance: felt252, 
    }

    #[embeddable_as(Hello)]
    impl HelloImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl State: state_component::HasComponent<TContractState>,
    > of super::IHello<ComponentState<TContractState>> {
        fn write(ref self: ComponentState<TContractState>, value: felt252) {
            let mut state = get_dep_component_mut!(ref self, State);
            state.testvar.write(value);
        }
    }
}