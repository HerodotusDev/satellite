import { getSelector } from "../ignition/SatelliteDeployment";

function main() {
  if (Bun.argv.length < 3) {
    console.error("Usage: getSelector <interfaceName>");
    process.exit(1);
  }
  const selectors = getSelector(Bun.argv[2]);
  console.log(selectors);
}

main();
