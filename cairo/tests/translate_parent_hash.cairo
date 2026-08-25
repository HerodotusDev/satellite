use starknet::storage::{StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess};
use storage_proofs::mmr_core::{
    ICoreMmrExternal, KECCAK_HASHING_FUNCTION, POSEIDON_HASHING_FUNCTION,
};
use storage_proofs::receiver::Satellite;

fn get_example_1() -> (Span<u64>, u256, u256, u256) {
    let header_rlp = [
        0xc57beff6a06102f9, 0xab0a35054d35bb33, 0xeb293dfc4f6a1e9e, 0xde7dca79eef974c1,
        0x4dcc1da07d978234, 0xb585ab7a5dc7dee8, 0x4512d31ad4ccb667, 0x42a1f013748a941b,
        0x9425944793d440fd, 0xc84f5164bb71c71d, 0xd4b97f3070e9bcab, 0xf0b3015de4a0e977,
        0x5b79e4dceb12dbce, 0x22fc154783b2743a, 0x53ca1c01878645d0, 0x37e96f58a0faf77c,
        0xa3720dfd9cac4207, 0xea8c574511de3db8, 0x5cac20e616cc2d65, 0x5bcf0fa0bb670a23,
        0xacee818d30bcc6d9, 0xe8f80274901e26c4, 0xa10b5f68a7f39121, 0x1b93460999928,
        0xa4908801f812a1d, 0x6c0d02a3b6319edb, 0x3f340a362a9e430d, 0x571ae90206a0c8a2,
        0x19256bfdf110e8a2, 0xe880240cf13fce81, 0x1c2740e927507411, 0x1a5cb466403646c8,
        0xa8140c29a88f2aac, 0x100a18b15b2134f1, 0x6448e412881247e4, 0x509ed494a202509c,
        0x4b732a2afc996439, 0xa4e8e23402e63561, 0xa378ac4ac8a94fd4, 0x4c6a088dbd10213a,
        0xace18223e800e86a, 0xb611201b93946464, 0x3c0209d015ed6c4a, 0x1ccc97948b308d76,
        0x9600e2a1838a8882, 0xdfdd0d58224140f4, 0x14aa4ee490923, 0xbb39414c227b85c3,
        0xa706c2976e0c88c1, 0x5440979fe1066142, 0x216080ec011a4000, 0xa1e8686c5c40a864,
        0x4e909ce098e59680, 0x5f801c2c87612035, 0xcc07948d300c5e82, 0x2072f2c874270606,
        0x25028472ce738380, 0x843591d101840051, 0x183d899c0f09867, 0x8868746567840c0e,
        0x332e33322e316f67, 0xfba078756e696c85, 0xc7c756aed3073b2e, 0x1a567fbb80af3d8c,
        0x492af78cba2398bc, 0x88822d33dabc18e3, 0x0, 0xc812a03f7834d984, 0xd6ba4d226aca183d,
        0x883da7e2739499e8, 0xbeb477f6ae4a3ecf, 0xc830ea6c7cfcf8b, 0xfcf15685a0800000,
        0x11cef7e7eb27080c, 0xe26671c1c8021f74, 0xacf1aab71fa45f32, 0x6c1a34ec,
    ]
        .span();

    let block_number: u256 = 7589490;
    let keccak_hash: u256 = 0x91f27b9943379ad7147ccf51317e4ad74c4d753a377eadd4cb37d91e5cb9d22a;
    let poseidon_hash: u256 = 0x3f932f98b40cb3c9d65a3c8f94d6f7988fe27c99595000dcd625c00e3d67c1a;

    (header_rlp, block_number, keccak_hash, poseidon_hash)
}

fn get_example_2() -> (Span<u64>, u256, u256, u256) {
    let header_rlp = [
        0xe9421fafa06302f9, 0x51c64069719b6868, 0x4c600544c9fd69ad, 0xfe46e0a32c2b540e,
        0x4dcc1da03d57e7c3, 0xb585ab7a5dc7dee8, 0x4512d31ad4ccb667, 0x42a1f013748a941b,
        0x989b944793d440fd, 0xa2c08d0d98035a4d, 0xc824544668c90645, 0x2f60dd27c9a0be1d,
        0x06d028586d4e6bfc, 0xc64c02222d6af2ca, 0xefa9df97e94e68e5, 0xca376c4fa0b62686,
        0x70cb1975aaad83aa, 0x35d5e8e6fe9b93d1, 0x111ebf4bc1fc1435, 0x6dac7da003d711e9,
        0x1800c60a01da69d3, 0xdcf5c3929b3597e4, 0x80141d5ccc0ea28d, 0x0001b91ff9c2e3ed,
        0x105a1c804c886a08, 0x6c00088496511591, 0x8652c32463204840, 0xcb0cb64036193872,
        0x8701826080614842, 0x9ca2bc42570ca068, 0x0536420e21985003, 0xca027d28a3929255,
        0x09238c0d6e723900, 0x24c201900e308140, 0xca08f401008345c5, 0x13e660941ccd5694,
        0x0450dc02601c02b9, 0x644814136300188a, 0xca8ca4d8c10d58a8, 0x18470b61d4488142,
        0x6564b0e90438e74a, 0x94c9a0a3298002a2, 0x2b055814c1430012, 0x1305e0a4e5040396,
        0x79118200d7e1ce4a, 0x1f0aa60c25046065, 0x82d46294cde7d204, 0xc21ea0a0064bc5a1,
        0xc002702c930d0488, 0x182083a83d2b0310, 0x5281d793204ae04c, 0x61f9c09336bd231a,
        0x6089130018425480, 0x049210f28332a557, 0x4122306c30913280, 0x385aa91055214804,
        0x2502847101768380, 0x678480edaf830051, 0x0f0183d8993c74b4, 0x6788687465678402,
        0x85362e33322e316f, 0x245fa078756e696c, 0x7d3c387764726a3f, 0xfaa56e02cc639e09,
        0xf420fd5736e1a024, 0x00885a4597ae5746, 0x8400000000000000, 0x5201b5a039fbe4af,
        0x7af08816185117dc, 0xc97a9b0f540460b3, 0x3dcd40a576accc2b, 0x000883ceaaaa59f4,
        0x2b72a000004c8300, 0x6173d5b4c6cb7adf, 0x8a3f497d877ee937, 0xf4ecda00a56f312d,
        0xb90d115f60ce,
    ]
        .span();

    let block_number: u256 = 7733618;
    let hash_keccak: u256 = 0xc9a017b4cf7c70308aa44fc4fe9daa872da815947670f919eb45ff3969bcbda9;
    let hash_poseidon: u256 = 0x3a876b75da92a476f485ab1609e285a703996f4b6a899030efa58773d546067;

    (header_rlp, block_number, hash_keccak, hash_poseidon)
}

fn get_example_3() -> (Span<u64>, u256, u256, u256) {
    let header_rlp = [
        0x7f8bbfe6a08c02f9, 0x52e9b75990c003bc, 0x27e1814e94c136f6, 0xc9477a0f8a95ce5d,
        0x4dcc1da08543ba44, 0xb585ab7a5dc7dee8, 0x4512d31ad4ccb667, 0x42a1f013748a941b,
        0xcb13944793d440fd, 0x4d7f97a0134ae36a, 0x23bb874bc2eb0171, 0xabace44f21a0d5f0,
        0xff1d89af13afdda1, 0x7b34bbeff95c08b7, 0xe7982d727b7220a2, 0xb1d70d93a0de5545,
        0x2baf2fd69e315ee4, 0xad9cd8b978095c4, 0x7ccf3460fdc7541b, 0xcd1d50a0f3c9d827,
        0x78f3548545e6a139, 0xa3d5b61da89c1d7d, 0xd02e5b5ab5838644, 0x1b9eef48b9de0,
        0xf04010c642428154, 0xa41100456891102, 0x8a4412010f90cd09, 0xa024030658a11a1d,
        0x2361904102a09a00, 0x82a1a45043c1c04a, 0x2066ab11004a15c0, 0x40416a71dab20008,
        0xc86206063081825a, 0xd18078400a00a042, 0x2073901118404095, 0x10a1080144061a29,
        0x2219096208824602, 0x480b1088a5b40420, 0x1b501026c1200800, 0x7264281110800000,
        0x26a54010020cab3, 0x1498116806480a6, 0x53904428c11d2989, 0x8021601003710,
        0x741a101087204912, 0x60801108c5c54630, 0x1c009418b208049, 0xbc9b8000e0a8191,
        0x43700104a2808a42, 0x49404e58210c3384, 0x3040281664011813, 0x330640000425208,
        0x3fe80881041425, 0x16800f602a1a1288, 0x7e42f9080d1e26c0, 0x9c10031262ac92,
        0x9303845a929b8380, 0x84bb627f01840087, 0x6c6c499f505e8469, 0x206574616e696d75,
        0x69746172636f6d44, 0x697274734420657a, 0x2d9c5aa065747562, 0xb690eb26a2882d74,
        0x6007b42e69d464d2, 0xbfe1e0f78a7dea39, 0x88b81931a844, 0x3b84000000000000,
        0x137ae4e6a0139cfb, 0x96851f9f4a39b4f5, 0x6da2d7e5d4742e79, 0x9af6dae5691c1b22,
        0x1483cc2f1a31, 0xe2cda06725700c84, 0x582f29afd511ec60, 0x7b38af835c44e903,
        0xa5f2d1bd45982c71, 0xe3a07f14a8e25ce0, 0x9a141cfc9842c4b0, 0x2724b96f99c8f4fb,
        0xa44c939b64e441ae, 0x55b852781b9995,
    ]
        .span();

    let block_number: u256 = 10195546;
    let hash_keccak: u256 = 0x0f1721fbb6d61170172accd29d6d1518c29cf8b727f87bac73013bf3a8e851d8;
    let hash_poseidon: u256 = 0x40d8850d0e0d27fe0d460ac5031ffcd582925601059830cc7c2498c7858eb4b;
    // 0xe6bf8b7fbc03c09059b7e952f636c1944e81e1275dce958a0f7a47c944ba4385

    (header_rlp, block_number, hash_keccak, hash_poseidon)
}

#[test]
fn test_translate_parent_hash_1() {
    let chain_id: u256 = 11155111;
    let (header_rlp, block_number, hash_keccak, hash_poseidon) = get_example_1();

    let mut contract = Satellite::contract_state_for_testing();

    contract
        .state
        .received_parent_hashes
        .entry(chain_id)
        .entry(KECCAK_HASHING_FUNCTION)
        .entry(block_number)
        .write(hash_keccak);

    contract.translateParentHashFunction(chain_id, block_number, header_rlp);

    let result = contract
        .state
        .received_parent_hashes
        .entry(chain_id)
        .entry(POSEIDON_HASHING_FUNCTION)
        .entry(block_number)
        .read();
    assert(result == hash_poseidon, 'Result mismatch');
}

#[test]
fn test_translate_parent_hash_2() {
    let chain_id: u256 = 11155111;
    let (header_rlp, block_number, hash_keccak, hash_poseidon) = get_example_2();

    let mut contract = Satellite::contract_state_for_testing();

    contract
        .state
        .received_parent_hashes
        .entry(chain_id)
        .entry(KECCAK_HASHING_FUNCTION)
        .entry(block_number)
        .write(hash_keccak);

    contract.translateParentHashFunction(chain_id, block_number, header_rlp);

    let result = contract
        .state
        .received_parent_hashes
        .entry(chain_id)
        .entry(POSEIDON_HASHING_FUNCTION)
        .entry(block_number)
        .read();
    assert(result == hash_poseidon, 'Result mismatch');
}

#[test]
fn test_translate_parent_hash_3() {
    let chain_id: u256 = 11155111;
    let (header_rlp, block_number, hash_keccak, hash_poseidon) = get_example_3();

    let mut contract = Satellite::contract_state_for_testing();

    contract
        .state
        .received_parent_hashes
        .entry(chain_id)
        .entry(KECCAK_HASHING_FUNCTION)
        .entry(block_number)
        .write(hash_keccak);

    contract.translateParentHashFunction(chain_id, block_number, header_rlp);

    let result = contract
        .state
        .received_parent_hashes
        .entry(chain_id)
        .entry(POSEIDON_HASHING_FUNCTION)
        .entry(block_number)
        .read();
    assert(result == hash_poseidon, 'Result mismatch');
}
