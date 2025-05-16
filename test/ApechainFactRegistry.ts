import { ethers } from "hardhat";
import { expect } from "chai";
import { fieldsToSave as f, fields, toU256, setMmrData, deploy } from "./utils";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

describe("EVM Fact Registry Apechain", () => {
  it("Should prove account", async () => {
    const { satellite, satelliteAddress } = await loadFixture(deploy);

    const chainId = BigInt(33111);
    const blockNumber = BigInt(0x104e821);
    const mmrId = BigInt(100);
    const mmrSize = BigInt(1);
    const keccakHasher = BigInt(
      "0xdf35a135a69c769066bbb4d17b2fa3ec922c028d4e4bf9d0402e6f7c12b31813",
    );
    const blockHash =
      "0xc0e31e50a113d30d36da432139080f5a596631f1935b1b37a4a1a905d1a1f290";
    const mmrRoot = BigInt(
      ethers.keccak256(toU256(mmrSize, BigInt(blockHash))),
    );

    await setMmrData(
      satelliteAddress,
      chainId,
      mmrId,
      keccakHasher,
      false,
      mmrSize,
      mmrRoot,
    );

    const account = "0xEEBC6016539E0bC60D35f527FEfa414794854499";
    const headerProof = {
      treeId: mmrId,
      mmrTreeSize: mmrSize,
      blockNumber,
      blockProofLeafIndex: 1,
      mmrPeaks: [blockHash],
      mmrElementInclusionProof: [],
      provenBlockHeader:
        "0xf90223a0e09c933b2ae4b00ae29a6ce9ec40d2073f74cc1a39cd2453948a2945c8051680a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d4934794a4b000000000000000000073657175656e636572a07da0dca81ff738751942f1e160e8bb174f2822b54271e048e30028e9f05d4f7ca05494efe03c9f501e7c8afc33f13af9304224f840d91a9608dabfedc43cd1fbb6a008519cd3f965720c9f16783ad2e6a3d2df9fa05d18ac58f8d0ade7dd8c5ec5c6b901000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000040000000000000000220000000000000000000000000000000000000200000000000000000000000000000000000000000002000000000000000004080000000000000000400000000004200000000000000000000000002000000041000000000000000000000022000000000000000000000000000000080000800000080000000000000000000000000000000000002000000000004000000000000400000000000000000000000000002000000000000000000000000800000000000000800000040000000000000010000001840104e8218704000000000000830129388467efcb0fa055197ad14d6804f2dcd9118ebd0cea13640510a635005d312d7dae2db30d96bfa000000000004430d200000000007ad0d7000000000000002000000000000000008800000000000d920883989680",
    };
    const accountTrieProof =
      "0xf90bb3b90214f90211a0e7615cc1a65525dcbe26e59fac6822fd3bd555af663c4c580bd8cef784c31536a0715132fc76d255fc7a8aebdf240b8568e33bed61fcbd13db95e057b25ee4199fa067eabbde6b28d98300186b627409c9c1d0c4f83d29aa9fca00657df26fb99b57a070c2526f2f783305f00a9559d780220e963e83b238d0b4c06604c36c6b6c139ea09849edeee1a769316786b848c5bfa444be3c568cff1d5985fc8b29f75258df6fa030fd041f6909484573737047e63792567e4daf95b93d98d60c70d3baed2990a4a09b620ab489dd1f05f4582f2dcfb387bcb632f1b5e8046486e1ee2c9ccc0a4c38a09ead1c3d6ab8d10a6ea3a20f40e7cd121cc57db7ff09faa738dddd3e1acd30d0a0a8f04abb4045983d189a1bb6b5c9721e5a19edbba9e9f4f9e967d13bf2f1f238a07ebdee05c7a405f3420066674c3a3bb10e6a123fed1b620214e1ae166b286804a02977cc2cadc3788dc5c7b29aca508221307a1bf670d2a8613fc4a6a1cbe0a5a4a0c8016a382a4d7b60aa1e183191385ff158939782826e490616cae49ec19bfd2aa047f06817e34cf3ac2d5fa8c08e9f406cc1cef22f18d2a838ab2413d6c472f8cea0567eb8dc4e3fd62e2dd4fe7f362610d64396522a5938150995aafa41db552bd7a067674c5952ee92b673b653670cb7673a2d9058b8c085b104b302e70f2e3b8ba6a0cffc85324a41da22ae10bf2f959a21bdf35ce0a86d9b353a3213bc0feee08abd80b90214f90211a070737e92ac36992e12e55908f3e479f52eefd6fd0264cd8c64fc314876ee004ba068b7ae6411deb5087d8734f84176d84e423ed82125f3afee2d33632bfb57a51da06e0bb2bbcd47c316a5f23e27758ed72fd3113ad33b5da9e4a3b4276dc7d16407a02b71ff19f84eab8eac0f34ac0db32eb036e10e60f38c9dec95d95ba7e3c1e270a021a05586d887f7fd1ba40f77680a028e21a73cc9f607c0a73459144683d6e1d3a05677429ee761bb620e93877928db883bef3e496c103f027dd829c05f7c7cb833a04b7600fc629db3e4bd4256dc76c175d23e3272e5f1f88d92f8e6072c1686b750a04eb6333c96e57bf1af389faec9cb24ed2039fccfe0e82e36bb0c82e205180ae9a0f6f2d52465c1426bd534e364c89b7d04dad11e9314f0187f32881db769406552a01ff646f94ef6fc06e4a9bff5cdae83b16f39ad0509e5eff68ae3da5a5bcfc8a2a0a0bfe0fb065cca4fae4622e4135afb7ca0d739e388ffeff35a986bc7c59996d7a064b9ddb74d7c76928dfe178ecc3bc4a78d371009aef58629b02bc1364defd204a02db45f9fc19dec19d0359e033aafdd6fccef8a8c3a52e6b1ef71f80e909a50cea0c7711b7df64f573a5dddf558024550a729faf408ffc7138f828c20cd50d6055aa040a639c922febfe011c55383a1c47680de78cb091ae6396aa5cda8f43f63df68a0b64dbf6a5916ce36f5cc3fbd42795e9be8162eeef88dd75ea2c808cd9982a83b80b90214f90211a0772d0ad4883a2aedbae23f886ea62552a26dfd755053e675f1132c6a7e99cfe7a043304fdd2d5a7eb48509e6938aea837389fb7c803ea6b21cf2ebf5ec951c93d1a07a06d0dbc59f03a63ff347b9a673a3a43e4009e1584c45fc0427d9a299f397c5a0976e949cc3dbec5f29443b381b2644b0d1b3728cedd4830ba30fc8a6fede4623a06b61065c66b4b22929d5505a4e435a4bf6c6855857eddf073e431936f0a4c22aa0dcea905fb0e03993b21c9416cb2c35b659ffe5e390305f75be382f4f9b019284a0b3ee645439142c41e95f9fa0ffafdb4b973aa52cfa27fa30226942f0e81618e2a08e9b5fe7321fba7130be46e804a645f8fa27e47f3b990a1ee7bc529194416aaba0adfce7af9db323fd14c301503c04aa2fb7d20d09a2dd069cce1b436e01a333b8a0b2d057c47e94c0cdebc5c240ed9b952021cf9a98ac30e14e44a905e2f6aa773fa04a43e51326ae6254f44688b6ef6d3a32ca9960d37352012f0ce624679640ce95a0bf06b4d7e77594d3ee17b1f16a4ea1db3a074b0c173c8626808bc40ccaeab29ba09f70d7a6e9200cbfd6a70fe0f08ebb0a00f3b1032427344ec9308c1216d8323da09d5b93a22795dbb8c6b0806a7f55e9cb1706075df4f51dc24bdcdbc2e95232b5a02e3fea0695251faa8416dcc812fd502043e66bb1e5311beb856e809ff88feca9a09849ad6ffe5b118a043ab57989fb2391176e539f2450280273b5103edca1a9cd80b90214f90211a02c81e867be7fdff7b5f233c529e97c9bece4935f345594b23a83b229ec66b3e5a073317fd5dbd378152618d8dbffda67e6a8b78a5d13531cc7a2e44226da608591a00e2bb0c7fda5c4e469a82ff657fba938c0859f2fea8cf28be134de30c00ba503a0c8e0d712282cc534cb8353ebf1a6f3a2e0c80c6e788b1167a8f010bea409d1e0a031c4e153ab17b860052ada00ff69f074be78d2ef397c2922f97dbc89e80a88f1a0d9dfc5314bca6464eba4013e77acb90ec43b52a2b3511550ba0911283e84d257a0ef3acff06ddc05e934bca95a13a7ad40f5d25ef5a5c29d67aeaf0bbe4f251fcfa08e4776493a0e4db5321cc98ef6cf4d11b335cb215e5b3975d160fa48e4e24d5ea068f6c2051418371012a1e9c4b4fb983a9c5e9f019d8f1bd584931081c968b95aa0c47fdbaee82912493966cc3ece18dcd6f516e1b02a0f8e969fb8b00c838b2c77a08d629d5b9d26e51a74e958c84230e24e9e99ca0894fb06968bc984286698f81ca047cb038cb3ef3012ecde9af0b2b98731c7aaf31925392d9b334307e39e12f3b7a08716dc103ebc83062ba53ed64d1d88a881088d058f08cd084f52c334d5731b25a097e5a69abef43de28500e5bb7f455f59533e8c15f4dc6af48959e92f92792714a00ea0f97e5aa671ad07dd6c8dd0ed7b34c2665c811ca804ee02ae8d9a0248d847a0ab929d896a7a63a468a889326a410fd6bcc7f886c078f738c8029c032a3c243380b90214f90211a0185e5f7f70d689132d27fcccad01547d497bbb07d343de317ba6ac2c1a80697ba07025b3dc2713927a7253f0f3e18cc7398b62157df121fc51c449f6e7df5260cca0f8a4892abe38e6cbef5b44c91f43289cf91caa9dc0f4b7469e1ac861e15f813ca08f25f8d92bb546cc336c8ae09421ec36d41d5aaffe7aa6839a0ab9839d989daca0ca33113b20adfa0801b90bfa0da97063fc7b111388720c3df95057ed209580fca0ca989fed9cf3c53ab5bf2045ce6ef516c7820ab8552f2a28d4ecd78d9963aac8a096128afbaee78a79798d6cbdeb35816e644b45ace9320027ac866ef38f8231caa040f9c9b82cc1e7612eea1c7b2b015082c95503b5be542811001e4f1e9f31c4aca04b6ce1d1bf4b348353450a4d68742dbeacf8d63ebd5fb8f1223a8fcf32abfb74a0fda4b57c9b8c60c8ef6a42549fc999da3487c60d47831b2ecdfcb2156154f80ba02710315307cd63f018408773601b5ef6d6ec98c384ad241d4f6eee77ffcbc5d7a071f3398a1c6c666b9fe6e3ab27b3b9338f72500ba7b86d6f0b95e0e32f8ba1e3a02a649a860d20f80dba3b7a5afc3c3b750b02427901ea62be0e8ea96e59eee947a07d06cb0fd57d984d238ea0d9a39d159ca973fa37172a9c3d56ebbaa6a12ea233a0f96acef81e73e137ab3ed1feeaa3aa6e0ee24133f2aabf6c5c2bfc7472d3f7d0a09d3c88ee1d859f1bd69eb545cc7ae5cca39cbdbd15c7169b43d0885565a1a9e480b8b3f8b18080a0260510957f0ae6d92682cd1bbf27fb4d6de3a0cb2886d08b43414bdde69a37aea06ac5f520ca2286ac172e29401b98a5a1e201862c2bbb2a930e48daa612cc62eb8080a08b5ae6f3c969e551b883759877f9cf1d397af64db3e6dc4a69437b7b0cfcdb60808080a071a0a29f09da2499bccc1f3f44713617fcf60c493e3f63432bcac3f95599bf138080a0f06e2e755e6443f8c592845a007bd56197ae81bbd55dc68e2e03a6c22814c98a808080b889f8879e2023b76d0262107041ef01f93aa86c725dbb04c54bf65d06384efd271601b866f864778084136fe9798470e2925380940000000000000000000000000000000000000000a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

    const expected = {
      nonce: 0x77,
      flags: 0,
      fixed: 0x136fe979,
      shares: 0x70e29253,
      debt: 0x0,
      delegate: 0x0,
      storageHash: BigInt(
        "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
      ),
      codeHash: BigInt(
        "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",
      ),
    };

    await expect(
      satellite.accountField(chainId, account, blockNumber, fields.NONCE),
    ).to.be.revertedWith("ERR_FIELD_NOT_SAVED");

    await expect(
      satellite.accountField(chainId, account, blockNumber, fields.BALANCE),
    ).to.be.revertedWith("ERR_FIELD_NOT_SAVED");

    await expect(
      satellite.accountField(
        chainId,
        account,
        blockNumber,
        fields.STORAGE_ROOT,
      ),
    ).to.be.revertedWith("ERR_FIELD_NOT_SAVED");

    await expect(
      satellite.accountField(chainId, account, blockNumber, fields.CODE_HASH),
    ).to.be.revertedWith("ERR_FIELD_NOT_SAVED");

    await expect(
      satellite.accountField(chainId, account, blockNumber, fields.APE_FLAGS),
    ).to.be.revertedWith("ERR_FIELD_NOT_SAVED");

    await expect(
      satellite.accountField(chainId, account, blockNumber, fields.APE_FIXED),
    ).to.be.revertedWith("ERR_FIELD_NOT_SAVED");

    await expect(
      satellite.accountField(chainId, account, blockNumber, fields.APE_SHARES),
    ).to.be.revertedWith("ERR_FIELD_NOT_SAVED");

    await expect(
      satellite.accountField(chainId, account, blockNumber, fields.APE_DEBT),
    ).to.be.revertedWith("ERR_FIELD_NOT_SAVED");

    await expect(
      satellite.accountField(
        chainId,
        account,
        blockNumber,
        fields.APE_DELEGATE,
      ),
    ).to.be.revertedWith("ERR_FIELD_NOT_SAVED");

    await satellite.proveAccount(
      chainId,
      account,
      f.NONCE | f.CODE_HASH | f.STORAGE_ROOT | f.APE_FLAGS,
      headerProof,
      accountTrieProof,
    );

    expect(
      await satellite.accountField(chainId, account, blockNumber, fields.NONCE),
    ).to.equal(toU256(expected.nonce));

    await expect(
      satellite.accountField(chainId, account, blockNumber, fields.BALANCE),
    ).to.be.revertedWith("ERR_FIELD_NOT_SAVED");

    expect(
      await satellite.accountField(
        chainId,
        account,
        blockNumber,
        fields.CODE_HASH,
      ),
    ).to.equal(toU256(expected.codeHash));

    expect(
      await satellite.accountField(
        chainId,
        account,
        blockNumber,
        fields.STORAGE_ROOT,
      ),
    ).to.equal(toU256(expected.storageHash));

    expect(
      await satellite.accountField(
        chainId,
        account,
        blockNumber,
        fields.APE_FLAGS,
      ),
    ).to.equal(toU256(expected.flags));

    expect(
      await satellite.accountField(
        chainId,
        account,
        blockNumber,
        fields.APE_FIXED,
      ),
    ).to.equal(toU256(expected.fixed));

    expect(
      await satellite.accountField(
        chainId,
        account,
        blockNumber,
        fields.APE_SHARES,
      ),
    ).to.equal(toU256(expected.shares));

    expect(
      await satellite.accountField(
        chainId,
        account,
        blockNumber,
        fields.APE_DEBT,
      ),
    ).to.equal(toU256(expected.debt));

    expect(
      await satellite.accountField(
        chainId,
        account,
        blockNumber,
        fields.APE_DELEGATE,
      ),
    ).to.equal(toU256(expected.delegate));
  });
});
