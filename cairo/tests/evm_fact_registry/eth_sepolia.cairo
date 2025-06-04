use crate::{
    evm_fact_registry::{
        evm_fact_registry_component::{EvmFactRegistryInternalImpl, EvmFactRegistryImpl},
        BlockHeaderField, AccountField,
    },
    mmr_core::{mmr_core_component::MmrCoreInternalImpl}, receiver::HerodotusStarknet,
};
use starknet::EthAddress;
use crate::_utils::create_mmr_with_block;


fn get_header_sepolia() -> (Span<u64>, u256) {
    // https://rs-indexer.api.herodotus.cloud/blocks/?chain_id=11155111&from_block_number_inclusive=8423389&to_block_number_inclusive=8423389&hashing_function=keccak

    // def format_string_blocks(s: str) -> str:
    //     return ", ".join(["0x" + "".join(reversed([s[i + j : i + j + 2] for j in range(0, 16,
    //     2)])) for i in range(0, len(s), 16)])

    (
        [
            0xacf96fcba07602f9, 0xd0b6919c869adeef, 0x934264fe324b2344, 0x6364613a61d01b77,
            0x4dcc1da06bc8a686, 0xb585ab7a5dc7dee8, 0x4512d31ad4ccb667, 0x42a1f013748a941b,
            0x2638944793d440fd, 0x19f1dc688dbd9c53, 0x8c27b45745990be8, 0x683e7d823aa09fec,
            0x2a547233f0f8d32b, 0xe4a3ca8a2de2859b, 0x465908584d7970f9, 0x39430378a0f39266,
            0xdbd56c793581e904, 0xeccfc6ec3539dd83, 0xf53576f89544d94d, 0xc54b1ea0beb191cc,
            0xb525657c4d7d193e, 0x65875bf3fd9769e4, 0x2083227507efb839, 0x0001b9e7f8014d51,
            0xb2621fc02f74ae1d, 0xce9419b88ea628ca, 0x1650b2bcd13e5ff0, 0x53ea93165438eb0d,
            0x2e276bd05e151c3c, 0x4267774077112673, 0x28be9516e0b49d83, 0x4f203c570a8aebc0,
            0x14c6e66c06b8aa78, 0xc87663995eb2ba07, 0xc89a4d0de2603f9f, 0x45776296a380cef3,
            0x48e7272ef2684841, 0xcd0ca8d370150910, 0x728e40c32a194020, 0xe53b9d7214f0e24a,
            0x5af71c44fb40cfc0, 0x34e38188ab88c96e, 0x68ac576bab7a4063, 0x90c805f64829033e,
            0x9070f242e3ebfc42, 0x88ad4c58bca56cd4, 0x26290ce869525459, 0xc29845609cab8c71,
            0x7f577f0d63aa74c8, 0xb9084c38b33a5ba4, 0x4964b9dc249b1483, 0x4379c5c8423d3755,
            0xa296e1ba1629144c, 0x1025fce891bcdf4d, 0xe1429846af14aae8, 0x668056fbe24d0632,
            0x930384dd87808380, 0x84d6c9e301841c86, 0x7365628b00c13668, 0x312e342e35322075,
            0x1b56a944630993a0, 0x080fc4cf219c6019, 0x892e38b4e19bb574, 0x767ee38aaaaf5c12,
            0x0000000000008822, 0xa0a07c02bf830000, 0xb7e628c67dec8dac, 0xe13b03aa021107b8,
            0xd11a5ced887f8619, 0x83b3039905d4618d, 0xa000000a83000012, 0xeba0ae70a2ff8813,
            0x4eb9536fa29b0468, 0xab6b6c84b1711ea5, 0x6450e7382011fcaf, 0x1cfc9842c4b0e3a0,
            0xb96f99c8f4fb9a14, 0x939b64e441ae2724, 0xb852781b9995a44c, 0x55,
        ]
            .span(),
        0x8087dd,
    )
}

fn get_account_sepolia() -> (Span<Span<u64>>, EthAddress) {
    // curl https://eth-sepolia.g.alchemy.com/v2/API_KEY -X POST -H "Content-Type: application/json"
    // -d '{"id": 3, "jsonrpc": "2.0", "method": "eth_getProof", "params":
    // ["0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8", [], "0x8087dd"]}'

    // def format_string_mpt(sl: list[str]) -> str:
    //     return "\n".join(["[" + ", ".join(["0x" + "".join(reversed([s[i + j + 2 : i + j + 4] for
    //     j in range(0, 16, 2)])) for i in range(0, len(s) - 2, 16)]) + "].span()," for s in sl])

    let account: EthAddress = (0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8).try_into().unwrap();
    let account_rlp = [
        [
            0x07984ebfa01102f9, 0xe8e512fb8e9424e2, 0xa131bed3bf5e1e76, 0x580a7509fe736789,
            0x093e9aa0c32ebaf4, 0xe0467fa3572ab58b, 0x85420603289ed57f, 0x49b292906b814e1f,
            0x8c07a0e894920f84, 0x59282c8bc1b2dce9, 0x874049057d8de78e, 0xf5dbe4929492fbe2,
            0xf8a0048bd6c30cc5, 0x39fccdd7b14f475d, 0xae4b942253819563, 0xcf56c9db7e57bda6,
            0xa0ff9df0a8610058, 0x11299f4ad05d2284, 0x55b1b04049c0f87e, 0x5e1b4918c68ec25a,
            0x412592893d588652, 0x3bae30f089cbaea0, 0x7f7cd99eefb84e8e, 0x5eece609d7f42824,
            0xdbbdf24a3b513a2f, 0x1c21c9bc98c1a054, 0x645c8b32fac6b023, 0x9fea19ee32e76748,
            0xa36ed1a3d4c0eef3, 0xf3ae602ed7a0cd2a, 0x402df5c20cd15fb0, 0x3ba1dfadd33fde71,
            0x440173bffb02e978, 0x5bf9b33aa0cac349, 0x4c816174d3a55d81, 0xe19704877d22963e,
            0xea40419933287a6b, 0xe4709ea03b2e0434, 0xe8c79b68268e3ef4, 0x6be5f93f9f6db7b3,
            0xe92049f59c112a60, 0xebb4a0212fa9b71a, 0x6b2f661be9dbce94, 0x200853f77a9dc6cf,
            0x81a80225fffc9909, 0xd9a0df6a9af7708d, 0xceb7a1a9ca595de2, 0x66269ef770cd1da0,
            0xf134e24f426a16bd, 0xa04f0d304389fbb7, 0xa9486a243319f9de, 0x0f8f19668d331366,
            0x19adc1d8d4af45f6, 0x30f74f2e3dbbe08b, 0xddf4d85d5e43c0a0, 0x85749173ca15777e,
            0xd6d8d0787eeeab52, 0x9ef5192d2464a866, 0x74c60ee0f79fa0da, 0x3104d612d9743adf,
            0x918ba6968db10bea, 0x224fd0fa181d1844, 0x7bf3fdf5b7a0028b, 0xfdb19cd70b32501a,
            0xc29c7cdc7479aa67, 0xcf863cabaab943cf, 0x8039a696,
        ]
            .span(),
        [
            0x49d86a0ca01102f9, 0x0e915dc5c9ba062f, 0x85a6f8c82ed3b94b, 0x999013ef55af215e,
            0x285ccba0196b2bd4, 0x5e48547c7571439f, 0xb245c1d5e879743e, 0x2dcc35f192a44b4d,
            0xa84fa0e1c6d617f9, 0x2033665ed0736701, 0xdb1e20b60289b3e8, 0xae608bf1fac25914,
            0x52a0b238196c5acb, 0xfab74e0346ad5f10, 0x9258cedf10a26630, 0xfdb2fc0c9c5f641e,
            0xa0587b5e815846ce, 0xd2170f13abc71b10, 0x975cd2b6f82249f4, 0x7953ff8bb79873d7,
            0x5801b3257ceda401, 0xbfe509c9d747e4a0, 0xed3962ba97644765, 0x8403b06e5d1178d5,
            0xeea49913a13f1dbc, 0x3d62b9f1d9c2a077, 0x11adeca41c761520, 0xaef2fe1bf73e9699,
            0xe3a7ebbfbb803ccb, 0x29f1129c9ea0b66b, 0x4c460838b12301de, 0x8deb74ee21173ff3,
            0x68ff75a00e74255e, 0x20b9f6bca0d257ab, 0x979887b781442ed7, 0x267df96a06ab0c65,
            0x4c3e4c35ae91fa58, 0x28af95a0af8d34ce, 0x4117c1e0ce6c4d9c, 0x2964254883edcbe4,
            0x1fc39fe34c6396ad, 0x95dea030f0221400, 0x8ed8858a1dae676d, 0xbdd4f3c0d7ee8c67,
            0x0865cec435722a33, 0x89a057906918b6d9, 0xdfd81dab58ac9fe1, 0x2b8abf860c32e16b,
            0xde06e14109011287, 0xa099e668a9d9ac38, 0xe672a7b26b63c258, 0xebc8a8b520afc4c0,
            0x985558c3b4c1bd63, 0x1055ae3aea7f3ea0, 0x51daa1ba406f70a0, 0xa5cbb0bed18f3dff,
            0x31389d028a95a8f4, 0x0197e05ad2dd2b2b, 0x283c37159defa09d, 0x8aea69dd56503a42,
            0x17827792c4fb6a93, 0x27634a8287e533ee, 0x42a61f1d52a09041, 0xf55e68b8c35a2833,
            0x51af8374e6da3d34, 0x641f96247fa8d777, 0x80ef76a4,
        ]
            .span(),
        [
            0x20bcbb1ca01102f9, 0x67925507db2bd1e5, 0xf3074020206a7103, 0x0693de29246450a3,
            0x556e84a0b315bbae, 0x61cce6dfd549d968, 0x617ff5461fbb8bbf, 0xc8ec749cfa2956f7,
            0xd829a0623f6f77d2, 0x31913d58e359fb11, 0x13d1a443eedeafe1, 0x725ed5ee700b9d06,
            0x5aa084019392c689, 0x8f49b1aae6b0d370, 0x0992cbb3f26a0419, 0x9a122ae448871307,
            0xa0838b72145bf3e4, 0x0627a597c465efa0, 0x43d301d9560db318, 0x87b2938b4d411a43,
            0x0e20639b740ff077, 0xe99cc0de1f7acba0, 0x7fa5bced5c1a38ff, 0x7297a9878d8125a2,
            0xad609d5f4b835c11, 0x7ab5ff78e632a066, 0x6c41cad039b86c33, 0x2682940f225a9bcf,
            0xbefc0bb617777ca6, 0x93edf58b19a02d7b, 0xf84976a8ca78887b, 0x93b2e85984cb4f3d,
            0x29ecf7c4aeab76e7, 0x15e72dffa0e40338, 0x8d83d43092f5f6e5, 0x21281b18fd22198f,
            0xffccf57a02cec2b1, 0x2b7089a0aa5e1abb, 0x4d52a917fd9722ee, 0x8db77e82727b1e69,
            0x27aae132d0b113ca, 0x4973a0909b6032c9, 0x69a6931af724d369, 0xc3107e92e13d3826,
            0xdecad86c4e23ee59, 0x92a0285369d34cf8, 0x97462210d1e7ed45, 0xba8d15e7a5a180ac,
            0xfdb7fd07d2b96743, 0xa0814fc3bfdbf30b, 0x1370987dabdc3c53, 0x89d1d86d642b74a5,
            0x079bf6630f3d722f, 0x9110b68a5a7d2a50, 0x598b4b80209fb8a0, 0xdb802b799155517a,
            0x8e8995adfcf13ca1, 0x6c106c08bd0a8973, 0xd76118a50d6ba0cf, 0xd521a2415138dfcd,
            0xf29d18a54406b423, 0xbd104602a605537c, 0xaa7171b721a0f753, 0x3a54b135d6414aaf,
            0x0d14ccae0a6a25ec, 0x6dd67dc2187aceac, 0x804fe9a9,
        ]
            .span(),
        [
            0x400b59d7a01102f9, 0x60965a57e3218682, 0x723382c5fc1e6652, 0x9059d908c36c58e6,
            0xcad363a0eb75f313, 0x46807e18389e3db9, 0x525253b3ad56f0fd, 0x366b197047858330,
            0x77eea07ed3159a39, 0xbb16801794411e65, 0xf917a96b2c8a3467, 0xa49661cb8682a91c,
            0x46a0345fd4d785fe, 0xf8e527f816bceeb3, 0x6745f44a8341e38d, 0x33aeef8d9a1b25bd,
            0xa0497269e5baa2b9, 0x1657117704aabe3a, 0x60a80f7f3b254647, 0xf24f1bc19d7c9220,
            0xa93dbf86a1820f94, 0xd74c052ccc3f14a0, 0xcdc43ac474f927a2, 0x61decfded96542bc,
            0x31faf6f2f1a24e60, 0xba5aa512ab86a0b3, 0x0b65f68f17ab902b, 0x7a36e64566fee690,
            0x1ac12f5899dcb78e, 0x77dabba0c8a023b4, 0x3ec28f6912a4f97d, 0xa4b2bd120862dc7d,
            0xb842a6eadcadad57, 0xe51bcf8da0529aaa, 0xdfa39e6ba75e550a, 0x6790d1f90b43af91,
            0xcb93538e4fb4d945, 0x2d26cea0773e1b96, 0x05d1984e0b22c137, 0x1c8306f391724129,
            0xd786c61673f5923b, 0x4795a0517cf66b35, 0x1c77f458ce7a3a38, 0x3addc677dab374e9,
            0xcbea611ff87bd87e, 0x94a0adf34238951b, 0xc59b4b3fcbae1747, 0x964fc3e4b66ceeb5,
            0x8cada50a36f37e4b, 0xa0193201da583ee2, 0x6aa154856cd11f26, 0x23a617c5bf9944eb,
            0x6ac93006d0fa81a9, 0x0ae1589999c4671a, 0x7f5c477232d53ca0, 0x526dfc6442612386,
            0xff09fe323cecbccc, 0x8484119a0d1a84f4, 0x43b9f38584dba05a, 0x462475a6fd2cc287,
            0xf814559b5764c242, 0xa403fe92171f4c57, 0xa11f5526c7a0ab78, 0x73d7e684ba2076f1,
            0x9d62a9bc3fd10fb4, 0x97b0e55059b697b8, 0x80557125,
        ]
            .span(),
        [
            0xcf67fb4fa01102f9, 0xcd4679338eedcdb6, 0x9f63100606dd0c4e, 0x4df4f7a7d17341ae,
            0x360eaca09dab3830, 0x237675a0cde5f17c, 0xc518cf282c207fb5, 0x2b46ae246795d10d,
            0xc6c8a0a68a39fcb2, 0x2ea2e22bcb66f0b8, 0x676aed3bf9aa0b03, 0x21ed0c56a90d3816,
            0xb8a05b0123189be3, 0xbc35c0b98f339b45, 0xc792db833a442206, 0xe40fbe17f4cf177c,
            0xa00a80f8e698572a, 0x14a9a143bd0eb2ff, 0x43a1dbe4938fba5f, 0xf0b7c7af5f66611d,
            0xb720f8346c883910, 0x89f68dc17a60a9a0, 0x85660cabd9a8b38d, 0x65c38f185d0c2c53,
            0x7869ff91e2f4e190, 0x78225b6943ffa05c, 0xe5dbaa4f58488ba3, 0x7e96b6cd62e70ce5,
            0x02df0df1cf5355b3, 0x64d752a027a0cb08, 0xc9af584f78e0feb7, 0x522396ca87eb4572,
            0x7241d4d8d1e49619, 0xdb3df8f6a07f5215, 0x464c0311dcd1e5b6, 0x872ad2caf0d3892a,
            0x7a6465de6af3a3f8, 0xb04aaea01c9769c4, 0xa3ba69b5d9ba546a, 0x0abcbbe4fd5bf6ee,
            0xad32e7032c095657, 0xd7bca0cd3d535c7c, 0xb1c2c4f6cca32bba, 0x062985cc56bbd0d3,
            0x3624040a5bb0c11c, 0x6ea063535746d766, 0x5d128f6efacebe63, 0x8a041bf2996a0a3d,
            0xf71e9efbc0d6a92a, 0xa0911263dc38a62d, 0xaa74034a545f2d0c, 0xa137bb0fb370963d,
            0xb27c7da706887e3e, 0xb0e3d7787fff7ff6, 0x0e2567b0c618e0a0, 0x64b7ef6f63fcfcb9,
            0x8d577b586d18f7a7, 0x611f988c91ac6b53, 0x597b1e731b0ba055, 0x3ca6e2e866820130,
            0xfb69effe6c814720, 0x95e2b08332d1a56b, 0xc0dc176b81a02af4, 0x719dd2802b1c2f0d,
            0x1433f383e2d52c7c, 0xab4f03334a08df7d, 0x8063237b,
        ]
            .span(),
        [
            0x1a819e8fa01102f9, 0x024878406a6da772, 0xbd70fc955db56796, 0x90195222da3658bf,
            0xa62dd7a02b65321f, 0x786ed9dcc3a469da, 0xc7fb4abf002c81e8, 0xc64274f01aee64f1,
            0xec62a0eda60a98a2, 0xd267aa7e38fcb1c2, 0xd7fab8f93275664b, 0x9e42bb578dbf0a3a,
            0x9da0cc28baf7029e, 0xdebae34bd9c450aa, 0x25c07468cab277c1, 0xe3840b0dc1eda08e,
            0xa088718114ed3f05, 0x14de9f2e46196c77, 0x9b1378b9f37ba322, 0xaf340de37044c863,
            0x0d2f3089b9e0f3cf, 0x1c5d874e11aadba0, 0x550303253b508bdd, 0x67f31e2a21a184cf,
            0xa14b6b8c8ce655a5, 0xe3cbddb85dc8a066, 0xe55a62ee1cd18a75, 0x5d75e8eae2e9d558,
            0x193973324671b736, 0x66fb79ce97a0d17d, 0xc184fd68f2aa85b3, 0x627609006f57148b,
            0xfeb4ae0481729d9c, 0x69bceab0a043630b, 0x4aeb4f762b59b9a4, 0xb0fdf5550f649c4d,
            0x7984c0de742e7ae3, 0x0b781ca017cc96b9, 0x7a4904b75b9cc989, 0x434d3538daeae56e,
            0x95f408df59528dad, 0xf56da086aac5b710, 0x67afa23592b32fb9, 0xbf73310c2382737c,
            0xfed3d78727256a42, 0x07a0f9e3dded6cf8, 0xcd19428f25a92624, 0x16fc6e0cd25e9982,
            0xc4c5ba0bbdb598f6, 0xa0ecf5b158eb58a0, 0x7d29a892bc57a7a0, 0xbe25de42be4c45e6,
            0x0201235921062996, 0xfbde33a0b74d90a4, 0xac8194b6526584a0, 0x8cf398a099ab4aca,
            0xa3a9ead6eb088040, 0xd9558c70eb05cd68, 0x2f2edbdea57ba003, 0x73760f88d02d5ebd,
            0xf09b20ee87896714, 0x552cf6719129232e, 0xb7d279ae46a09a2c, 0xf1ea2d319912cfdb,
            0x6c77f4fff814b3fa, 0xd1717ab976668e79, 0x80c4594d,
        ]
            .span(),
        [
            0x132b35d8209e67f8, 0x052acf32dbca883e, 0x24fc63fc557ff4d7, 0x14cd48348c0ef2fa,
            0xa0800144f846b887, 0x92d30177c7529e1e, 0xef157f06b36e35e3, 0xaa38f5d5835aa22d,
            0x45de5dcfa26ead29, 0x17f987427aa2ada0, 0x9a7c97d5a4234d1a, 0x2daaf60689713d58,
            0x0673399c73247f6d, 0xf2,
        ]
            .span(),
    ]
        .span();
    (account_rlp, account)
}

#[test]
fn read_header_fields() {
    let mut contract = HerodotusStarknet::contract_state_for_testing();
    let (header_rlp, _) = get_header_sepolia();
    let result = contract._readBlockHeaderFields(header_rlp);

    let expected = [
        0xcb6ff9acefde9a869c91b6d044234b32fe644293771bd0613a61646386a6c86b, // PARENT_HASH
        0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347, // OMMERS_HASH
        0x3826539cbd8d68dcf119e80b994557b4278cec9f, // BENEFICIARY
        0x3a827d3e682bd3f8f03372542a9b85e22d8acaa3e4f970794d580859466692f3, // STATE_ROOT
        0x7803433904e98135796cd5db83dd3935ecc6cfec4dd94495f87635f5cc91b1be, // TRANSACTIONS_ROOT
        0x1e4bc53e197d4d7c6525b5e46997fdf35b876539b8ef0775228320514d01f8e7, // RECEIPTS_ROOT
        0, // LOGS_BLOOM - not supported
        0x0, // DIFFICULTY
        0x8087dd, // NUMBER
        0x393861c, // GAS_LIMIT
        0x1e3c9d6, // GAS_USED
        0x6836c100, // TIMESTAMP
        0x626573752032352e342e31, // EXTRA_DATA
        0x93096344a9561b19609c21cfc40f0874b59be1b4382e89125cafaa8ae37e7622, // MIX_HASH
        0x0000000000000000 // NONCE
    ]
        .span();

    assert_eq!(result, expected);
}

#[test]
fn prove_header() {
    let mut contract = HerodotusStarknet::contract_state_for_testing();

    let chain_id = 11155111;
    let (header_rlp, block_number) = get_header_sepolia();

    let header_proof = create_mmr_with_block(ref contract, header_rlp, chain_id, 211);

    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::PARENT_HASH),
        Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::OMMERS_HASH),
        Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::BENEFICIARY),
        Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::STATE_ROOT),
        Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::TRANSACTIONS_ROOT),
        Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::RECEIPTS_ROOT),
        Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::LOGS_BLOOM),
        Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::DIFFICULTY),
        Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::NUMBER), Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::GAS_LIMIT), Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::GAS_USED), Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::TIMESTAMP), Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::EXTRA_DATA),
        Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::MIX_HASH), Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::NONCE), Option::None,
    );

    contract.proveHeader(chain_id, 0b111111010111111, header_proof);

    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::PARENT_HASH),
        Option::Some(0xcb6ff9acefde9a869c91b6d044234b32fe644293771bd0613a61646386a6c86b),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::OMMERS_HASH),
        Option::Some(0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::BENEFICIARY),
        Option::Some(0x3826539cbd8d68dcf119e80b994557b4278cec9f),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::STATE_ROOT),
        Option::Some(0x3a827d3e682bd3f8f03372542a9b85e22d8acaa3e4f970794d580859466692f3),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::TRANSACTIONS_ROOT),
        Option::Some(0x7803433904e98135796cd5db83dd3935ecc6cfec4dd94495f87635f5cc91b1be),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::RECEIPTS_ROOT),
        Option::Some(0x1e4bc53e197d4d7c6525b5e46997fdf35b876539b8ef0775228320514d01f8e7),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::LOGS_BLOOM),
        Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::DIFFICULTY),
        Option::Some(0x0),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::NUMBER), Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::GAS_LIMIT),
        Option::Some(0x393861c),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::GAS_USED),
        Option::Some(0x1e3c9d6),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::TIMESTAMP),
        Option::Some(0x6836c100),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::EXTRA_DATA),
        Option::Some(0x626573752032352e342e31),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::MIX_HASH),
        Option::Some(0x93096344a9561b19609c21cfc40f0874b59be1b4382e89125cafaa8ae37e7622),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::NONCE),
        Option::Some(0x0000000000000000),
    );
}

#[test]
fn prove_account() {
    let mut contract = HerodotusStarknet::contract_state_for_testing();

    let chain_id = 11155111;
    let (header_rlp, block_number) = get_header_sepolia();
    let (account_rlp, account) = get_account_sepolia();

    let header_proof = create_mmr_with_block(ref contract, header_rlp, chain_id, 211);

    contract.proveHeader(chain_id, 0b1000, header_proof);

    assert_eq!(
        contract.accountFieldSafe(chain_id, block_number, account, AccountField::NONCE),
        Option::None,
    );
    assert_eq!(
        contract.accountFieldSafe(chain_id, block_number, account, AccountField::BALANCE),
        Option::None,
    );
    assert_eq!(
        contract.accountFieldSafe(chain_id, block_number, account, AccountField::STORAGE_ROOT),
        Option::None,
    );
    assert_eq!(
        contract.accountFieldSafe(chain_id, block_number, account, AccountField::CODE_HASH),
        Option::None,
    );

    contract.proveAccount(chain_id, block_number, account, 0b1111, account_rlp);

    assert_eq!(
        contract.accountFieldSafe(chain_id, block_number, account, AccountField::NONCE),
        Option::Some(0x1),
    );
    assert_eq!(
        contract.accountFieldSafe(chain_id, block_number, account, AccountField::BALANCE),
        Option::Some(0x0),
    );
    assert_eq!(
        contract.accountFieldSafe(chain_id, block_number, account, AccountField::STORAGE_ROOT),
        Option::Some(0x1e9e52c77701d392e3356eb3067f15ef2da25a83d5f538aa29ad6ea2cf5dde45),
    );
    assert_eq!(
        contract.accountFieldSafe(chain_id, block_number, account, AccountField::CODE_HASH),
        Option::Some(0xada27a4287f9171a4d23a4d5977c9a583d718906f6aa2d6d7f24739c397306f2),
    );
}
