use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

use herodotus_starknet::hello::IHelloSafeDispatcher;
use herodotus_starknet::hello::IHelloSafeDispatcherTrait;
use herodotus_starknet::hello::IHelloDispatcher;
use herodotus_starknet::hello::IHelloDispatcherTrait;

use herodotus_starknet::hello2::IHello2SafeDispatcher;
use herodotus_starknet::hello2::IHello2SafeDispatcherTrait;
use herodotus_starknet::hello2::IHello2Dispatcher;
use herodotus_starknet::hello2::IHello2DispatcherTrait;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_increase_balance() {
    let contract_address = deploy_contract("HelloStarknet");

    let dispatcher = IHelloDispatcher { contract_address };
    let dispatcher2 = IHello2Dispatcher { contract_address };

    // let balance_before = dispatcher.get_balance();
    assert(dispatcher2.read() == 0, 'Invalid value');

    dispatcher.write(12);

    assert(dispatcher2.read() == 12, 'Invalid value');

    // dispatcher.increase_balance(42);

    // let balance_after = dispatcher.get_balance();
    // assert(balance_after == 42, 'Invalid balance');
}

// #[test]
// #[feature("safe_dispatcher")]
// fn test_cannot_increase_balance_with_zero_value() {
//     let contract_address = deploy_contract("Hello");

//     let safe_dispatcher = IHelloSafeDispatcher { contract_address };

//     let balance_before = safe_dispatcher.get_balance().unwrap();
//     assert(balance_before == 0, 'Invalid balance');

//     match safe_dispatcher.increase_balance(0) {
//         Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
//         Result::Err(panic_data) => {
//             assert(*panic_data.at(0) == 'Amount cannot be 0', *panic_data.at(0));
//         }
//     };
// }
