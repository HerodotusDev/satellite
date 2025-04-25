import { ignition } from "hardhat";
import SatelliteModule from "../ignition/modules/31337";

describe("Deployment", () => {
  it("should deploy the satellite", async () => {
    const { satellite } = await ignition.deploy(SatelliteModule);
    console.log(await satellite.POSEIDON_HASHING_FUNCTION());
  });
});
