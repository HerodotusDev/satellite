import { loadFixture, mine } from "@nomicfoundation/hardhat-network-helpers";
import {
  deploy,
  getHeaderRlp,
  KECCAK_HASHER,
  POSEIDON_HASHER,
  setMmrData,
  toU256,
  headerFieldsBitmask,
  accountFieldsBitmask,
  deploy2,
} from "../utils";
import { expect } from "chai";
import { ethers } from "hardhat";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";

describe("MMR from storage slots", () => {
  it("getStorageSlotsForMmrCreation", async () => {
    // const { satellite, satelliteAddress } = await loadFixture(deploy);
    // const chain_id = BigInt(11155111);
    // const mmr_id = BigInt(123);
    // const mmr_size = BigInt(10);
    // const keccak_root = BigInt(
    //   "0x4c466c582074f6351b729134d42c66b15b7e1218fa63f1bfd614045ea96cd66a",
    // );
    // const poseidon_root = BigInt(
    //   "0x3c5f312ba85ad56867cd2de63d79e4ba910c90d9e82437d023846a044d10952",
    // );
    // const is_offchain_grown = true;
    // for (const [r, f] of [
    //   [keccak_root, KECCAK_HASHER],
    //   [poseidon_root, POSEIDON_HASHER],
    // ]) {
    //   await setMmrData(
    //     satelliteAddress,
    //     chain_id,
    //     mmr_id,
    //     f,
    //     is_offchain_grown,
    //     mmr_size,
    //     r,
    //   );
    // }
    // const storageSlots = await satellite.getStorageSlotsForMmrCreation(
    //   chain_id,
    //   mmr_id,
    //   mmr_size,
    //   [toU256(KECCAK_HASHER), toU256(POSEIDON_HASHER)],
    // );
    // expect(storageSlots.length).to.equal(2);
    // expect(storageSlots[0].length).to.equal(2);
    // expect(storageSlots[1].length).to.equal(2);
    // expect(
    //   await ethers.provider.send("eth_getStorageAt", [
    //     satelliteAddress,
    //     toU256(BigInt(storageSlots[0][0])),
    //   ]),
    // ).to.equal(toU256(Number(is_offchain_grown)));
    // expect(
    //   await ethers.provider.send("eth_getStorageAt", [
    //     satelliteAddress,
    //     toU256(BigInt(storageSlots[1][0])),
    //   ]),
    // ).to.equal(toU256(keccak_root));
    // expect(
    //   await ethers.provider.send("eth_getStorageAt", [
    //     satelliteAddress,
    //     toU256(BigInt(storageSlots[0][1])),
    //   ]),
    // ).to.equal(toU256(Number(is_offchain_grown)));
    // expect(
    //   await ethers.provider.send("eth_getStorageAt", [
    //     satelliteAddress,
    //     toU256(BigInt(storageSlots[1][1])),
    //   ]),
    // ).to.equal(toU256(poseidon_root));
  });

  it("createMmrFromStorageProof", async () => {
    const {
      satellite1: sourceSatellite,
      satelliteAddress1: sourceSatelliteAddress,
      satellite2: destinationSatellite,
      satelliteAddress2: destinationSatelliteAddress,
    } = await loadFixture(deploy2);

    const sourceChainId = BigInt(123001);
    const accumulatedChainId = BigInt(123002);

    // Setup data that we want to move (which is on sourceChainId and accumulates accumulatedChainId)
    const accumulatedMmrId = BigInt(579120);
    const accumulatedIsOffchainGrown = true;
    const accumulatedMmrSize = BigInt(3);

    const keccak_root = BigInt(
      "0xc47c2f4ab42fe2617dd76ca1eb9781d09fced5e5671df71824e2f8a8f694e024",
    );
    const poseidon_root = BigInt(
      "0x5033c57e97ecf1702c4fade3c0c1d5a588896cf74d2e28814ea2bac0fecbff5",
    );

    for (const [r, f] of [
      [keccak_root, KECCAK_HASHER],
      [poseidon_root, POSEIDON_HASHER],
    ]) {
      await setMmrData(
        sourceSatelliteAddress,
        accumulatedChainId,
        accumulatedMmrId,
        f,
        accumulatedIsOffchainGrown,
        accumulatedMmrSize,
        r,
      );
    }

    // Prove on destination satellite that source satellite contains an MMR that accumulated accumulatedChainId

    // await mine();
    // return;

    // If hardhat fixes this https://github.com/NomicFoundation/hardhat/issues/3345
    // We can use this better solution.
    // const blockNumber = BigInt(await ethers.provider.send("eth_blockNumber"));
    // const block = await ethers.provider.send("eth_getBlockByNumber", [
    //   toU256(blockNumber),
    //   false,
    // ]);
    const block = {
      hash: "0x6ac245403bbc1a7b180360ea7c57e21f8b739fe872f024c25c1723c69df87b8e",
      parentHash:
        "0xbad68f990f9404423b2389dd37d68bd5fb51b6d48cbbf5ef5b76d5d9a1e0417b",
      sha3Uncles:
        "0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347",
      miner: "0x0000000000000000000000000000000000000000",
      stateRoot:
        "0x1162a848904d8cc716bee90c504f90c95082a9e7f930164ad0d250d78766dc2f",
      transactionsRoot:
        "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
      receiptsRoot:
        "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
      logsBloom:
        "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      difficulty: "0x0",
      number: "0x2",
      gasLimit: "0x1c9c380",
      gasUsed: "0x0",
      timestamp: "0x686ba66d",
      extraData: "0x",
      mixHash:
        "0x0000000000000000000000000000000000000000000000000000000000000000",
      nonce: "0x0000000000000000",
      baseFeePerGas: "0x342b0f93",
      withdrawalsRoot:
        "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
      blobGasUsed: "0x0",
      excessBlobGas: "0x0",
      parentBeaconBlockRoot:
        "0x0000000000000000000000000000000000000000000000000000000000000000",
      totalDifficulty: "0x0",
      size: "0x246",
    };

    const srcMmrId = BigInt(582120);
    const srcMmrSize = BigInt(1);
    const srcLeafIndex = BigInt(1);
    const srcLeafValue = BigInt(block.hash);
    const srcMmrRoot = BigInt(
      ethers.keccak256(toU256(srcMmrSize, srcLeafValue)),
    );

    await setMmrData(
      destinationSatelliteAddress,
      sourceChainId,
      srcMmrId,
      KECCAK_HASHER,
      false,
      srcMmrSize,
      srcMmrRoot,
    );

    const headerRlp = getHeaderRlp(block);
    expect(ethers.keccak256(headerRlp)).to.equal(block.hash);

    await destinationSatellite.proveHeader(
      sourceChainId,
      headerFieldsBitmask.STATE_ROOT,
      {
        mmrId: srcMmrId,
        mmrSize: srcMmrSize,
        mmrLeafIndex: srcLeafIndex,
        mmrPeaks: [toU256(srcLeafValue)],
        mmrInclusionProof: [],
        blockHeaderRlp: headerRlp,
      },
    );

    // const proofs = await ethers.provider.send("eth_getProof", [
    //   sourceSatelliteAddress,
    //   toU256(0),
    //   block.number,
    // ]);

    // console.log(
    //   `["${sourceSatelliteAddress}", ["${toU256(slots[0][0])}", "${toU256(slots[1][0])}", "${toU256(slots[0][1])}", "${toU256(slots[1][1])}"], "${block.number}"]`,
    // );
    // curl http://localhost:8545 -X POST -H "Content-Type: application/json" -d '{"id": 3, "jsonrpc": "2.0", "method": "eth_getProof", "params": ["0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0", ["0xf3ea1b97239b244cd6107d7d1441522f759a4b38b0337532d11f8ae514cf3bba", "0x3e1951967b5a3086fdc4fe1f28dc75f05ae96fa1df3f0b8bf3875d67e25ca393", "0xedfbe9e80a049266f16056085ee859fc33873c24d73bbab8a59eb1c86456a388", "0xb277b521ad1836e891e2c1b96f396f6d3a13e664b6294be863a063b3af45b95e"], "latest"]}'

    const proofs = {
      address: "0xa51c1fc2f0d1a1b8494ed1fe312d7c3a78ed91c0",
      balance: "0x0",
      codeHash:
        "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",
      nonce: "0x0",
      storageHash:
        "0x24f06d32884db41a7455cbee160885bfa3f8b2d06890ff7480c4a651a7461103",
      accountProof: [
        "0xf90151a0b91a8b7a7e9d3eab90afd81da3725030742f663c6ed8c26657bf00d842a9f4aaa01689b2a5203afd9ea0a0ca3765e4a538c7176e53eac1f8307a344ffc3c6176558080a037658e942168bc0b2a5e6b7278ff4aadd9e919f7ae5768dc98b36eb3761508c1a0e17ef99b2b14face17279a10e280427ce4090bc3b9d1599cd5e169345787d59180a0733ed568cbca8475aa416b9c86d5e34df2fb6e52f0464873e7bef1951216185da04b29efa44ecf50c19b34950cf1d0f05e00568bcc873120fbea9a4e8439de0962a0d0a1bfe5b45d2d863a794f016450a4caca04f3b599e8d1652afca8b752935fd880a0bf9b09e442e044778b354abbadb5ec049d7f5e8b585c3966d476c4fbc9a181d28080a064516ac89e2183574b6ce90465d24a9ee46ccfa2b3cb7b5e0ba8759844858458a0e5c557a0ce3894afeb44c37f3d24247f67dc76a174d8cacc360c1210eef60a7680",
        "0xf8518080808080808080a0935861f170ab96d3374aaf7a1c5fc889ee2f98405d148083a4bebe32141231248080a009ae6c95830a7ad6527b56c373f3926dc07af49558fa169dc99c234b55e553938080808080",
        "0xf869a02052b82e709191be4bae3bb8544d2a6b51d7440a1d15ba1f09e33bcf049e47a5b846f8448080a024f06d32884db41a7455cbee160885bfa3f8b2d06890ff7480c4a651a7461103a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",
      ],
      storageProof: [
        {
          key: "0xf3ea1b97239b244cd6107d7d1441522f759a4b38b0337532d11f8ae514cf3bba",
          value: "0x1",
          proof: [
            "0xf8918080a03e2c7ffb86961354c6b19b2a241366bc9020c508aab3e1326f09fa8e81b7f4908080808080a0bda521437ca13bffe55cb44883070948b0f50591bdc7c4fcaf3d4f4804bc9f2280a0186f3a9515e213ebc7d32c99ddc14909b89397e65e99164f2a2dcbcdb24b7ce180a0d54cfc1b032794b59ed28e068d4b9b897bb3f46fb7dae9b2761f3f6f4a8ecd3680808080",
            "0xf8518080a0abdea2afa4601630c0efc4af09ea43893cb071a2d07d21016ba1924ef4eecad88080a0102a38b5967bfa8190752fea8cd6089fdcad51ed03de49318e01f53e05e724198080808080808080808080",
            "0xe2a020e103221b4c45ac8b9c710a5b293d831c66787e9d6929e138173047025c40c201",
          ],
        },
        {
          key: "0x3e1951967b5a3086fdc4fe1f28dc75f05ae96fa1df3f0b8bf3875d67e25ca393",
          value:
            "0xc47c2f4ab42fe2617dd76ca1eb9781d09fced5e5671df71824e2f8a8f694e024",
          proof: [
            "0xf8918080a03e2c7ffb86961354c6b19b2a241366bc9020c508aab3e1326f09fa8e81b7f4908080808080a0bda521437ca13bffe55cb44883070948b0f50591bdc7c4fcaf3d4f4804bc9f2280a0186f3a9515e213ebc7d32c99ddc14909b89397e65e99164f2a2dcbcdb24b7ce180a0d54cfc1b032794b59ed28e068d4b9b897bb3f46fb7dae9b2761f3f6f4a8ecd3680808080",
            "0xf843a0396cece3396c65aad1b48701981a1e99106c266071e593f7a4bcfddb72e8ee26a1a0c47c2f4ab42fe2617dd76ca1eb9781d09fced5e5671df71824e2f8a8f694e024",
          ],
        },
        {
          key: "0xedfbe9e80a049266f16056085ee859fc33873c24d73bbab8a59eb1c86456a388",
          value: "0x1",
          proof: [
            "0xf8918080a03e2c7ffb86961354c6b19b2a241366bc9020c508aab3e1326f09fa8e81b7f4908080808080a0bda521437ca13bffe55cb44883070948b0f50591bdc7c4fcaf3d4f4804bc9f2280a0186f3a9515e213ebc7d32c99ddc14909b89397e65e99164f2a2dcbcdb24b7ce180a0d54cfc1b032794b59ed28e068d4b9b897bb3f46fb7dae9b2761f3f6f4a8ecd3680808080",
            "0xf8518080a0abdea2afa4601630c0efc4af09ea43893cb071a2d07d21016ba1924ef4eecad88080a0102a38b5967bfa8190752fea8cd6089fdcad51ed03de49318e01f53e05e724198080808080808080808080",
            "0xe2a0201bffb69df9f474f24f9b253f4a5eec82a654d0a1b6479df1392408b019a8ff01",
          ],
        },
        {
          key: "0xb277b521ad1836e891e2c1b96f396f6d3a13e664b6294be863a063b3af45b95e",
          value:
            "0x5033c57e97ecf1702c4fade3c0c1d5a588896cf74d2e28814ea2bac0fecbff5",
          proof: [
            "0xf8918080a03e2c7ffb86961354c6b19b2a241366bc9020c508aab3e1326f09fa8e81b7f4908080808080a0bda521437ca13bffe55cb44883070948b0f50591bdc7c4fcaf3d4f4804bc9f2280a0186f3a9515e213ebc7d32c99ddc14909b89397e65e99164f2a2dcbcdb24b7ce180a0d54cfc1b032794b59ed28e068d4b9b897bb3f46fb7dae9b2761f3f6f4a8ecd3680808080",
            "0xf8518080a08ef69c7376c1912cec6e29ba46e4a63ef6cabce7a0bd8515da8369a6796dd56e8080a095d67bc3ced75939230f63b2597b8227843905e3df488d08ba84fd4795a8e6e18080808080808080808080",
            "0xf843a02014f5faa25e9f5409733ab0eb8a7ede43eabbf08332427af45cb0126884c17fa1a005033c57e97ecf1702c4fade3c0c1d5a588896cf74d2e28814ea2bac0fecbff5",
          ],
        },
      ],
    };

    await destinationSatellite.registerSatelliteConnection(
      sourceChainId,
      sourceSatelliteAddress,
      "0x0000000000000000000000000000000000000000",
      "0x0000000000000000000000000000000000000000",
      "0x00000000",
    );

    // 0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0 0x67d269191c92Caf3cD7723F116c85e6E9bf55933

    // const storageProofs = ;
    // console.log(BigInt(await ethers.provider.send("eth_blockNumber")));

    // const storageSlots = await destinationSatellite.getStorageSlotsForMmrCreation(
    //   sourceChainId,
    //   srcMmrId,
    //   srcMmrSize,
    //   [toU256(KECCAK_HASHER), toU256(POSEIDON_HASHER)],
    // );
    // console.log(storageSlots);

    await destinationSatellite.proveAccount(
      sourceChainId,
      block.number,
      sourceSatelliteAddress,
      accountFieldsBitmask.STORAGE_ROOT,
      ethers.encodeRlp(proofs.accountProof),
    );

    for (const { key, proof } of proofs.storageProof) {
      await destinationSatellite.proveStorage(
        sourceChainId,
        block.number,
        sourceSatelliteAddress,
        key,
        ethers.encodeRlp(proof),
      );
    }

    const dstMmrId = BigInt(7952302);

    const slots = await destinationSatellite.getStorageSlotsForMmrCreation(
      accumulatedChainId,
      accumulatedMmrId,
      accumulatedMmrSize,
      [toU256(KECCAK_HASHER), toU256(POSEIDON_HASHER)],
    );
    expect(slots[0][0]).to.equal(proofs.storageProof[0].key);
    expect(slots[1][0]).to.equal(proofs.storageProof[1].key);
    expect(slots[0][1]).to.equal(proofs.storageProof[2].key);
    expect(slots[1][1]).to.equal(proofs.storageProof[3].key);

    expect(
      await destinationSatellite.getLatestMmr(
        accumulatedChainId,
        dstMmrId,
        toU256(KECCAK_HASHER),
      ),
    ).to.deep.equal([BigInt(0), toU256(BigInt(0)), false]);

    await expect(
      destinationSatellite.createMmrFromStorageProof(
        dstMmrId,
        accumulatedMmrId,
        accumulatedChainId,
        accumulatedMmrSize,
        [toU256(KECCAK_HASHER), toU256(POSEIDON_HASHER)],
        sourceChainId,
        block.number,
        accumulatedIsOffchainGrown,
        [],
      ),
    )
      .to.emit(destinationSatellite, "CreatedMmr")
      .withArgs(
        dstMmrId,
        accumulatedMmrSize,
        accumulatedChainId,
        accumulatedMmrId,
        anyValue,
        sourceChainId,
        BigInt(2), // STORAGE_PROOF
        accumulatedIsOffchainGrown,
      );

    expect(
      await destinationSatellite.getLatestMmr(
        accumulatedChainId,
        dstMmrId,
        toU256(KECCAK_HASHER),
      ),
    ).to.deep.equal([
      accumulatedMmrSize,
      keccak_root,
      accumulatedIsOffchainGrown,
    ]);
  });
});
