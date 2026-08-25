use storage_proofs::cairo_fact_registry::get_fact_hashes;

#[test]
fn test_get_fact_hashes_1() {
    let program_hash: felt252 = 0x024635cb1e1e20ed5d3af014f21c457b43f1297912d4a2db706999cf4117fbc2;
    let output = [
        0xa4219f, 0xa41a46, 0x904fe236e43cd0d0e61fc97ef38ac50d, 0xf10d8ca4b572731a2479a61726be5ece,
        0xb6949179c92c0946d231c146db41c700, 0xa72f757427b396e804318986c59834f0,
        0x7108f7fd3b11f499b05e95f0d77d23e581c15d02a22922a1bd641950c59e802,
        0x299fc3d4c121d33335d102bab7ff1705, 0x59b51dde30bb78a402863dc6e69e9cbf, 0x28e528,
        0x1427bc87fbf9d43803d82b8fb9a60336c918cbd14c33c954eeb20adc1f62d12,
        0x82fc93c52d6aab47d887efffe1cc05e7, 0x6e95cae272878108ca21bfa2e9765f35, 0x28f3d9,
    ]
        .span();

    let expected_keccak_fact: u256 =
        0x683e7a11077aeb0e52a0918212dc0dc60f5f807148b703135f9b0158c4713319;
    let expected_poseidon_fact: felt252 =
        0x27b610200ae060ac07887efbc502c39b55718d86cc516b54f108f54164a3d5b;

    let (keccak_fact, poseidon_fact) = get_fact_hashes(program_hash, output);

    assert(keccak_fact == expected_keccak_fact, 'keccak fact mismatch');
    assert(poseidon_fact == expected_poseidon_fact, 'poseidon fact mismatch');
}

#[test]
fn test_get_fact_hashes_2() {
    let program_hash: felt252 = 0x7387f9a9d25ada984cdad3c677adca4ad2d9c1f4fcc41daf5d522ffb6a48c8f;
    let output = [0xb, 0xc, 0xd].span();

    let expected_keccak_fact: u256 =
        0xf92b63d73a8ab9eba89e99a65074a5a51b63a356762dc9891cbafc5e1217920d;
    let expected_poseidon_fact: felt252 =
        0x726e06a3262c55e0e452007677ecf674db672c1da6d8ac79870b0e9502280ec;

    let (keccak_fact, poseidon_fact) = get_fact_hashes(program_hash, output);

    assert(keccak_fact == expected_keccak_fact, 'keccak fact mismatch');
    assert(poseidon_fact == expected_poseidon_fact, 'poseidon fact mismatch');
}
