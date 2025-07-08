import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { deploy, ZERO_ADDRESS } from "./utils";
import { ethers } from "hardhat";
import { expect } from "chai";

describe("SatelliteRegistry", () => {
  it("Should add and remove a satellite with no send and no receive", async () => {
    const { satellite } = await loadFixture(deploy);

    const [_, otherSatellite] = await ethers.getSigners();
    const otherSatelliteAddress = BigInt(otherSatellite.address);

    const chainId = 101;

    expect(await satellite.getSatellite(chainId)).to.deep.equal([
      0n,
      ZERO_ADDRESS,
      "0x00000000",
      false,
    ]);

    await expect(
      satellite.registerSatellite(
        chainId,
        otherSatelliteAddress,
        ZERO_ADDRESS,
        "0x00000000",
        ZERO_ADDRESS,
      ),
    )
      .to.emit(satellite, "SatelliteRegistered")
      .withArgs(chainId, otherSatelliteAddress, false, ZERO_ADDRESS);

    expect(await satellite.getSatellite(chainId)).to.deep.equal([
      otherSatelliteAddress,
      ZERO_ADDRESS,
      "0x00000000",
      false,
    ]);

    await expect(satellite.removeSatellite(chainId, ZERO_ADDRESS))
      .to.emit(satellite, "SatelliteRemoved")
      .withArgs(chainId, otherSatelliteAddress);

    expect(await satellite.getSatellite(chainId)).to.deep.equal([
      0n,
      ZERO_ADDRESS,
      "0x00000000",
      false,
    ]);
  });

  it("Should add and remove a satellite with send and no receive", async () => {
    const { satellite } = await loadFixture(deploy);

    const [_, otherSatellite, inbox] = await ethers.getSigners();
    const otherSatelliteAddress = BigInt(otherSatellite.address);

    const chainId = 101;

    expect(await satellite.getSatellite(chainId)).to.deep.equal([
      0n,
      ZERO_ADDRESS,
      "0x00000000",
      false,
    ]);

    await expect(
      satellite.registerSatellite(
        chainId,
        otherSatelliteAddress,
        inbox.address,
        "0x1234abcd",
        ZERO_ADDRESS,
      ),
    )
      .to.emit(satellite, "SatelliteRegistered")
      .withArgs(chainId, otherSatelliteAddress, true, ZERO_ADDRESS);

    expect(await satellite.getSatellite(chainId)).to.deep.equal([
      otherSatelliteAddress,
      inbox.address,
      "0x1234abcd",
      false,
    ]);

    await expect(satellite.removeSatellite(chainId, ZERO_ADDRESS))
      .to.emit(satellite, "SatelliteRemoved")
      .withArgs(chainId, otherSatelliteAddress);

    expect(await satellite.getSatellite(chainId)).to.deep.equal([
      0n,
      ZERO_ADDRESS,
      "0x00000000",
      false,
    ]);
  });

  it("Should add and remove a satellite with receive and no send", async () => {
    const { satellite } = await loadFixture(deploy);

    const [_, otherSatellite, crossDomainCounterpart] =
      await ethers.getSigners();
    const otherSatelliteAddress = BigInt(otherSatellite.address);

    const chainId = 101;

    expect(await satellite.getSatellite(chainId)).to.deep.equal([
      0n,
      ZERO_ADDRESS,
      "0x00000000",
      false,
    ]);

    await expect(
      satellite.registerSatellite(
        chainId,
        otherSatelliteAddress,
        ZERO_ADDRESS,
        "0x00000000",
        crossDomainCounterpart.address,
      ),
    )
      .to.emit(satellite, "SatelliteRegistered")
      .withArgs(
        chainId,
        otherSatelliteAddress,
        false,
        crossDomainCounterpart.address,
      );

    expect(await satellite.getSatellite(chainId)).to.deep.equal([
      otherSatelliteAddress,
      ZERO_ADDRESS,
      "0x00000000",
      true,
    ]);

    await expect(
      satellite.removeSatellite(chainId, crossDomainCounterpart.address),
    )
      .to.emit(satellite, "SatelliteRemoved")
      .withArgs(chainId, otherSatelliteAddress);

    expect(await satellite.getSatellite(chainId)).to.deep.equal([
      0n,
      ZERO_ADDRESS,
      "0x00000000",
      false,
    ]);
  });

  it("Should add and remove a satellite with send and receive", async () => {
    const { satellite } = await loadFixture(deploy);

    const [_, otherSatellite, inbox, crossDomainCounterpart] =
      await ethers.getSigners();
    const otherSatelliteAddress = BigInt(otherSatellite.address);

    const chainId = 101;

    expect(await satellite.getSatellite(chainId)).to.deep.equal([
      0n,
      ZERO_ADDRESS,
      "0x00000000",
      false,
    ]);

    await expect(
      satellite.registerSatellite(
        chainId,
        otherSatelliteAddress,
        inbox.address,
        "0x567890ab",
        crossDomainCounterpart.address,
      ),
    )
      .to.emit(satellite, "SatelliteRegistered")
      .withArgs(
        chainId,
        otherSatelliteAddress,
        true,
        crossDomainCounterpart.address,
      );

    expect(await satellite.getSatellite(chainId)).to.deep.equal([
      otherSatelliteAddress,
      inbox.address,
      "0x567890ab",
      true,
    ]);

    await expect(
      satellite.removeSatellite(chainId, crossDomainCounterpart.address),
    )
      .to.emit(satellite, "SatelliteRemoved")
      .withArgs(chainId, otherSatelliteAddress);

    expect(await satellite.getSatellite(chainId)).to.deep.equal([
      0n,
      ZERO_ADDRESS,
      "0x00000000",
      false,
    ]);
  });
});
