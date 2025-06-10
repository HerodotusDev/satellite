import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("AuthenticatedMockFactsRegistry", (m) => {
  const factsRegistry = m.contract("AuthenticatedMockFactsRegistry");

  return { factsRegistry };
});
