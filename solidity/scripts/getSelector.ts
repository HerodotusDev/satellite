import { getSelectorWithName } from "../ignition/SatelliteDeployment";

function main() {
  if (Bun.argv.length < 3) {
    console.error("Usage: getSelector <interfaceName>");
    process.exit(1);
  }
  const selectors = getSelectorWithName(Bun.argv[2]);
  console.log(JSON.stringify(selectors, null, 2));
}

main();
