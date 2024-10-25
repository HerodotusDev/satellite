import { promises as fs } from "fs";
import * as path from "path";

type ContractsWithSelectors = Record<string, string[]>;

const OUT_PATH = "./out";
const OUT_FILE = "contracts-with-selectors.json";

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

async function main() {
  let contractsWithSelectors = await getContractsWithSelectors();
  let oufFilePath = path.join(OUT_PATH, OUT_FILE);

  await fs.writeFile(
    oufFilePath,
    JSON.stringify(contractsWithSelectors, null, 2),
  );

  console.log(`\n✅ Successfully generated ${oufFilePath}\n`);
}

async function getContractsWithSelectors(): Promise<ContractsWithSelectors> {
  const folders = await fs.readdir(OUT_PATH);

  // Filter for files that start with 'I' and contain 'Module' in the name
  const targetFolders = folders.filter(
    (folder) =>
      folder.startsWith("I") &&
      folder.includes("Module") &&
      folder.endsWith(".sol"),
  );

  let contractsWithSelectors: ContractsWithSelectors = {};

  console.log(`\n== Detected Satellite Modules' functions with selectors ==\n`);
  // Loop over the filtered files
  for (const folder of targetFolders) {
    const interfaceName = folder.replace(".sol", "");
    const filePath = path.join(OUT_PATH, folder, `${interfaceName}.json`);

    const data = await fs.readFile(filePath, "utf8");
    const jsonData = JSON.parse(data);

    let contractName = interfaceName.replace("I", "");
    console.log(`${contractName}`);
    // Check if methodIdentifiers field exists and log it
    let selectors = Object.entries(jsonData.methodIdentifiers).map(([k, v]) => {
      console.log(` - ${k} [${v}]`);
      let pure = (v as string).toLowerCase().replace("0x", "");
      if (pure.length !== 8)
        throw new Error(`Invalid selector length: ${pure.length}`);
      return `0x${pure}`;
    });

    contractsWithSelectors[contractName] = selectors;
  }

  return contractsWithSelectors;
}
