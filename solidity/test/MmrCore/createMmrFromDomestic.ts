import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import {
  deploy,
  KECCAK_HASHER,
  POSEIDON_HASHER,
  setMmrData,
  toU256,
} from "../utils";
import { expect } from "chai";

async function setup_mmr_multiple_hashing_functions() {
  const { satellite, satelliteAddress } = await loadFixture(deploy);

  // Set up some MMR for testing
  let chain_id = BigInt(11155111);
  let original_mmr_id = BigInt(123);
  let mmr_size = BigInt(10);
  let keccak_root = BigInt(
    "0x4c466c582074f6351b729134d42c66b15b7e1218fa63f1bfd614045ea96cd66a",
  );
  let poseidon_root = BigInt(
    "0x3c5f312ba85ad56867cd2de63d79e4ba910c90d9e82437d023846a044d10952",
  );
  let original_is_offchain_grown = true;
  let roots_for_hashing_functions = [
    { root: keccak_root, hashing_function: KECCAK_HASHER },
    { root: poseidon_root, hashing_function: POSEIDON_HASHER },
  ];

  for (const r of roots_for_hashing_functions) {
    await setMmrData(
      satelliteAddress,
      chain_id,
      original_mmr_id,
      r.hashing_function,
      original_is_offchain_grown,
      mmr_size,
      r.root,
    );
  }

  expect(
    await satellite.getLatestMmr(
      chain_id,
      original_mmr_id,
      toU256(KECCAK_HASHER),
    ),
  ).to.deep.equal([mmr_size, keccak_root, original_is_offchain_grown]);

  expect(
    await satellite.getLatestMmr(
      chain_id,
      original_mmr_id,
      toU256(POSEIDON_HASHER),
    ),
  ).to.deep.equal([mmr_size, poseidon_root, original_is_offchain_grown]);

  return {
    satellite,
    satelliteAddress,
    chain_id,
    original_mmr_id,
    mmr_size,
    keccak_root,
    poseidon_root,
  };
}

async function setup_mmr_single_hashing_functions(
  original_is_offchain_grown: boolean,
) {
  const { satellite, satelliteAddress } = await loadFixture(deploy);

  // Set up some MMR for testing
  const chain_id = BigInt(11155111);
  const original_mmr_id = BigInt(123);
  const mmr_size = BigInt(10);
  const keccak_root = BigInt(
    "0x4c466c582074f6351b729134d42c66b15b7e1218fa63f1bfd614045ea96cd66a",
  );
  const poseidon_root = BigInt(
    "0x3c5f312ba85ad56867cd2de63d79e4ba910c90d9e82437d023846a044d10952",
  );
  const roots_for_hashing_functions = [
    { root: keccak_root, hashing_function: KECCAK_HASHER },
  ];

  for (const r of roots_for_hashing_functions) {
    await setMmrData(
      satelliteAddress,
      chain_id,
      original_mmr_id,
      r.hashing_function,
      original_is_offchain_grown,
      mmr_size,
      r.root,
    );
  }

  expect(
    await satellite.getLatestMmr(
      chain_id,
      original_mmr_id,
      toU256(KECCAK_HASHER),
    ),
  ).to.deep.equal([mmr_size, keccak_root, original_is_offchain_grown]);

  return {
    satellite,
    satelliteAddress,
    chain_id,
    original_mmr_id,
    mmr_size,
    keccak_root,
    poseidon_root,
  };
}

describe("createMmrFromDomestic", () => {
  // ========== Branch out from offchain MMR with multiple hashing functions ========== //

  it("multiple_offchain_to_multiple_offchain", async () => {
    let {
      satellite,
      chain_id,
      original_mmr_id,
      mmr_size,
      keccak_root,
      poseidon_root,
    } = await setup_mmr_multiple_hashing_functions();

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [toU256(KECCAK_HASHER), toU256(POSEIDON_HASHER)];
    await satellite.createMmrFromDomestic(
      new_mmr_id,
      original_mmr_id,
      chain_id,
      mmr_size,
      hashing_functions,
      new_is_offchain_grown,
    );

    expect(
      await satellite.getLatestMmr(chain_id, new_mmr_id, toU256(KECCAK_HASHER)),
    ).to.deep.equal([mmr_size, keccak_root, new_is_offchain_grown]);
    expect(
      await satellite.getLatestMmr(
        chain_id,
        new_mmr_id,
        toU256(POSEIDON_HASHER),
      ),
    ).to.deep.equal([mmr_size, poseidon_root, new_is_offchain_grown]);
  });

  it("multiple_offchain_to_multiple_offchain_invalid_hashing_function", async () => {
    let {
      satellite,
      chain_id,
      original_mmr_id,
      mmr_size,
      keccak_root,
      poseidon_root,
    } = await setup_mmr_multiple_hashing_functions();

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [toU256(KECCAK_HASHER), toU256(0x111)];

    // Should panic because hashing function 0x111 doesn't exist
    await expect(
      satellite.createMmrFromDomestic(
        new_mmr_id,
        original_mmr_id,
        chain_id,
        mmr_size,
        hashing_functions,
        new_is_offchain_grown,
      ),
    ).to.be.revertedWith("SRC_MMR_NOT_FOUND");
  });

  it("multiple_offchain_to_single_offchain", async () => {
    let { satellite, chain_id, original_mmr_id, mmr_size, keccak_root } =
      await setup_mmr_multiple_hashing_functions();

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [toU256(KECCAK_HASHER)];
    await satellite.createMmrFromDomestic(
      new_mmr_id,
      original_mmr_id,
      chain_id,
      mmr_size,
      hashing_functions,
      new_is_offchain_grown,
    );

    expect(
      await satellite.getLatestMmr(chain_id, new_mmr_id, toU256(KECCAK_HASHER)),
    ).to.deep.equal([mmr_size, keccak_root, new_is_offchain_grown]);
    expect(
      await satellite.getLatestMmr(
        chain_id,
        new_mmr_id,
        toU256(POSEIDON_HASHER),
      ),
    ).to.deep.equal([0, 0, false]);
  });

  it("multiple_offchain_to_single_offchain_invalid_hashing_function", async () => {
    let { satellite, chain_id, original_mmr_id, mmr_size } =
      await setup_mmr_multiple_hashing_functions();

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [toU256(0x111)];

    // Should panic because hashing function 0x111 doesn't exist
    await expect(
      satellite.createMmrFromDomestic(
        new_mmr_id,
        original_mmr_id,
        chain_id,
        mmr_size,
        hashing_functions,
        new_is_offchain_grown,
      ),
    ).to.be.revertedWith("SRC_MMR_NOT_FOUND");
  });

  it("multiple_offchain_to_multiple_onchain", async () => {
    let { satellite, chain_id, original_mmr_id, mmr_size } =
      await setup_mmr_multiple_hashing_functions();

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [toU256(KECCAK_HASHER), toU256(POSEIDON_HASHER)];

    // Should panic because onchain MMRs can have only one hashing function
    await expect(
      satellite.createMmrFromDomestic(
        new_mmr_id,
        original_mmr_id,
        chain_id,
        mmr_size,
        hashing_functions,
        new_is_offchain_grown,
      ),
    ).to.be.revertedWith("INVALID_HASHING_FUNCTIONS_LENGTH");
  });

  it("multiple_offchain_to_single_onchain", async () => {
    let { satellite, chain_id, original_mmr_id, mmr_size, keccak_root } =
      await setup_mmr_multiple_hashing_functions();

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [toU256(KECCAK_HASHER)];
    await satellite.createMmrFromDomestic(
      new_mmr_id,
      original_mmr_id,
      chain_id,
      mmr_size,
      hashing_functions,
      new_is_offchain_grown,
    );

    expect(
      await satellite.getLatestMmr(chain_id, new_mmr_id, toU256(KECCAK_HASHER)),
    ).to.deep.equal([mmr_size, keccak_root, new_is_offchain_grown]);
    expect(
      await satellite.getLatestMmr(
        chain_id,
        new_mmr_id,
        toU256(POSEIDON_HASHER),
      ),
    ).to.deep.equal([0, 0, false]);
  });

  it("multiple_offchain_to_single_onchain_invalid_hashing_function", async () => {
    let { satellite, chain_id, original_mmr_id, mmr_size } =
      await setup_mmr_multiple_hashing_functions();

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [toU256(0x111)];
    await expect(
      satellite.createMmrFromDomestic(
        new_mmr_id,
        original_mmr_id,
        chain_id,
        mmr_size,
        hashing_functions,
        new_is_offchain_grown,
      ),
    ).to.be.revertedWith("SRC_MMR_NOT_FOUND");
  });

  // ========== Branch out from offchain MMR with single hashing functions ========== //

  it("single_offchain_to_multiple_offchain", async () => {
    let { satellite, chain_id, original_mmr_id, mmr_size } =
      await setup_mmr_single_hashing_functions(true);

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [toU256(KECCAK_HASHER), toU256(POSEIDON_HASHER)];

    // Should panic because hashing function doesn't exist in original MMR
    // Errors with SRC_MMR_NOT_FOUND, because root for provided hashing function does not exist in original MMR
    await expect(
      satellite.createMmrFromDomestic(
        new_mmr_id,
        original_mmr_id,
        chain_id,
        mmr_size,
        hashing_functions,
        new_is_offchain_grown,
      ),
    ).to.be.revertedWith("SRC_MMR_NOT_FOUND");
  });

  it("single_offchain_to_single_offchain", async () => {
    let { satellite, chain_id, original_mmr_id, mmr_size, keccak_root } =
      await setup_mmr_single_hashing_functions(true);

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [toU256(KECCAK_HASHER)];
    await satellite.createMmrFromDomestic(
      new_mmr_id,
      original_mmr_id,
      chain_id,
      mmr_size,
      hashing_functions,
      new_is_offchain_grown,
    );

    expect(
      await satellite.getLatestMmr(chain_id, new_mmr_id, toU256(KECCAK_HASHER)),
    ).to.deep.equal([mmr_size, keccak_root, new_is_offchain_grown]);
    expect(
      await satellite.getLatestMmr(
        chain_id,
        new_mmr_id,
        toU256(POSEIDON_HASHER),
      ),
    ).to.deep.equal([0, 0, false]);
  });

  it("single_offchain_to_single_offchain_invalid_hashing_function", async () => {
    let { satellite, chain_id, original_mmr_id, mmr_size } =
      await setup_mmr_single_hashing_functions(true);

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [toU256(POSEIDON_HASHER)];

    // Should panic because hashing function POSEIDON_HASHING_FUNCTION doesn't exist
    await expect(
      satellite.createMmrFromDomestic(
        new_mmr_id,
        original_mmr_id,
        chain_id,
        mmr_size,
        hashing_functions,
        new_is_offchain_grown,
      ),
    ).to.be.revertedWith("SRC_MMR_NOT_FOUND");
  });

  it("single_offchain_to_multiple_onchain", async () => {
    let { satellite, chain_id, original_mmr_id, mmr_size } =
      await setup_mmr_single_hashing_functions(true);

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [toU256(KECCAK_HASHER), toU256(POSEIDON_HASHER)];

    // Should panic because onchain MMRs can have only one hashing function
    await expect(
      satellite.createMmrFromDomestic(
        new_mmr_id,
        original_mmr_id,
        chain_id,
        mmr_size,
        hashing_functions,
        new_is_offchain_grown,
      ),
    ).to.be.revertedWith("INVALID_HASHING_FUNCTIONS_LENGTH");
  });

  it("single_offchain_to_single_onchain", async () => {
    let { satellite, chain_id, original_mmr_id, mmr_size, keccak_root } =
      await setup_mmr_single_hashing_functions(true);

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [toU256(KECCAK_HASHER)];
    await satellite.createMmrFromDomestic(
      new_mmr_id,
      original_mmr_id,
      chain_id,
      mmr_size,
      hashing_functions,
      new_is_offchain_grown,
    );

    expect(
      await satellite.getLatestMmr(chain_id, new_mmr_id, toU256(KECCAK_HASHER)),
    ).to.deep.equal([mmr_size, keccak_root, new_is_offchain_grown]);
    expect(
      await satellite.getLatestMmr(
        chain_id,
        new_mmr_id,
        toU256(POSEIDON_HASHER),
      ),
    ).to.deep.equal([0, 0, false]);
  });

  it("single_offchain_to_single_onchain_invalid_hashing_function", async () => {
    let { satellite, chain_id, original_mmr_id, mmr_size } =
      await setup_mmr_single_hashing_functions(true);

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [toU256(POSEIDON_HASHER)];

    // Should panic because hashing function POSEIDON_HASHING_FUNCTION doesn't exist
    await expect(
      satellite.createMmrFromDomestic(
        new_mmr_id,
        original_mmr_id,
        chain_id,
        mmr_size,
        hashing_functions,
        new_is_offchain_grown,
      ),
    ).to.be.revertedWith("SRC_MMR_NOT_FOUND");
  });

  // ========== Branch out from onchain MMR with single hashing functions ========== //

  it("single_onchain_to_multiple_offchain", async () => {
    let { satellite, chain_id, original_mmr_id, mmr_size } =
      await setup_mmr_single_hashing_functions(false);

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [toU256(KECCAK_HASHER), toU256(POSEIDON_HASHER)];

    // Should panic because hashing function doesn't exist in original MMR
    // Errors with SRC_MMR_NOT_FOUND, because root for provided hashing function does not exist in original MMR
    await expect(
      satellite.createMmrFromDomestic(
        new_mmr_id,
        original_mmr_id,
        chain_id,
        mmr_size,
        hashing_functions,
        new_is_offchain_grown,
      ),
    ).to.be.revertedWith("SRC_MMR_NOT_FOUND");
  });

  it("single_onchain_to_single_offchain", async () => {
    let { satellite, chain_id, original_mmr_id, mmr_size, keccak_root } =
      await setup_mmr_single_hashing_functions(false);

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [toU256(KECCAK_HASHER)];
    await satellite.createMmrFromDomestic(
      new_mmr_id,
      original_mmr_id,
      chain_id,
      mmr_size,
      hashing_functions,
      new_is_offchain_grown,
    );

    expect(
      await satellite.getLatestMmr(chain_id, new_mmr_id, toU256(KECCAK_HASHER)),
    ).to.deep.equal([mmr_size, keccak_root, new_is_offchain_grown]);
    expect(
      await satellite.getLatestMmr(
        chain_id,
        new_mmr_id,
        toU256(POSEIDON_HASHER),
      ),
    ).to.deep.equal([0, 0, false]);
  });

  it("single_onchain_to_single_offchain_invalid_hashing_function", async () => {
    let { satellite, chain_id, original_mmr_id, mmr_size } =
      await setup_mmr_single_hashing_functions(false);

    let new_mmr_id = 456;
    let new_is_offchain_grown = true;
    let hashing_functions = [toU256(POSEIDON_HASHER)];
    await expect(
      satellite.createMmrFromDomestic(
        new_mmr_id,
        original_mmr_id,
        chain_id,
        mmr_size,
        hashing_functions,
        new_is_offchain_grown,
      ),
    ).to.be.revertedWith("SRC_MMR_NOT_FOUND");
  });

  it("single_onchain_to_multiple_onchain", async () => {
    let { satellite, chain_id, original_mmr_id, mmr_size } =
      await setup_mmr_single_hashing_functions(false);

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [toU256(KECCAK_HASHER), toU256(POSEIDON_HASHER)];

    // Should panic because onchain MMRs can have only one hashing function
    await expect(
      satellite.createMmrFromDomestic(
        new_mmr_id,
        original_mmr_id,
        chain_id,
        mmr_size,
        hashing_functions,
        new_is_offchain_grown,
      ),
    ).to.be.revertedWith("INVALID_HASHING_FUNCTIONS_LENGTH");
  });

  it("single_onchain_to_single_onchain", async () => {
    let { satellite, chain_id, original_mmr_id, mmr_size, keccak_root } =
      await setup_mmr_single_hashing_functions(false);

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [toU256(KECCAK_HASHER)];
    await satellite.createMmrFromDomestic(
      new_mmr_id,
      original_mmr_id,
      chain_id,
      mmr_size,
      hashing_functions,
      new_is_offchain_grown,
    );

    expect(
      await satellite.getLatestMmr(chain_id, new_mmr_id, toU256(KECCAK_HASHER)),
    ).to.deep.equal([mmr_size, keccak_root, new_is_offchain_grown]);
    expect(
      await satellite.getLatestMmr(
        chain_id,
        new_mmr_id,
        toU256(POSEIDON_HASHER),
      ),
    ).to.deep.equal([0, 0, false]);
  });

  it("single_onchain_to_single_onchain_invalid_hashing_function", async () => {
    let { satellite, chain_id, original_mmr_id, mmr_size } =
      await setup_mmr_single_hashing_functions(false);

    let new_mmr_id = 456;
    let new_is_offchain_grown = false;
    let hashing_functions = [toU256(POSEIDON_HASHER)];
    await expect(
      satellite.createMmrFromDomestic(
        new_mmr_id,
        original_mmr_id,
        chain_id,
        mmr_size,
        hashing_functions,
        new_is_offchain_grown,
      ),
    ).to.be.revertedWith("SRC_MMR_NOT_FOUND");
  });
});
