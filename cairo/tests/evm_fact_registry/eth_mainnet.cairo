use herodotus_starknet::{
    evm_fact_registry::{
        evm_fact_registry_component::{EvmFactRegistryInternalImpl, EvmFactRegistryImpl},
        BlockHeaderField, AccountField,
    },
    mmr_core::{mmr_core_component::MmrCoreInternalImpl}, receiver::HerodotusStarknet,
};
use starknet::EthAddress;
use crate::_utils::create_mmr_with_block;


fn get_header_mainnet() -> (Span<u64>, u256) {
    // https://rs-indexer.api.herodotus.cloud/blocks/?chain_id=1&from_block_number_inclusive=22578043&to_block_number_inclusive=22578043&hashing_function=keccak

    // def format_string_blocks(s: str) -> str:
    //     return ", ".join(["0x" + "".join(reversed([s[i + j : i + j + 2] for j in range(0, 16,
    //     2)])) for i in range(0, len(s), 16)])

    (
        [
            0x58990cc3a08402f9, 0x23a1a95a6fc44c69, 0xfb91fd670f3c4e3d, 0x98bd5ca850aac9ad,
            0x4dcc1da0a30573c8, 0xb585ab7a5dc7dee8, 0x4512d31ad4ccb667, 0x42a1f013748a941b,
            0x6339944793d440fd, 0xe01cdaa4e22b3643, 0x82fb46539410c2c1, 0x89db469aafa049aa,
            0xdd52cd4ffca52cbe, 0xd506254e5a4c0c6b, 0x58b94e32cd7e7be2, 0xd49feedaa0c7e194,
            0x0a19a358973497c7, 0x36549c7711f98e0f, 0x75b447399f9fd1aa, 0x19365ea050fdfe65,
            0xdda1b28f30c1889b, 0xe53fd26f9f26ea6a, 0x65b68a82380502cd, 0x0001b9902e3672b4,
            0x04cb126d7259f0d0, 0x02500183210a2128, 0x4410581521a5c81d, 0x4388708c00512805,
            0x84286822a0031204, 0x1d85ce19492a9032, 0x19201188c8853c92, 0xee292590c2428421,
            0x2b19422001542605, 0xe02171e48a610429, 0x8a8c4425713a0408, 0x4001c0be2e400028,
            0x68006ecb00784127, 0x2d2825598091080c, 0x478e8127c02c4280, 0x45078d31555e8a78,
            0x02d06984845f011e, 0x4703f3106580a544, 0xd970a1d1a1441904, 0x99729460d0e262b0,
            0x1368913b7215460a, 0xdbec06a9e200114a, 0x0040e0542448022a, 0x57214ca413aa3315,
            0x153958951b54922b, 0x80bc080872d48401, 0x328e2111c624ae26, 0x426014cd564c4f07,
            0x10c04241582d3c12, 0x52464be28e520d90, 0xc51848512c640425, 0x943109105c820030,
            0x02847b8358018480, 0x846be18e838bc724, 0xa89ce29beb683668, 0x2072617361755120,
            0x2e72617361757128, 0xa89ce220296e6977, 0x67ecec69dc5b4fa0, 0x249a5a1e0413f36c,
            0x4ad8ceefa23ea896, 0xa5a2bbe84d962bb1, 0x0000000000008818, 0xa0acea203b840000,
            0x368a7bd42466cc3f, 0xf069e86306aa37ef, 0x455be475a531efb8, 0x0e36e75b49a99d58,
            0xc089a08000001283, 0x27c4e6a269349eb1, 0x30e8a4288e44d308, 0x6cfdb7b78ef98ee9,
            0xe3a0ffde03de9b7a, 0x9a141cfc9842c4b0, 0x2724b96f99c8f4fb, 0xa44c939b64e441ae,
            0x55b852781b9995,
        ]
            .span(),
        0x158837b,
    )
}

fn get_account_mainnet() -> (Span<Span<u64>>, EthAddress) {
    // curl https://eth-mainnet.g.alchemy.com/v2/API_KEY -X POST -H "Content-Type: application/json"
    // -d '{"id": 3, "jsonrpc": "2.0", "method": "eth_getProof", "params":
    // ["0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", [], "0x158837b"]}'

    // def format_string_mpt(sl: list[str]) -> str:
    //     return "\n".join(["[" + ", ".join(["0x" + "".join(reversed([s[i + j + 2 : i + j + 4] for
    //     j in range(0, 16, 2)])) for i in range(0, len(s) - 2, 16)]) + "].span()," for s in sl])

    let account: EthAddress = (0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).try_into().unwrap();
    let account_rlp = [
        [
            0xcf2a32e5a01102f9, 0x7ddc2f36df0fffda, 0x1cec8683409d989b, 0xf135e04fed707d41,
            0x1adfb6a018302460, 0x0dca001df74965ff, 0x1525c5eff197869e, 0x555f335da54be3b2,
            0xc703a082c5d328c1, 0x5d792d7c8ceb9e94, 0x19ef687c468943dd, 0x31e4b2b00cd2e7b8,
            0x01a0db7ae21d7d40, 0xa0f314c56862a881, 0x2ff910f24e48b567, 0x1f9a7d97dc0d195f,
            0xa03e70a4ead2baff, 0x421a1800f9744171, 0x863abbccbdef24cf, 0x061bc190b35bce6a,
            0x77930e8c4bdf253a, 0x991a79b9249efda0, 0x785394ed131bf132, 0x3d1f49be65e6ff9a,
            0x3521f308d76e01df, 0x441d2822e058a080, 0x4e0f8752a7aef9d6, 0x1a2db9ea058123d4,
            0x1c5604ce705e1b02, 0x373285473fa020fe, 0x0946a9e78ceec48d, 0xe971b5e1532f78bd,
            0xeef8c0486d695227, 0x38e0d383a010c992, 0x63f902deca7e0799, 0x4b3b8d729b96a8cd,
            0x52d715602c8c7b8d, 0x9e3432a09bd51f32, 0xa9be69f4c2805a23, 0x1528f5710e430371,
            0xdb24fa65a5748af5, 0xcba5a0a7e525a8be, 0x88a400f0125ac754, 0xd5172eb8ad4ca9ae,
            0xf1ac90e2f0e42a68, 0xd5a04154f940f543, 0xb8a945224b75dbc2, 0xbfefd8a7eb18efad,
            0x2fabec43aee12c07, 0xa0ae84cdbcf79f02, 0xccbb1d5714ba5b54, 0x95752e850a7bd80a,
            0x1325c55dfb3cae48, 0x20ba32dd5e8eea15, 0xfab1563a1c24dca0, 0x7f843c40574acaa2,
            0x498b1cd4fe62da37, 0xadd630a63100be2e, 0x08b12decaf10a0ef, 0x20434104d220d97e,
            0x96225e56873fdd82, 0xfd1af7fb55f1dc30, 0x0317fc65eca0c34c, 0x0d86e8ef3e5cb1ac,
            0x05e0d80fc58ff0c5, 0xe6e992e74e0ff356, 0x80e3ad66,
        ]
            .span(),
        [
            0x553c5af4a01102f9, 0x0af8925a80b2cb7d, 0xde85b7fb0dfe1ff3, 0x029a840be4ee19d7,
            0x338b2ca053e1b8ab, 0x0da4b1849d7f4c2d, 0x0b1249c99e4c41e6, 0x41a8bbcf907c2024,
            0xd91ca0a03e605620, 0xe468699e5ac0e6a3, 0xa8770f8bbf479eb0, 0xed4832fa751ca614,
            0xe3a04ed29fa19ead, 0x6b40c85e987a0163, 0xc07eb4555c14e992, 0x04a6a48ce318c17b,
            0xa0cad5ea714d8c85, 0x1f8b8b3ed6c96e10, 0xd140a8f45bdac327, 0x24f6902ad520a082,
            0xc0dff656fff63f5c, 0x313e140a5c25bfa0, 0x2ac67fe48fa8e3bf, 0x05df03c6437f52d3,
            0x0fd4e83a46076118, 0x4bafe723458ca082, 0xb1b7aa8f76fef9b3, 0x37219aebf917a426,
            0xe5afbece6c6d8a22, 0x2d6a1150bfa0af42, 0x8bcfa735f8ead92b, 0x09500885fe5b9dac,
            0x5938125af7effeb5, 0x1edb0d40a0860983, 0x311f58abf421a4db, 0x67828259491fd1b5,
            0x1f394de15f1de2d1, 0xcacd50a052aa31c8, 0x250e10567f2b879a, 0x8bd9029342b89359,
            0x21e36c60e98e5e4e, 0x2845a0ae72cdec91, 0x000dd7c9342e4a5a, 0xd956386b67de4e92,
            0x28a36cd677587431, 0xd6a03ab59ce97890, 0x123693f882ef444a, 0xb4e0bdc8909b4d3c,
            0x5b64684d8c92666f, 0xa0fd20bef19be477, 0x808240390f368830, 0x5cdf88c94e363f52,
            0x5e633e367756d010, 0xa13bb1b65784efac, 0x1a0062ed35adb6a0, 0x448e6658b1da78cf,
            0x3ef60b8a34f3a9bd, 0x7682c537e0fa3109, 0x549e36f43573a029, 0x8a0d3cda46ae22d7,
            0x60b5dc1d0334ab9b, 0x4bb0121d3007fed4, 0x2ed3ce67eda0c639, 0xbf560bdd78e2921c,
            0x744c8314e6ff3921, 0x46c96739e875a31a, 0x8034bf78,
        ]
            .span(),
        [
            0x6b4dce75a01102f9, 0x829648507a778233, 0xb6a77df9674be090, 0xfd8ba7b9ced82e05,
            0x14e855a06a8e702b, 0x6b11d667d60e29fb, 0x622bcdc72916461d, 0x17981b51d35b4a19,
            0x5cd0a0556398b861, 0xebb0ad00b9224455, 0xc501331fd2673805, 0x9e81262c2e199fcb,
            0xb6a004e2c66ed9e4, 0x19b594a4a7333e5d, 0x2eaa8f714379c0ed, 0x1c8008ab2b4b4df6,
            0xa0097f571e268bf8, 0x6ba82363eb1d4926, 0x336ded642ac2fada, 0x3be2a28ce79bbe3d,
            0xa8962e2ebe2bdaa8, 0x2eb80504f9fe55a0, 0x496db58ad9c442c9, 0x6ff4a1aa42e91bf4,
            0x80c04fafea7cd3ed, 0x870fc9243f28a0ab, 0xe5625042257dcf4b, 0xb51782fe15c3fc5c,
            0x3e31cbe5e69b551a, 0x5cbaf3d755a0c4ec, 0x9bf042731c4efea6, 0xb2030220efb12395,
            0xc006fa406925741d, 0x751651b4a09647e1, 0x2efe47627688a8cd, 0x8c2bbf4c08410182,
            0x1e2348cc2a0ba0f6, 0xa95283a0480e0fcd, 0x0a58faa1ad78de94, 0xf81522c0b026d9c1,
            0xe7bc90c57dafbf90, 0x9c56a0171d2367e1, 0xbaf4accf723cb022, 0xb5eb53d43fa086a7,
            0xc5389662e70dd016, 0xdea03bc576adb67b, 0x5c216f3711658fc4, 0xfb0e647625c81e9c,
            0xc79579b43aba2469, 0xa03d1774b6bdce31, 0x89c9401ef01d1511, 0x8661d4118b4eabfd,
            0xb7aa03b977b84747, 0xb6709e8bb8027ff1, 0xfa33c7770fa419a0, 0x4fd3465ce232e0ca,
            0xc6f8f6001c69beac, 0xce6f98465dd27835, 0x5f7bc4717c40a03f, 0x1ea867a4a365c16d,
            0x8f953dc89c382f29, 0x9573544a272b67c4, 0x2d5220720ca078b6, 0x801482f1f5289eb0,
            0x7c5f6f8e5d3d6a16, 0xc7422d05a2fdaa8d, 0x803861c4,
        ]
            .span(),
        [
            0x865d1c9ea01102f9, 0x467bf5369b237b88, 0x927bb7bcdd14c18a, 0xe7aa01e40eafbed2,
            0x6c51d3a0f9a4bfce, 0xf24dc0b173f4e0bf, 0x35b62f83d45a2a37, 0x4dad30961e8e9e78,
            0x4279a0e4ab22e7b4, 0x168cf0e32108690b, 0xd07c87258d91a48d, 0x0e96f50beba95ad0,
            0xefa07817abaf9b26, 0x27e375cc6d8d3f90, 0x313cff3f387530f1, 0xcabbea248472d9aa,
            0xa0c58d63cfe9c2cb, 0xdaf18e4ebbb4ecf7, 0x491af344a75405a2, 0x5f0fb3ee026b6a12,
            0x8c890730f74c7837, 0x40d96027abbf9ea0, 0x64e210d5b6a37363, 0xe94a77e19ceb263f,
            0x91aa45c8adc54e55, 0x9ba8673165e2a09b, 0x9743ec3081e35d54, 0xee3964fbb72f63fc,
            0x61371ebf693a7cd0, 0x2eabc4f372a0eb41, 0x164c159d177ec971, 0x14e1035731b28b28,
            0x58cae44b1a99f516, 0x28b10adfa0e2d79e, 0x0b30ea22e84b31af, 0x3f1db0dc6edd6ec8,
            0xbc018169bc16682a, 0x2861afa082b364b8, 0x74085f2770ba8c1c, 0x64b875c1c2a73628,
            0x1e4db38e5964040a, 0x2f03a05d32648fac, 0x8a38bdf9ab269962, 0x10fc25739797f701,
            0xe9ebe36a31aa7370, 0x3ba05b97f1f5fe54, 0xe1685e39beca539a, 0x1f5f99081e750fec,
            0xcf01551107bd8ac7, 0xa0fd1f7059c2fbe9, 0x036f70e6eb25f0e3, 0xcb65547b73a39ba1,
            0x76d76b9426f3f215, 0xb80c952da955315c, 0x4d389f3ddb4bc6a0, 0x6b7771b372126a08,
            0xa97dc3af20853106, 0xc923b585d35175ca, 0x35b83319e1b0a087, 0x42da1f093cba263a,
            0xfc03cadc751b7bde, 0xa9fbcf5505f0ddf5, 0xd14e9494c3a06476, 0xe42250883510142c,
            0xe9921172a3e1a7fc, 0x2d5549a5a675730b, 0x80c38511,
        ]
            .span(),
        [
            0x7a835e0aa01102f9, 0x2e9198d3a599121e, 0x3ae18383025fa2ba, 0x1b8529ef6ccf5185,
            0x68e031a0e7787cd6, 0xb27711899c1757b6, 0x14ee6af7a77f9638, 0xd9044b1f5958bdc4,
            0x77c4a030917c416d, 0x57cad0b9cef9cf33, 0x266e06a8ba5f8eee, 0x61abc6b7afef438e,
            0x86a0428e4a4f80d4, 0x528b3ff0b1fabbee, 0xd13b4e0a3145c768, 0xae0c9520399c4915,
            0xa0890bd0f56387c7, 0x90095a795b6827a2, 0xee440f681096edc4, 0xba285d9c14f31e64,
            0xb8da5b41b434fc75, 0x4f9dcf4fd6290ba0, 0x2833539b502911fc, 0x38bcf0954fe9534a,
            0xfb2a9f1b1d569e8f, 0xeffbc1d46fd2a092, 0x56c951b516b3e745, 0xcd8da80476466531,
            0x58a6e0eba5e788e4, 0xd2e83351cda079ea, 0xe90bdf600aaf1bbe, 0x0216e4337321848a,
            0xd78e9ae59c5a494b, 0x467306c2a0ab0e52, 0xa98a0316de98eff4, 0x0981595357e92735,
            0xb0202f86e3b26d96, 0xc8309ca01381842c, 0x3a9bc349d1d9ec42, 0xc19a08be75c80482,
            0x490067dae2b4ad8f, 0x95a0a07f1dae2403, 0x19bc920ca330eecb, 0xfe22eb81b37314eb,
            0x1377e52b8b78228d, 0xe0a06ec6309b1b99, 0x24934c45f799570d, 0x137b4a3949fae446,
            0x1f321de8ceb19f9d, 0xa0985bd4a39bd4e8, 0xc082650dfa5f59ab, 0xce3511dad2e39311,
            0x741889baa540ead7, 0xe2bad74c155eb41f, 0xa932693eaa4faaa0, 0x1bdc124c306d10d5,
            0x943d0f61846abec3, 0x62c3ae658ec2219a, 0x31b9eb2c1857a0b0, 0x643f181afade81c3,
            0x35468db2a6ddd713, 0x4f6882b8355c0c7d, 0x5849646b9aa02bcb, 0x9d55cde1257f1cf6,
            0x9d249f3d03542434, 0xd4fbfe4c7f677c8f, 0x80c7bf7b,
        ]
            .span(),
        [
            0xe5e85022a01102f9, 0x43d036bb196c2b91, 0x37c99d75932dcef5, 0x8e3ae3c4ab673cbe,
            0x63cd7aa07ec268dd, 0x189f38ed4b9ac52d, 0xc5ea6771ed1b4a27, 0x132462d13e1a7e77,
            0xc753a03226875809, 0xb56742be12e8c8dd, 0xde2beb460d12dcbe, 0xb729eed1fa8f6228,
            0xbca06f1133458c50, 0xe7fcfcfc1c8b3d53, 0x60efa71a0d62131a, 0x756af2861110632b,
            0xa0f24ddfef399288, 0x18bed36bf70cf9ce, 0x5a9f21c9010351ce, 0x5f1b25135e421d88,
            0x1898833e7a7a6afd, 0x2513cbec0d4d28a0, 0x17c9724b5a0521c7, 0x011edf5a1d7ce4bb,
            0xb87a8802a58ff511, 0xd59699a8e6f2a0d9, 0x38d5ba5ab5c989f7, 0x18ba021577aab2d6,
            0xd8f04282cedf31a5, 0x58b218d7cea0389e, 0x5843ab27bd7b527e, 0xbd9b6906fe8359c5,
            0x7d8926f22ea4d8d7, 0x65f8b410a0055927, 0x89007f365a30f28e, 0xc49298fde1de3f52,
            0x352ae3f296280c55, 0x218bd7a06061bcfa, 0x77a106d667330416, 0xf8d134a5141fee8d,
            0x0dda3eb2fa568c2d, 0xce9ea0e545fba2db, 0x4db38fe062c04b46, 0xf780f2805eae750e,
            0x9a267a95873beca9, 0x0aa054eec609b2f4, 0x6d606d4e666e0580, 0x74075a12ce1d4364,
            0x3ffcc06814a77d3d, 0xa0592a020784024a, 0xbe539d98b9b5a589, 0x1dbe2e212483ab3b,
            0x6836a5cc3c298938, 0xfb0ef98222d69f6a, 0x1cfeac832c075ca0, 0x3ef9ffb97a257665,
            0xfe0d4b64275bb9d8, 0x9f523226542df5aa, 0xc8bc1f607337a041, 0xcbda80bc349723da,
            0xf72044abcf23a286, 0xf808371e96d352e0, 0x935f424ba8a00360, 0x7b3aad5e26ff9572,
            0xacac5b9f731d8fa5, 0xf755e88720a597f4, 0x80664b7e,
        ]
            .span(),
        [
            0x717e337da09101f9, 0xa84e5cf4e54ccd7e, 0x37f98ce36c474e99, 0x8ffa0cc44d92f2a4,
            0xe9983fa0e90f87e5, 0x1a4808ec72f16ace, 0x3f9364a289fbcf6b, 0x0e4c14828a28ee90,
            0x0f3aa0ff428e96ab, 0x1130488369390a31, 0xecc5862627b51078, 0x657dda4c76235dd2,
            0x80806cfcd02196e3, 0x7a276311ac574aa0, 0xf932d649e6da0b82, 0x543610805a88b317,
            0x2525b709946f21d3, 0x33c2de681803a0d3, 0xabd616fa0adc86f9, 0xa7a40f6b39228ef7,
            0x846a75808368f057, 0xd490e6bed3a0e24b, 0xb97a9a674d447381, 0xdec33ab89991cd69,
            0x2daac67d983ddb64, 0x484a745ca0e706db, 0x12f22d96e3c96e25, 0x07443bfe72c3b153,
            0x712ae14ea891e3b3, 0x02b1cca0a45e72cd, 0xd674874745b5fb37, 0x8d7027137aeb58e8,
            0x5d3a5d19c705c2e6, 0x3e90a0091296d5ac, 0x0e3e69b4041dd43c, 0xb04e02fef74915ae,
            0xc6ac7c131cfa986b, 0xd6a023e2a0a7576d, 0x36002038b074624d, 0xfc4c43581b210374,
            0x0f05aef5d68738a9, 0xa0f90b9aaed234b4, 0xdad7ea7179d629c3, 0x6caad99029221d9f,
            0x1e98c061d18b440f, 0x61662b29d7b104f5, 0x9bf39e4d2315a080, 0xd55d71b53f08af97,
            0xa4a33ca254442fcc, 0x18a93edecf1924d7, 0x80806c03,
        ]
            .span(),
        [
            0x48358a56a08071f8, 0x916d6cc6be68c4f0, 0xc07343e4842fd7b1, 0xa86bdc7e8d116e3c,
            0x808080800c4d9bfe, 0x29e126eca0808080, 0xbd48c7dca511fca6, 0x3ce6aca0414eca22,
            0x952b8e01deb21cbf, 0x9fa4a080c66fa085, 0x9658344be212c14d, 0x109bcb779c6dedeb,
            0x37c118f7b44d8ea4, 0x80808213f6b9b382, 0x808080,
        ]
            .span(),
        [
            0x3f7fcd92209d66f8, 0xccf602df97741378, 0xe082973da9ddbab9, 0xe08b72ba07c830f2,
            0x6da0800144f846b8, 0x9fba91afad2fedf6, 0x93799a85b5996607, 0x1d4ff2763b72cd3a,
            0xa085106bfdceb8be, 0xd6b90c897c4b0dd8, 0xb534bc526b3e89a4, 0xe01637b15c33256b,
            0x0515b4e68313d3d1,
        ]
            .span(),
    ]
        .span();
    (account_rlp, account)
}

#[test]
fn read_header_fields() {
    // https://rs-indexer.api.herodotus.cloud/blocks/?chain_id=1&from_block_number_inclusive=22578043&to_block_number_inclusive=22578043&hashing_function=keccak

    let mut contract = HerodotusStarknet::contract_state_for_testing();
    let (header_rlp, _) = get_header_mainnet();
    let result = contract._readBlockHeaderFields(header_rlp);

    let expected = [
        0xc30c9958694cc46f5aa9a1233d4e3c0f67fd91fbadc9aa50a85cbd98c87305a3, // PARENT_HASH
        0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347, // OMMERS_HASH
        0x396343362be2a4da1ce0c1c210945346fb82aa49, // BENEFICIARY
        0xaf9a46db89be2ca5fc4fcd52dd6b0c4c5a4e2506d5e27b7ecd324eb95894e1c7, // STATE_ROOT
        0xdaee9fd4c797349758a3190a0f8ef911779c5436aad19f9f3947b47565fefd50, // TRANSACTIONS_ROOT
        0x5e36199b88c1308fb2a1dd6aea269f6fd23fe5cd020538828ab665b472362e90, // RECEIPTS_ROOT
        0, // LOGS_BLOOM - not supported
        0x0, // DIFFICULTY
        0x158837b, // NUMBER
        0x224c78b, // GAS_LIMIT
        0x8ee16b, // GAS_USED
        0x683668eb, // TIMESTAMP
        0xe29ca82051756173617220287175617361722e77696e2920e29ca8, // EXTRA_DATA
        0x4f5bdc69ecec676cf313041e5a9a2496a83ea2efced84ab12b964de8bba2a518, // MIX_HASH
        0x0 // NONCE
    ]
        .span();

    assert_eq!(result, expected);
}

#[test]
fn prove_header() {
    let mut contract = HerodotusStarknet::contract_state_for_testing();

    let chain_id = 1;
    let (header_rlp, block_number) = get_header_mainnet();

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
        Option::Some(0xc30c9958694cc46f5aa9a1233d4e3c0f67fd91fbadc9aa50a85cbd98c87305a3),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::OMMERS_HASH),
        Option::Some(0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::BENEFICIARY),
        Option::Some(0x396343362be2a4da1ce0c1c210945346fb82aa49),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::STATE_ROOT),
        Option::Some(0xaf9a46db89be2ca5fc4fcd52dd6b0c4c5a4e2506d5e27b7ecd324eb95894e1c7),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::TRANSACTIONS_ROOT),
        Option::Some(0xdaee9fd4c797349758a3190a0f8ef911779c5436aad19f9f3947b47565fefd50),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::RECEIPTS_ROOT),
        Option::Some(0x5e36199b88c1308fb2a1dd6aea269f6fd23fe5cd020538828ab665b472362e90),
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
        Option::Some(0x224c78b),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::GAS_USED),
        Option::Some(0x8ee16b),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::TIMESTAMP),
        Option::Some(0x683668eb),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::EXTRA_DATA),
        Option::Some(0xe29ca82051756173617220287175617361722e77696e2920e29ca8),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::MIX_HASH),
        Option::Some(0x4f5bdc69ecec676cf313041e5a9a2496a83ea2efced84ab12b964de8bba2a518),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::NONCE),
        Option::Some(0x0),
    );
}

#[test]
fn prove_account() {
    let mut contract = HerodotusStarknet::contract_state_for_testing();

    let chain_id = 1;
    let (header_rlp, block_number) = get_header_mainnet();
    let (account_rlp, account) = get_account_mainnet();

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
        Option::Some(0x6df6ed2fadaf91ba9f076699b5859a79933acd723b76f24f1dbeb8cefd6b1085),
    );
    assert_eq!(
        contract.accountFieldSafe(chain_id, block_number, account, AccountField::CODE_HASH),
        Option::Some(0xd80d4b7c890cb9d6a4893e6b52bc34b56b25335cb13716e0d1d31383e6b41505),
    );
}
