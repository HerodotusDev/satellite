import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("MockFactsRegistry", (m) => {
  const factsRegistry = m.contract("MockFactsRegistry");

  return { factsRegistry };
});
