#[starknet::interface]
pub trait IHello<TContractState> {
    fn increase_balance(ref self: TContractState, amount: felt252);
    fn get_balance(self: @TContractState) -> felt252;
}

#[starknet::component]
pub mod hello_component {
    #[storage]
    struct Storage {
        balance: felt252, 
    }

    #[embeddable_as(Hello)]
    impl HelloImpl<
        TContractState, +HasComponent<TContractState>,
    > of super::IHello<ComponentState<TContractState>> {
        fn increase_balance(ref self: ComponentState<TContractState>, amount: felt252) {
            assert(amount != 0, 'Amount cannot be 0');
            self.balance.write(self.balance.read() + amount);
        }
    
        fn get_balance(self: @ComponentState<TContractState>) -> felt252 {
            self.balance.read()
        }
    }
}