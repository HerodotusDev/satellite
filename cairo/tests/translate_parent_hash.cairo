use herodotus_starknet::{
    mmr_core::{ICoreMmrExternal, KECCAK_HASHING_FUNCTION, POSEIDON_HASHING_FUNCTION},
    receiver::HerodotusStarknet,
};
use core::starknet::storage::{
    StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry,
};

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

#[test]
fn test_translate_parent_hash_1() {
    let chain_id: u256 = 11155111;
    let (header_rlp, block_number, hash_keccak, hash_poseidon) = get_example_1();

    let mut contract = HerodotusStarknet::contract_state_for_testing();

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

    let mut contract = HerodotusStarknet::contract_state_for_testing();

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
