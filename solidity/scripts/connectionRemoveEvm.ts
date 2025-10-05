import hre from "hardhat";

export async function main() {
  const contract = await hre.ethers.getContractAt(
    "ISatellite",
    process.env.CONTRACT_ADDRESS as string,
  );

  const tx = await contract.removeSatellite(
    ...(process.env.ARGS!.split(",") as any),
  );

  console.log("Tx:", tx.hash);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
