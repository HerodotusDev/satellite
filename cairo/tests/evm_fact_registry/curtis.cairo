use starknet::EthAddress;
use storage_proofs::evm_fact_registry::evm_fact_registry_component::{
    EvmFactRegistryImpl, EvmFactRegistryInternalImpl,
};
use storage_proofs::evm_fact_registry::{AccountField, BlockHeaderField};
use storage_proofs::mmr_core::mmr_core_component::MmrCoreInternalImpl;
use storage_proofs::receiver::Satellite;
use crate::_utils::create_mmr_with_block;


fn get_header_curtis() -> (Span<u64>, u256) {
    // https://rs-indexer.api.herodotus.cloud/blocks/?chain_id=33111&from_block_number_inclusive=18179561&to_block_number_inclusive=18179561&hashing_function=keccak

    // def format_string_blocks(s: str) -> str:
    //     return ", ".join(["0x" + "".join(reversed([s[i + j : i + j + 2] for j in range(0, 16,
    //     2)])) for i in range(0, len(s), 16)])

    (
        [
            0x00c27185a02302f9, 0x82aeb05dc2836a9f, 0x2d6b74b2fa905cd5, 0x027189d9db1bbf98,
            0x4dcc1da0bd180c34, 0xb585ab7a5dc7dee8, 0x4512d31ad4ccb667, 0x42a1f013748a941b,
            0xb0a4944793d440fd, 0x0000000000000000, 0x636e657571657300, 0xe3fcfb5f24a07265,
            0x2f1c11aa5e05b21b, 0xd497f25d56ba5243, 0xde01bf0e85aeaa2c, 0x7e3168d7a03d923e,
            0xd9410fd87ce03226, 0x9f74e5c9fd9e7bdb, 0xcde07c4a63819abd, 0xb8943ba0c98b136d,
            0x69a852d9a6f41752, 0xba375bdf73645b96, 0x1a2e381e1d2b6d5f, 0x0001b9ba8f2f23ba,
            0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
            0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
            0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
            0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
            0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
            0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
            0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
            0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
            0x0487e96515018401, 0x0183000000000000, 0xa0c8d03a6884a086, 0xd716a60f2eca5d87,
            0xeecd45db8d13552c, 0x1b9c4f25cb8a0389, 0x797c0b5b332d607a, 0x124a0000000000a0,
            0xde800000000000df, 0x000000000000005b, 0x0000000000000020, 0x0e00000000008800,
            0x80969883375b,
        ]
            .span(),
        0x11565E9,
    )
}

fn get_account_curtis() -> (Span<Span<u64>>, EthAddress) {
    // curl https://curtis.rpc.caldera.xyz/http -X POST -H "Content-Type: application/json" -d
    // '{"id": 3, "jsonrpc": "2.0", "method": "eth_getProof", "params":
    // ["0xDd6B74123b2aB93aD701320D3F8D1b92B4fA5202", [], "0x11565E9"]}'

    // def format_string_mpt(sl: list[str]) -> str:
    //     return "\n".join(["[" + ", ".join(["0x" + "".join(reversed([s[i + j + 2 : i + j + 4] for
    //     j in range(0, 16, 2)])) for i in range(0, len(s) - 2, 16)]) + "].span()," for s in sl])

    let account: EthAddress = (0xDd6B74123b2aB93aD701320D3F8D1b92B4fA5202).try_into().unwrap();
    let account_rlp = [
        [
            0x935660dfa01102f9, 0xcb03b301334881bf, 0xa33e7cc1e45a6e87, 0x870540a753dfcd8e,
            0x337717a00feb1d4d, 0x6c1ff29c3c1e4997, 0x9d57566456576e3b, 0x527a1517f29dc3cf,
            0x12dea0e64fb310e4, 0x416ad29202061143, 0xdd1e95fc992966f1, 0xe8cacbda7809ac04,
            0x90a06fae13fd213a, 0x6925c8c234eab477, 0xa6b58a080a1e7c1a, 0x3763789035121e0c,
            0xa054e5bcb54ce2cf, 0xb35091e5fd9820c1, 0x0a96cf1adca8a149, 0x712132d62c5c6ca3,
            0xe5c9375c4356c752, 0x9e33f772a4c283a0, 0xda9dff764ccc7f40, 0xc191d35c1579b51e,
            0x012bcd9289100f1f, 0xbf104df52e85a050, 0x9a935de8a759ad83, 0x4b024f8a7fd4020f,
            0x37081e3696b7d50e, 0x969de54a6aa0ffdf, 0x1ff3c14e24d39a6c, 0x73537d747e94ff50,
            0x88a7a8c0665f815d, 0x3d162581a09fb2e1, 0xc36d559dd639a5e0, 0x8483c0e184fb7602,
            0x4543642f3b1db839, 0x420220a0c6e8ee76, 0x535b1768504efd25, 0x8526564a6966321a,
            0x96f61dbdf7efa097, 0x0f74a0c854fd2656, 0x8943c4aa0c362663, 0x5dfe58dac6328084,
            0xebe6ea5fd13e85ae, 0xefa06df0c1670a24, 0x5079bc2fba27bd12, 0xf70e44cbc8178c0e,
            0xc4f19dd590c70781, 0xa0dae204b87abd72, 0xcff9b22c915b66a4, 0xb69bc8834e2c0a5a,
            0x8df711f7a26e0d17, 0xa2aeec8b10ababce, 0x755d545db27775a0, 0x14a96f3172dafa52,
            0x26cb50647de3aa13, 0x4f901ba060fc85a0, 0x19f4dec74c95a0b3, 0xb96b8cfacd2cb7ab,
            0x0b0a02ebc381c169, 0xf5ae56e5fe343f03, 0xd9f059e1b0a0e9ca, 0x0c9086d1bc2ef35e,
            0x7dcda937e7f5fdd5, 0xad8bf8d5ecfa6df9, 0x804eb842,
        ]
            .span(),
        [
            0x4a828609a01102f9, 0x21dc347dc420f7ad, 0x73643eab4d242c7c, 0x7759855764c6ca46,
            0x83f1f0a0d5f5f893, 0x75d759d9cc29ac5c, 0x014437f1e43c8b43, 0x142396c648ad99bb,
            0x3820a0d208a7e102, 0x7c77255c83c5c3a9, 0xe74f26ec5b0ac69d, 0x5c7cda673b7bb515,
            0x98a0a90aaddc904a, 0x773b505f56dcf0ed, 0x38d125b24a52b6e3, 0x20531775ab0fff68,
            0xa0faa157982350ad, 0xd52cc1f181f43416, 0x6c317642eec3f5f2, 0x96ccb7afab42bf7e,
            0x1d36c5d399a45e3e, 0xdd711b69fec253a0, 0xc17aeb927e8b354f, 0x4b2d82fdfaaa8891,
            0x1d29f159fe0d1a20, 0x8b49ce9f37d5a02f, 0x1c3671ea94d0ec32, 0x0e8b1c9526a89549,
            0x64c51501b4aa338b, 0xd29209ea70a0a29f, 0x2906bf072412b083, 0x53d905f50a957ae3,
            0x7873297a37e40249, 0x0a5eff3da0d8a951, 0x5b6b48cb557b4d3c, 0x37101032e588be96,
            0xc8e99f836f2ee322, 0x61d27ba084f3228c, 0x9a1887c91521a6b2, 0x61e57f7562705277,
            0xab5c3c24b98a4ad3, 0x6ebca05f7c842507, 0xaa80327185a50029, 0xbe200d99225bd531,
            0x7cf52c70eb51f26a, 0xd0a0cb3ea0b90962, 0xa500cf391dd422af, 0xf9a883f1a1d20c91,
            0xf81d70a0487e9c63, 0xa0e159055a422b4d, 0x4eaece3935b9b448, 0x82c6ac562695315d,
            0x3b057a5585a857e4, 0x55cd57cb022554ee, 0xbdd4e3e8ff3a84a0, 0xf239cd32860d2dbc,
            0xa765bdf2ce1aed3a, 0xda11e8fba3508731, 0x838577df9a83a064, 0x3a7ebf30a3a1b037,
            0x6ae7756a274daf2f, 0xe45697d86562d989, 0x680100e188a0af4a, 0xf140928d58f66471,
            0x7559b02c9e6ff899, 0xfd2d4b63d5f6f0ae, 0x80eb44e7,
        ]
            .span(),
        [
            0x229796f3a01102f9, 0x480f77be10141847, 0x875551d33a6c2979, 0xccc624b172943ce8,
            0x5e44bea079649028, 0x15dee4767e19e3e0, 0x8009ac47db44fb62, 0xcd9eb006d5838aa9,
            0x322aa0e93af63a3c, 0x7cddfdd408365de7, 0x0153f43f7669c673, 0x96e9205922875edf,
            0x07a01fee5abdd35a, 0x2e235f17abb123be, 0x9c65b681d38eddd9, 0x20fe2b766fb29961,
            0xa0546c7b353375f6, 0xf893cc5e65338cc5, 0x03e712803c93f014, 0xb4f67a4a450dd1dc,
            0xc3f5f3e189b75998, 0xfb4b70fa68bd3ba0, 0xe5563582be387c36, 0x59d1df55479add35,
            0xa7de374bb06ef2ee, 0xe9f7815e46b4a003, 0x86b787e42769f2a9, 0xe9e2f12c8c2e4e44,
            0xa7c5fdb6eb9a5753, 0x41ed293cd8a0bf2b, 0x5d2cf6baf9717fd7, 0xf6de83dae682ed99,
            0x2f6728b32e9d0132, 0x8b0e7356a04a9f99, 0x9f109b4f8cba78e6, 0x646ed0fd7195770d,
            0x4d7e3cfe966bcd32, 0xd4738aa073d1f764, 0x6dc602cd3dd4106b, 0x788318fc1bea0177,
            0x6a0993f5b3a001da, 0x184aa01f1380a7b7, 0xbda51e5f5c67d9f5, 0x4ce183fe7df9156f,
            0x4d0fcc4e7704727f, 0x6da071e3aafd7223, 0xa06c2fd026771950, 0x5c10ef036cf5872d,
            0x6b84518e0cb96eea, 0xa0c893b7c58d0549, 0x62333cad2b54b278, 0x987a4a2b08af1e54,
            0xa581a3e742fdcf74, 0xac376e3111637004, 0x582938fa0f0da4a0, 0xc667c7d0bc365c00,
            0xac5429978d0458bc, 0x97a9ec209dd98664, 0x5a8cb1fa20a1a054, 0xe6f9c71c7fa12fb1,
            0x3a0374b89f0e1a22, 0x502b0aa8eddde492, 0x1ea9901882a048b2, 0x03625e24a13fe496,
            0x2a0a0191f4474093, 0x42664af818a113b3, 0x8019eadc,
        ]
            .span(),
        [
            0x7f4ce25ba01102f9, 0x837218b27eb8c8ae, 0xcefee09f60da0642, 0xb6fb03025c6a5340,
            0x570d85a0b9ba5cf8, 0xc2fd0036428e3b4a, 0x7b138cc2f5e40d80, 0xaca54dbecd56e5e2,
            0x5c7da05d62f52886, 0x5b928a0ae970ff8c, 0x8d6ed9ba003a8f1a, 0x32381ad3ca4f7828,
            0x21a0a4f64137552e, 0x5daa6c11af959df4, 0x1b9aadaae3e969a1, 0x8284db7656bc8128,
            0xa015c44a4d5a0b75, 0xc320999e0fdbff5a, 0x638f8dde2d66cc21, 0x944b6018ed83ee01,
            0xbbfee58afbdd5c2a, 0xaf7793eab77d20a0, 0xf74ab59ad3ff6671, 0xf77045e8c2dcfd92,
            0x4596de45ad0d574f, 0x2d01cabb6cc8a0ea, 0xe3da20f75cd169e3, 0x99d159666803f0d9,
            0x271f4d43ebb72a0b, 0x24bb76efb7a015b6, 0xa6be431c01ebd3ad, 0x68c5cac35f3672d6,
            0xff2f52431662f50e, 0x8fe49adaa0cf268b, 0x5bc60554dd1acd85, 0x0e78113d436c8d5c,
            0x41956204504d88ce, 0xab35bfa04f38200d, 0xce228347780d4d5c, 0x1ed28f004c069e81,
            0x479eb89cc96c401b, 0xd9bda089c3a74981, 0x6613e38072ead58b, 0x97ad9b551df2c985,
            0x9122d6bf99faf6b6, 0x28a0b9638fd9f664, 0x6d013f9e8a490f45, 0x73b55ba48f537e4b,
            0x6853ba2eab1e20f2, 0xa08945ded275c343, 0x30d10c9324b5a015, 0x1ec360ef4a1b1952,
            0x68e4638ee590ff40, 0xd47528d42df98750, 0xabec4384da2a15a0, 0x251ea7e3df0b0f62,
            0x4f116b9d22efb01f, 0x10341dc706971d4d, 0x4cee157ee481a06d, 0x9867d4222250145a,
            0x0b43b1cb17fec7d7, 0xfff4c818508599ff, 0x7ec181cdb8a0f5a4, 0x348c2e410e6d0ea8,
            0x0879f894f7f4d53d, 0xe828c1328875e734, 0x80f297f7,
        ]
            .span(),
        [
            0x3d8f55a0a0f101f9, 0xa5380e4dfdce27b4, 0x9f8853588405962c, 0xa7bc2f64fe1b3844,
            0x58a07ba0b901e9d3, 0x3b6b0ca9af76b919, 0x72ef9a9b371b1b9b, 0xf4cbf4a589f0265f,
            0xcf30a059e15588f0, 0x5721cd5f34bbb324, 0x958fb941fdd8f1ee, 0xad78791b724751d0,
            0xdda09631bdd609f8, 0x8e57c7cf7e26b752, 0x6af264e831f0f584, 0xf78af115813fb9bc,
            0xa09fe09e12c14969, 0x2b24c6858770df20, 0xb5f8bc1f0652b8f6, 0x14f050c3dca797e8,
            0x37c62f4f8035bd1e, 0xdeb05e68f2cc13a0, 0xeebe4fef8f82d875, 0x7c02282396e79e98,
            0x1e9468a435ed9f40, 0x0631f2c16c27a090, 0x2151d56faa70e9e7, 0xcd35e43b73550a3a,
            0x59c5d967f057b2f2, 0x014d5ba376a0bc9d, 0x65826eed86e8284a, 0xf95134acced518d9,
            0xf407af909973c1b0, 0xee506209a03fa164, 0x3d45285a80c99c47, 0x72917062dbf19aeb,
            0x5fc4d49d8a4bfaf9, 0x1740ada0a439ec9d, 0xf90da92c39fa8b4d, 0xc2309ca9bb95e943,
            0x1c9bda0cf2238c1a, 0x1983a076a986617c, 0x11ebdf808579aa0a, 0x6fe39d029d761f5d,
            0xdb06be4a032b77c8, 0x4ba0b3af2001c7b4, 0xc224e13bef464e00, 0x40594dea93972eb9,
            0xa891497e98340ca9, 0xa0bde6c256496d4a, 0x7a278c9373449102, 0xb3b14eb021cc1ca8,
            0x7b32ec98760cf370, 0xf39deb93f78ed1a1, 0x1b3513dc0268a080, 0xc51aebe7e161cb5d,
            0x29edcc3b20e8808d, 0x8d397434304005b6, 0xa34081c16da02436, 0x17a6063a4380cf3e,
            0xb15e201d59d18232, 0x124cf853387c4c43, 0x80066d57,
        ]
            .span(),
        [
            0x99bbf5b6c0a091f8, 0x604e340006e86411, 0x65a032e70ae07fe4, 0x0259a67e88c8a949,
            0xf10ea0808027c6be, 0xe429c2f1454c22cb, 0x7daf0876861aae6f, 0xb7d7f22c73107ca2,
            0x808074f42c3d792e, 0xc356a727887aa080, 0x61d264deb75d4691, 0x8edd17d68b8cdca6,
            0x243e6b4eb52a75fa, 0x808080808080e929, 0x29087bcdbf2883a0, 0x8b0ed25e9e845946,
            0x043f04b50dc46afc, 0x178a7d7e95749d1f, 0x808058,
        ]
            .span(),
        [
            0x80808080808051f8, 0xa080808080808080, 0x7afaa115f12af6d6, 0x0df549e6deb14690,
            0x864acc4004215d0e, 0xf2031ec10a0bd660, 0xb5d88c59f149a080, 0xe7fa4e7bc30787f6,
            0xe7e9fabfab91c7cd, 0x3ca7f141dcb6ad60, 0x80d852,
        ]
            .span(),
        [
            0x748299603e9d7ef8, 0x6f019126e7322b63, 0x877c36ccd2b99d27, 0x1a1c1344003a4ce6,
            0x808001015cf85eb8, 0x0000000000009480, 0x0000000000000000, 0x6fa0000000000000,
            0xb6f89aea20ff22e5, 0xec4da284ee878ae9, 0xbaae3a7d667a5cfe, 0xa07ebc43b3e9e027,
            0x347694f6c8df0018, 0x042bfea6dfa1e2ce, 0x86969b208e81036f, 0x6b92a05e31c6d607,
        ]
            .span(),
    ]
        .span();
    (account_rlp, account)
}

fn get_slot_inclusion_curtis() -> (Span<Span<u64>>, u256) {
    // curl https://curtis.rpc.caldera.xyz/http -X POST -H "Content-Type: application/json" -d
    // '{"id": 3, "jsonrpc": "2.0", "method": "eth_getProof", "params":
    // ["0xDd6B74123b2aB93aD701320D3F8D1b92B4fA5202",
    // ["0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f"], "0x11565E9"]}'

    // def format_string_mpt(sl: list[str]) -> str:
    //     return "\n".join(["[" + ", ".join(["0x" + "".join(reversed([s[i + j + 2 : i + j + 4] for
    //     j in range(0, 16, 2)])) for i in range(0, len(s) - 2, 16)]) + "].span()," for s in sl])

    let slot = 0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f;
    let storage_rlp = [
        [
            0xbb84a080807101f9, 0xb85d2fc9c98d9e0c, 0x17c79766c1fae725, 0x3fce5aa756d776b8,
            0x2da0d7eda02e5ffa, 0x9affd0f5a7a7dcc9, 0x7cbfb6fd0efa7060, 0x748cdbf027a53b12,
            0xa04f0caa3594f685, 0xee7f80bf5aa2ef53, 0x6dc643ef279f335a, 0x816b926fc1dea8de,
            0x2c961d6c6f6c23cc, 0x1952265e91071ca0, 0x07ad344dc51e8984, 0x5f7ca82f2ea7c155,
            0x28b6ec423127924a, 0x08ec27c4bc0ca0bc, 0xafbd439b334f0b89, 0x07a98ef9b8ae6f6d,
            0xc3e66a7ba8edce29, 0x740efb35a0809cad, 0x7515f7959a3f2c44, 0x79a049669a5cb2dd,
            0xa11f2c6218cd0bd5, 0x572c9aa035d29af8, 0xeed3e03113c6b936, 0x67acd03b3aad031f,
            0x18a1923645cf89d4, 0x6dc6a08ae3c47b38, 0x1e33e3b74e9c8663, 0x2ec5a7b4284bf569,
            0x7bd00915f15d4752, 0x92a074052fce2d08, 0xbcf80459b631696c, 0xc41f96a2400e1680,
            0x3240010068aaed08, 0x808296235ca83642, 0x8885110d632ca080, 0x0b9bdaee429cbcb1,
            0x1b4c603d7ff7a724, 0x1f8708106faa7087, 0x118a604481a054f7, 0xe7cc6ab2b3512be2,
            0x77e574545202899a, 0x0500de1c37f321e3, 0x8011181a,
        ]
            .span(),
        [
            0x9881607b24a071f8, 0xfdf036aebd2a84f1, 0xff173113ddc8f81b, 0x6cf01344b7278ff2,
            0x808080808063f2fe, 0xede228eedd8c11a0, 0xe141edbb19316f00, 0xa20ace9ba2f55400,
            0xe7fa40b40b46a0b1, 0x9a00a08080808005, 0x79bfb3f8667d7990, 0x4b3be8f256ea08da,
            0xa9df8015672dcc1d, 0x8080c26a7a1ebb87, 0x808080,
        ]
            .span(),
        [0x80ad4027b320a0e2, 0x7e2dc709b9c3bc41, 0x3c5ec54e0960fe1a, 0x1d50283a4b9b32de, 0x036c82]
            .span(),
    ]
        .span();
    (storage_rlp, slot)
}

fn get_slot_non_inclusion_curtis() -> (Span<Span<u64>>, u256) {
    // curl https://curtis.rpc.caldera.xyz/http -X POST -H "Content-Type: application/json" -d
    // '{"id": 3, "jsonrpc": "2.0", "method": "eth_getProof", "params":
    // ["0xDd6B74123b2aB93aD701320D3F8D1b92B4fA5202",
    // ["0xd9d16d34ffb15ba3a3d852f0d403e2ce1d691fb54de27ac87cd2f993f3ec330f"], "0x11565E9"]}'

    // def format_string_mpt(sl: list[str]) -> str:
    //     return "\n".join(["[" + ", ".join(["0x" + "".join(reversed([s[i + j + 2 : i + j + 4] for
    //     j in range(0, 16, 2)])) for i in range(0, len(s) - 2, 16)]) + "].span()," for s in sl])

    let slot = 0xd9d16d34ffb15ba3a3d852f0d403e2ce1d691fb54de27ac87cd2f993f3ec330f;
    let storage_rlp = [
        [
            0xbb84a080807101f9, 0xb85d2fc9c98d9e0c, 0x17c79766c1fae725, 0x3fce5aa756d776b8,
            0x2da0d7eda02e5ffa, 0x9affd0f5a7a7dcc9, 0x7cbfb6fd0efa7060, 0x748cdbf027a53b12,
            0xa04f0caa3594f685, 0xee7f80bf5aa2ef53, 0x6dc643ef279f335a, 0x816b926fc1dea8de,
            0x2c961d6c6f6c23cc, 0x1952265e91071ca0, 0x07ad344dc51e8984, 0x5f7ca82f2ea7c155,
            0x28b6ec423127924a, 0x08ec27c4bc0ca0bc, 0xafbd439b334f0b89, 0x07a98ef9b8ae6f6d,
            0xc3e66a7ba8edce29, 0x740efb35a0809cad, 0x7515f7959a3f2c44, 0x79a049669a5cb2dd,
            0xa11f2c6218cd0bd5, 0x572c9aa035d29af8, 0xeed3e03113c6b936, 0x67acd03b3aad031f,
            0x18a1923645cf89d4, 0x6dc6a08ae3c47b38, 0x1e33e3b74e9c8663, 0x2ec5a7b4284bf569,
            0x7bd00915f15d4752, 0x92a074052fce2d08, 0xbcf80459b631696c, 0xc41f96a2400e1680,
            0x3240010068aaed08, 0x808296235ca83642, 0x8885110d632ca080, 0x0b9bdaee429cbcb1,
            0x1b4c603d7ff7a724, 0x1f8708106faa7087, 0x118a604481a054f7, 0xe7cc6ab2b3512be2,
            0x77e574545202899a, 0x0500de1c37f321e3, 0x8011181a,
        ]
            .span(),
        [0x4123e3155f32a0e2, 0x3d6fc479c97b0860, 0x6d6f29ae81482ffd, 0x3508cbe0b39d7941, 0x01cc40]
            .span(),
    ]
        .span();
    (storage_rlp, slot)
}

#[test]
fn read_header_fields() {
    // https://rs-indexer.api.herodotus.cloud/blocks/?chain_id=33111&from_block_number_inclusive=18179561&to_block_number_inclusive=18179561&hashing_function=keccak

    let mut contract = Satellite::contract_state_for_testing();
    let (header_rlp, _) = get_header_curtis();
    let result = contract._readBlockHeaderFields(header_rlp);

    let expected = [
        0x8571c2009f6a83c25db0ae82d55c90fab2746b2d98bf1bdbd9897102340c18bd, // PARENT_HASH
        0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347, // OMMERS_HASH
        0xa4b000000000000000000073657175656e636572, // BENEFICIARY
        0x245ffbfce31bb2055eaa111c2f4352ba565df297d42caaae850ebf01de3e923d, // STATE_ROOT
        0xd768317e2632e07cd80f41d9db7b9efdc9e5749fbd9a81634a7ce0cd6d138bc9, // TRANSACTIONS_ROOT
        0x3b94b85217f4a6d952a869965b6473df5b37ba5f6d2b1d1e382e1aba232f8fba, // RECEIPTS_ROOT
        0, // LOGS_BLOOM - not supported
        0x1, // DIFFICULTY
        0x11565e9, // NUMBER
        0x4000000000000, // GAS_LIMIT
        0x186a0, // GAS_USED
        0x683ad0c8, // TIMESTAMP
        0x875dca2e0fa616d72c55138ddb45cdee89038acb254f9c1b7a602d335b0b7c79, // EXTRA_DATA
        0x00000000004a12df000000000080de5b00000000000000200000000000000000, // MIX_HASH
        0x00000000000e5b37 // NONCE
    ]
        .span();

    assert_eq!(result, expected);
}

#[test]
fn prove_header() {
    let mut contract = Satellite::contract_state_for_testing();

    let chain_id = 33111;
    let (header_rlp, block_number) = get_header_curtis();

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
        Option::Some(0x8571c2009f6a83c25db0ae82d55c90fab2746b2d98bf1bdbd9897102340c18bd),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::OMMERS_HASH),
        Option::Some(0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::BENEFICIARY),
        Option::Some(0xa4b000000000000000000073657175656e636572),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::STATE_ROOT),
        Option::Some(0x245ffbfce31bb2055eaa111c2f4352ba565df297d42caaae850ebf01de3e923d),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::TRANSACTIONS_ROOT),
        Option::Some(0xd768317e2632e07cd80f41d9db7b9efdc9e5749fbd9a81634a7ce0cd6d138bc9),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::RECEIPTS_ROOT),
        Option::Some(0x3b94b85217f4a6d952a869965b6473df5b37ba5f6d2b1d1e382e1aba232f8fba),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::LOGS_BLOOM),
        Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::DIFFICULTY),
        Option::Some(0x1),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::NUMBER), Option::None,
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::GAS_LIMIT),
        Option::Some(0x4000000000000),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::GAS_USED),
        Option::Some(0x186a0),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::TIMESTAMP),
        Option::Some(0x683ad0c8),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::EXTRA_DATA),
        Option::Some(0x875dca2e0fa616d72c55138ddb45cdee89038acb254f9c1b7a602d335b0b7c79),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::MIX_HASH),
        Option::Some(0x00000000004a12df000000000080de5b00000000000000200000000000000000),
    );
    assert_eq!(
        contract.headerFieldSafe(chain_id, block_number, BlockHeaderField::NONCE),
        Option::Some(0x00000000000e5b37),
    );
}

#[test]
fn prove_account() {
    let mut contract = Satellite::contract_state_for_testing();

    let chain_id = 33111;
    let (header_rlp, block_number) = get_header_curtis();
    let (account_rlp, account) = get_account_curtis();

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

    // TODO: Test balance proving
    contract.proveAccount(chain_id, block_number, account, 0b1101, account_rlp);

    assert_eq!(
        contract.accountFieldSafe(chain_id, block_number, account, AccountField::NONCE),
        Option::Some(0x1),
    );
    assert_eq!(
        contract.accountFieldSafe(chain_id, block_number, account, AccountField::BALANCE),
        Option::None,
    );
    assert_eq!(
        contract.accountFieldSafe(chain_id, block_number, account, AccountField::STORAGE_ROOT),
        Option::Some(0x6fe522ff20ea9af8b6e98a87ee84a24decfe5c7a667d3aaeba27e0e9b343bc7e),
    );
    assert_eq!(
        contract.accountFieldSafe(chain_id, block_number, account, AccountField::CODE_HASH),
        Option::Some(0x1800dfc8f6947634cee2a1dfa6fe2b046f03818e209b968607d6c6315ea0926b),
    );
}

#[test]
fn prove_slot_inclusion() {
    let mut contract = Satellite::contract_state_for_testing();

    let chain_id = 33111;
    let (header_rlp, block_number) = get_header_curtis();
    let (account_rlp, account) = get_account_curtis();
    let (storage_rlp, slot) = get_slot_inclusion_curtis();

    let header_proof = create_mmr_with_block(ref contract, header_rlp, chain_id, 211);

    contract.proveHeader(chain_id, 0b1000, header_proof);
    contract.proveAccount(chain_id, block_number, account, 0b0100, account_rlp);

    assert_eq!(contract.storageSlotSafe(chain_id, block_number, account, slot), Option::None);

    contract.proveStorage(chain_id, block_number, account, slot, storage_rlp);

    assert_eq!(contract.storageSlotSafe(chain_id, block_number, account, slot), Option::Some(0x3));
}

#[test]
fn prove_slot_non_inclusion() {
    let mut contract = Satellite::contract_state_for_testing();

    let chain_id = 33111;
    let (header_rlp, block_number) = get_header_curtis();
    let (account_rlp, account) = get_account_curtis();
    let (storage_rlp, slot) = get_slot_non_inclusion_curtis();

    let header_proof = create_mmr_with_block(ref contract, header_rlp, chain_id, 211);

    contract.proveHeader(chain_id, 0b1000, header_proof);
    contract.proveAccount(chain_id, block_number, account, 0b0100, account_rlp);

    assert_eq!(contract.storageSlotSafe(chain_id, block_number, account, slot), Option::None);

    contract.proveStorage(chain_id, block_number, account, slot, storage_rlp);

    assert_eq!(contract.storageSlotSafe(chain_id, block_number, account, slot), Option::Some(0x0));
}
