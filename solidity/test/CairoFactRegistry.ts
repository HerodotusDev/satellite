import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { deploy } from "./utils";
import { expect } from "chai";
import { ethers, ignition } from "hardhat";
import MockFactsRegistry from "../ignition/modules/MockFactsRegistry";

describe("CairoFactRegistry", () => {
  it("Real fact registry ", async () => {
    const { satellite } = await loadFixture(deploy);
    const { factsRegistry } = await ignition.deploy(MockFactsRegistry);

    expect(await satellite.getCairoVerifiedFactRegistryContract()).to.equal(
      "0x0000000000000000000000000000000000000000",
    );
    await satellite.setCairoVerifiedFactRegistryContract(
      await factsRegistry.getAddress(),
    );
    expect(await satellite.getCairoVerifiedFactRegistryContract()).to.equal(
      await factsRegistry.getAddress(),
    );

    const hash = ethers.randomBytes(32);

    expect(await satellite.isCairoVerifiedFactValid(hash)).to.equal(false);
    expect(await satellite.isCairoVerifiedFactStored(hash)).to.equal(false);

    await factsRegistry.setValid(hash);

    expect(await satellite.isCairoVerifiedFactValid(hash)).to.equal(true);
    expect(await satellite.isCairoVerifiedFactStored(hash)).to.equal(false);

    await expect(satellite.storeCairoVerifiedFact(hash))
      .to.emit(satellite, "CairoFactSet")
      .withArgs(hash);

    expect(await satellite.isCairoVerifiedFactValid(hash)).to.equal(true);
    expect(await satellite.isCairoVerifiedFactStored(hash)).to.equal(true);
  });

  it("Mocked fact registry no fallback", async () => {
    const { satellite } = await loadFixture(deploy);
    const [_, admin, user] = await ethers.getSigners();
    type S = typeof satellite;

    await expect(
      (satellite.connect(user) as S).manageAdmins([admin.address], true),
    ).to.be.revertedWithCustomError(satellite, "MustBeContractOwner");

    await satellite.manageAdmins([admin.address], true);

    const hash = ethers.randomBytes(32);

    expect(await satellite.isCairoMockedFactValid(hash)).to.equal(false);

    await expect((satellite.connect(admin) as S).setCairoMockedFact(hash))
      .to.emit(satellite, "CairoMockedFactSet")
      .withArgs(hash);

    expect(await satellite.isCairoMockedFactValid(hash)).to.equal(true);
  });

  it("Internal mocked fact registry", async () => {
    const { satellite } = await loadFixture(deploy);
    type S = typeof satellite;
    const [owner, admin, user] = await ethers.getSigners();
    const { factsRegistry } = await ignition.deploy(MockFactsRegistry);

    await (satellite.connect(owner) as S).setCairoVerifiedFactRegistryContract(
      await factsRegistry.getAddress(),
    );
    expect(await satellite.getCairoVerifiedFactRegistryContract()).to.equal(
      await factsRegistry.getAddress(),
    );

    await (satellite.connect(owner) as S).manageAdmins([admin.address], true);

    const hash1 = ethers.randomBytes(32);
    const hash2 = ethers.randomBytes(32);

    await (satellite.connect(owner) as S).setIsMockedForInternal(true);
    expect(await satellite.isCairoVerifiedFactValidForInternal(hash1)).to.equal(
      false,
    );
    expect(await satellite.isCairoVerifiedFactValidForInternal(hash2)).to.equal(
      false,
    );

    await (satellite.connect(owner) as S).setIsMockedForInternal(false);
    expect(await satellite.isCairoVerifiedFactValidForInternal(hash1)).to.equal(
      false,
    );
    expect(await satellite.isCairoVerifiedFactValidForInternal(hash2)).to.equal(
      false,
    );

    await factsRegistry.setValid(hash1);
    await (satellite.connect(admin) as S).setCairoMockedFact(hash2);

    await (satellite.connect(owner) as S).setIsMockedForInternal(true);
    expect(await satellite.isCairoVerifiedFactValidForInternal(hash1)).to.equal(
      false,
    );
    expect(await satellite.isCairoVerifiedFactValidForInternal(hash2)).to.equal(
      true,
    );

    await (satellite.connect(owner) as S).setIsMockedForInternal(false);
    expect(await satellite.isCairoVerifiedFactValidForInternal(hash1)).to.equal(
      true,
    );
    expect(await satellite.isCairoVerifiedFactValidForInternal(hash2)).to.equal(
      false,
    );
  });
});
