use herodotus_starknet::{
    mmr_core::{ICoreMmrExternal, KECCAK_HASHING_FUNCTION, POSEIDON_HASHING_FUNCTION},
    receiver::HerodotusStarknet,
};
use core::starknet::storage::{
    StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry,
};

fn get_example_header_rlp() -> Span<u64> {
    let header_rlp = [
        0xb417a0c9a04402f9, 0xc44fa48a30707ccf, 0x9415a82d87aa9dfe, 0x39ff45eb19f97076,
        0x4dcc1da0a9bdbc69, 0xb585ab7a5dc7dee8, 0x4512d31ad4ccb667, 0x42a1f013748a941b,
        0x2638944793d440fd, 0x19f1dc688dbd9c53, 0x8c27b45745990be8, 0xe3c82def58a09fec,
        0xf93f2aede22bd03b, 0x841403a334a8be35, 0x23e5b88c68531264, 0x171fe856a0fc4806,
        0xe64583ffa655cc1b, 0x1be0485b6ef8c092, 0xb52f6201c0ad6c99, 0x1fe856a021b463e3,
        0x4583ffa655cc1b17, 0xe0485b6ef8c092e6, 0x2f6201c0ad6c991b, 0x0001b921b463e3b5,
        0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
        0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
        0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
        0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
        0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
        0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
        0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
        0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
        0x2502847201768380, 0x5474b46784800051, 0x2d3576d93594a080, 0xe477ecf301ea4315,
        0x3f4a23d6576e2d0f, 0x5294ee0d8f1dda30, 0x000000000088db1d, 0xdbadfda784000000,
        0xf40404ba7832eda0, 0x50c990323c2a14f3, 0x7b08ccb0f31f6c47, 0xaceadb398231bbb7,
        0x82a000004e838073, 0x4abf69ae4a2d7dd8, 0x2703b0e33ec4ae42, 0xb0dcc334cb0349fa,
        0x53cda84a8097bd,
    ]
        .span();

    header_rlp
}

fn get_example_header_rlp_2() -> Span<u64> {
    let header_rlp = [
        0xe9421fafa06302f9,0x51c64069719b6868,0x4c600544c9fd69ad,0xfe46e0a32c2b540e,0x4dcc1da03d57e7c3,0xb585ab7a5dc7dee8,0x4512d31ad4ccb667,0x42a1f013748a941b,0x989b944793d440fd,0xa2c08d0d98035a4d,0xc824544668c90645,0x2f60dd27c9a0be1d,0x06d028586d4e6bfc,0xc64c02222d6af2ca,0xefa9df97e94e68e5,0xca376c4fa0b62686,0x70cb1975aaad83aa,0x35d5e8e6fe9b93d1,0x111ebf4bc1fc1435,0x6dac7da003d711e9,0x1800c60a01da69d3,0xdcf5c3929b3597e4,0x80141d5ccc0ea28d,0x0001b91ff9c2e3ed,0x105a1c804c886a08,0x6c00088496511591,0x8652c32463204840,0xcb0cb64036193872,0x8701826080614842,0x9ca2bc42570ca068,0x0536420e21985003,0xca027d28a3929255,0x09238c0d6e723900,0x24c201900e308140,0xca08f401008345c5,0x13e660941ccd5694,0x0450dc02601c02b9,0x644814136300188a,0xca8ca4d8c10d58a8,0x18470b61d4488142,0x6564b0e90438e74a,0x94c9a0a3298002a2,0x2b055814c1430012,0x1305e0a4e5040396,0x79118200d7e1ce4a,0x1f0aa60c25046065,0x82d46294cde7d204,0xc21ea0a0064bc5a1,0xc002702c930d0488,0x182083a83d2b0310,0x5281d793204ae04c,0x61f9c09336bd231a,0x6089130018425480,0x049210f28332a557,0x4122306c30913280,0x385aa91055214804,0x2502847101768380,0x678480edaf830051,0x0f0183d8993c74b4,0x6788687465678402,0x85362e33322e316f,0x245fa078756e696c,0x7d3c387764726a3f,0xfaa56e02cc639e09,0xf420fd5736e1a024,0x00885a4597ae5746,0x8400000000000000,0x5201b5a039fbe4af,0x7af08816185117dc,0xc97a9b0f540460b3,0x3dcd40a576accc2b,0x000883ceaaaa59f4,0x2b72a000004c8300,0x6173d5b4c6cb7adf,0x8a3f497d877ee937,0xf4ecda00a56f312d,0xb90d115f60ce
    ].span();

    header_rlp
}

#[test]
fn test_translate_parent_hash() {
    let chain_id: u256 = 11155111;
    let block_number: u256 = 0;// todo: is this correct?
    let hash_keccak: u256 = 0xbc1d3acd5d78c3ed86c3ae64577a5bdf726cf1047ced41bf608f03df9d782829;
    let hash_poseidon: u256 = 0x5af296007fc841225b40f3828dcdab6a1a85a97566ee629ab83861b2505a802;

    let mut contract = HerodotusStarknet::contract_state_for_testing();

    contract.state.received_parent_hashes.entry(chain_id).entry(KECCAK_HASHING_FUNCTION).entry(block_number).write(hash_keccak);
    
    contract.translateParentHashFunction(chain_id, block_number, get_example_header_rlp());

    let result = contract.state.received_parent_hashes.entry(chain_id).entry(POSEIDON_HASHING_FUNCTION).entry(block_number).read();

    assert(result == hash_poseidon, 'Result mismatch');
}

#[test]
fn test_translate_parent_hash_marcin() {
    let chain_id: u256 = 11155111;
    let block_number: u256 = 7733618;
    let hash_keccak: u256 = 0xc9a017b4cf7c70308aa44fc4fe9daa872da815947670f919eb45ff3969bcbda9;
    let hash_poseidon: u256 = 0x3a876b75da92a476f485ab1609e285a703996f4b6a899030efa58773d546067;

    let mut contract = HerodotusStarknet::contract_state_for_testing();

    contract.state.received_parent_hashes.entry(chain_id).entry(KECCAK_HASHING_FUNCTION).entry(block_number).write(hash_keccak);
    
    contract.translateParentHashFunction(chain_id, block_number, get_example_header_rlp_2());

    let result = contract.state.received_parent_hashes.entry(chain_id).entry(POSEIDON_HASHING_FUNCTION).entry(block_number).read();

    assert(result == hash_poseidon, 'Result mismatch');
}
