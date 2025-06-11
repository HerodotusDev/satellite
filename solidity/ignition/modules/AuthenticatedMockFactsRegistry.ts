import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("AuthenticatedMockFactsRegistry", (m) => {
  const account = m.getAccount(0);

  const factsRegistry = m.contract(
    "AuthenticatedMockFactsRegistry",
    [account],
    { from: account },
  );

  return { factsRegistry };
});
