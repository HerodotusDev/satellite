use storage_proofs::{
    evm_fact_registry::evm_fact_registry_component::{
        EvmFactRegistryInternalImpl, EvmFactRegistryImpl,
    },
    mmr_core::{
        mmr_core_component::{MmrCoreInternalImpl, MmrCoreExternalImpl}, RootForHashingFunction,
        POSEIDON_HASHING_FUNCTION, KECCAK_HASHING_FUNCTION,
    },
    receiver::Satellite,
};


fn setup_mmr_multiple_hashing_functions() -> (
    Satellite::ContractState, u256, u256, u256, u256, u256,
) {
    let mut contract = Satellite::contract_state_for_testing();

    // Set up some MMR for testing
    let chain_id = 11155111;
    let original_mmr_id = 123;
    let mmr_size = 10;
    let keccak_root = 0x4c466c582074f6351b729134d42c66b15b7e1218fa63f1bfd614045ea96cd66a;
    let poseidon_root = 0x3c5f312ba85ad56867cd2de63d79e4ba910c90d9e82437d023846a044d10952;
    let original_is_offchain_grown = true;
    let roots_for_hashing_functions = [
        RootForHashingFunction {
            root: keccak_root.into(), hashing_function: KECCAK_HASHING_FUNCTION,
        },
        RootForHashingFunction {
            root: poseidon_root.into(), hashing_function: POSEIDON_HASHING_FUNCTION,
        },
    ]
        .span();

    contract
        ._createMmrFromForeign(
            original_mmr_id,
            roots_for_hashing_functions,
            mmr_size,
            chain_id,
            chain_id,
            0,
            original_is_offchain_grown,
        );

    assert_eq!(
        contract.getLatestMmr(chain_id, original_mmr_id, KECCAK_HASHING_FUNCTION),
        (mmr_size, keccak_root, original_is_offchain_grown),
    );
    assert_eq!(
        contract.getLatestMmr(chain_id, original_mmr_id, POSEIDON_HASHING_FUNCTION),
        (mmr_size, poseidon_root, original_is_offchain_grown),
    );

    (contract, chain_id, original_mmr_id, mmr_size, keccak_root, poseidon_root)
}

fn setup_mmr_single_hashing_functions(
    original_is_offchain_grown: bool,
) -> (Satellite::ContractState, u256, u256, u256, u256) {
    let mut contract = Satellite::contract_state_for_testing();

    // Set up some MMR for testing
    let chain_id = 11155111;
    let original_mmr_id = 123;
    let mmr_size = 10;
    let keccak_root = 0x4c466c582074f6351b729134d42c66b15b7e1218fa63f1bfd614045ea96cd66a;
    let roots_for_hashing_functions = [
        RootForHashingFunction {
            root: keccak_root.into(), hashing_function: KECCAK_HASHING_FUNCTION,
        },
    ]
        .span();

    contract
        ._createMmrFromForeign(
            original_mmr_id,
            roots_for_hashing_functions,
            mmr_size,
            chain_id,
            chain_id,
            0,
            original_is_offchain_grown,
        );

    assert_eq!(
        contract.getLatestMmr(chain_id, original_mmr_id, KECCAK_HASHING_FUNCTION),
        (mmr_size, keccak_root, original_is_offchain_grown),
    );

    (contract, chain_id, original_mmr_id, mmr_size, keccak_root)
}

// ========== Branch out from offchain MMR with multiple hashing functions ========== //

#[test]
fn multiple_offchain_to_multiple_offchain() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, keccak_root, poseidon_root) =
        setup_mmr_multiple_hashing_functions();

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [KECCAK_HASHING_FUNCTION, POSEIDON_HASHING_FUNCTION].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );

    assert_eq!(
        contract.getLatestMmr(chain_id, new_mmr_id, KECCAK_HASHING_FUNCTION),
        (mmr_size, keccak_root, new_is_offchain_grown),
    );
    assert_eq!(
        contract.getLatestMmr(chain_id, new_mmr_id, POSEIDON_HASHING_FUNCTION),
        (mmr_size, poseidon_root, new_is_offchain_grown),
    );
}

#[test]
#[should_panic(expected: 'SRC_MMR_NOT_FOUND')]
// Should panic because hashing function 0x111 doesn't exist
fn multiple_offchain_to_multiple_offchain_invalid_hashing_function() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, _, _) =
        setup_mmr_multiple_hashing_functions();

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [KECCAK_HASHING_FUNCTION, 0x111].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );
}

#[test]
fn multiple_offchain_to_single_offchain() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, keccak_root, _) =
        setup_mmr_multiple_hashing_functions();

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [KECCAK_HASHING_FUNCTION].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );

    assert_eq!(
        contract.getLatestMmr(chain_id, new_mmr_id, KECCAK_HASHING_FUNCTION),
        (mmr_size, keccak_root, new_is_offchain_grown),
    );
    assert_eq!(
        contract.getLatestMmr(chain_id, new_mmr_id, POSEIDON_HASHING_FUNCTION), (0, 0, false),
    );
}

#[test]
#[should_panic(expected: 'SRC_MMR_NOT_FOUND')]
// Should panic because hashing function 0x111 doesn't exist
fn multiple_offchain_to_single_offchain_invalid_hashing_function() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, _, _) =
        setup_mmr_multiple_hashing_functions();

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [0x111].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );
}

#[test]
#[should_panic(expected: 'INVALID_HASHING_FUNCTIONS_LEN')]
// Should panic because onchain MMRs can have only one hashing function
fn multiple_offchain_to_multiple_onchain() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, _, _) =
        setup_mmr_multiple_hashing_functions();

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [KECCAK_HASHING_FUNCTION, POSEIDON_HASHING_FUNCTION].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );
}

#[test]
fn multiple_offchain_to_single_onchain() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, keccak_root, _) =
        setup_mmr_multiple_hashing_functions();

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [KECCAK_HASHING_FUNCTION].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );

    assert_eq!(
        contract.getLatestMmr(chain_id, new_mmr_id, KECCAK_HASHING_FUNCTION),
        (mmr_size, keccak_root, new_is_offchain_grown),
    );
    assert_eq!(
        contract.getLatestMmr(chain_id, new_mmr_id, POSEIDON_HASHING_FUNCTION), (0, 0, false),
    );
}

#[test]
#[should_panic(expected: 'SRC_MMR_NOT_FOUND')]
// Should panic because hashing function 0x111 doesn't exist
fn multiple_offchain_to_single_onchain_invalid_hashing_function() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, _, _) =
        setup_mmr_multiple_hashing_functions();

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [0x111].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );
}

// ========== Branch out from offchain MMR with single hashing functions ========== //

#[test]
#[should_panic(expected: 'SRC_MMR_NOT_FOUND')]
// Should panic because hashing function doesn't exist in original MMR
// Errors with SRC_MMR_NOT_FOUND, because root for provided hashing function does not exist in
// original MMR
fn single_offchain_to_multiple_offchain() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, _) = setup_mmr_single_hashing_functions(
        true,
    );

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [KECCAK_HASHING_FUNCTION, POSEIDON_HASHING_FUNCTION].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );
}

#[test]
fn single_offchain_to_single_offchain() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, keccak_root) =
        setup_mmr_single_hashing_functions(
        true,
    );

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [KECCAK_HASHING_FUNCTION].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );

    assert_eq!(
        contract.getLatestMmr(chain_id, new_mmr_id, KECCAK_HASHING_FUNCTION),
        (mmr_size, keccak_root, new_is_offchain_grown),
    );
    assert_eq!(
        contract.getLatestMmr(chain_id, new_mmr_id, POSEIDON_HASHING_FUNCTION), (0, 0, false),
    );
}

#[test]
#[should_panic(expected: 'SRC_MMR_NOT_FOUND')]
// Should panic because hashing function POSEIDON_HASHING_FUNCTION doesn't exist
fn single_offchain_to_single_offchain_invalid_hashing_function() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, _) = setup_mmr_single_hashing_functions(
        true,
    );

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [POSEIDON_HASHING_FUNCTION].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );
}

#[test]
#[should_panic(expected: 'INVALID_HASHING_FUNCTIONS_LEN')]
// Should panic because onchain MMRs can have only one hashing function
fn single_offchain_to_multiple_onchain() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, _) = setup_mmr_single_hashing_functions(
        true,
    );

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [KECCAK_HASHING_FUNCTION, POSEIDON_HASHING_FUNCTION].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );
}

#[test]
fn single_offchain_to_single_onchain() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, keccak_root) =
        setup_mmr_single_hashing_functions(
        true,
    );

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [KECCAK_HASHING_FUNCTION].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );

    assert_eq!(
        contract.getLatestMmr(chain_id, new_mmr_id, KECCAK_HASHING_FUNCTION),
        (mmr_size, keccak_root, new_is_offchain_grown),
    );
    assert_eq!(
        contract.getLatestMmr(chain_id, new_mmr_id, POSEIDON_HASHING_FUNCTION), (0, 0, false),
    );
}

#[test]
#[should_panic(expected: 'SRC_MMR_NOT_FOUND')]
// Should panic because hashing function POSEIDON_HASHING_FUNCTION doesn't exist
fn single_offchain_to_single_onchain_invalid_hashing_function() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, _) = setup_mmr_single_hashing_functions(
        true,
    );

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [POSEIDON_HASHING_FUNCTION].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );
}

// ========== Branch out from onchain MMR with single hashing functions ========== //

#[test]
#[should_panic(expected: 'SRC_MMR_NOT_FOUND')]
// Should panic because hashing function doesn't exist in original MMR
// Errors with SRC_MMR_NOT_FOUND, because root for provided hashing function does not exist in
// original MMR
fn single_onchain_to_multiple_offchain() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, _) = setup_mmr_single_hashing_functions(
        false,
    );

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [KECCAK_HASHING_FUNCTION, POSEIDON_HASHING_FUNCTION].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );
}

#[test]
fn single_onchain_to_single_offchain() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, keccak_root) =
        setup_mmr_single_hashing_functions(
        false,
    );

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [KECCAK_HASHING_FUNCTION].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );

    assert_eq!(
        contract.getLatestMmr(chain_id, new_mmr_id, KECCAK_HASHING_FUNCTION),
        (mmr_size, keccak_root, new_is_offchain_grown),
    );
    assert_eq!(
        contract.getLatestMmr(chain_id, new_mmr_id, POSEIDON_HASHING_FUNCTION), (0, 0, false),
    );
}

#[test]
#[should_panic(expected: 'SRC_MMR_NOT_FOUND')]
// Should panic because hashing function POSEIDON_HASHING_FUNCTION doesn't exist
fn single_onchain_to_single_offchain_invalid_hashing_function() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, _) = setup_mmr_single_hashing_functions(
        false,
    );

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [POSEIDON_HASHING_FUNCTION].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );
}

#[test]
#[should_panic(expected: 'INVALID_HASHING_FUNCTIONS_LEN')]
// Should panic because onchain MMRs can have only one hashing function
fn single_onchain_to_multiple_onchain() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, _) = setup_mmr_single_hashing_functions(
        false,
    );

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [KECCAK_HASHING_FUNCTION, POSEIDON_HASHING_FUNCTION].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );
}

#[test]
fn single_onchain_to_single_onchain() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, keccak_root) =
        setup_mmr_single_hashing_functions(
        false,
    );

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [KECCAK_HASHING_FUNCTION].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );

    assert_eq!(
        contract.getLatestMmr(chain_id, new_mmr_id, KECCAK_HASHING_FUNCTION),
        (mmr_size, keccak_root, new_is_offchain_grown),
    );
    assert_eq!(
        contract.getLatestMmr(chain_id, new_mmr_id, POSEIDON_HASHING_FUNCTION), (0, 0, false),
    );
}

#[test]
#[should_panic(expected: 'SRC_MMR_NOT_FOUND')]
// Should panic because hashing function POSEIDON_HASHING_FUNCTION doesn't exist
fn single_onchain_to_single_onchain_invalid_hashing_function() {
    let (mut contract, chain_id, original_mmr_id, mmr_size, _) = setup_mmr_single_hashing_functions(
        false,
    );

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [POSEIDON_HASHING_FUNCTION].span();
    contract
        .createMmrFromDomestic(
            new_mmr_id,
            original_mmr_id,
            chain_id,
            mmr_size,
            hashing_functions,
            new_is_offchain_grown,
        );
}
