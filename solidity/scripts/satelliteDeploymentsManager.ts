import fs from "fs";
import { z } from "zod";

export async function getActiveEnvironmentSafe() {
  try {
    return fs.readFileSync("../deployments/_activeEnvironment", "utf8").trim();
  } catch {
    return null;
  }
}

export async function getActiveEnvironment() {
  const activeEnvironment = await getActiveEnvironmentSafe();
  if (activeEnvironment === null) {
    console.error(
      `No active environment found. Run "bun env:change" or "bun env:create"`,
    );
    process.exit(1);
  }
  return activeEnvironment;
}

export async function getDeployedSatellitesFilename() {
  return `../deployments/${await getActiveEnvironment()}.json`;
}

export async function changeEnvironment(name: string | null) {
  if (name === null) {
    await Bun.file(`../deployments/_activeEnvironment`).delete();
  } else {
    await Bun.write(`../deployments/_activeEnvironment`, name);
  }
}

const DeployedSatellitesSchema = z.object({
  satellites: z.array(
    z.object({
      chainId: z.string(),
      contractAddress: z.string(),
    }),
  ),
  connections: z.array(
    z.object({
      from: z.string(),
      to: z.string(),
    }),
  ),
});

type DeployedSatellites = z.infer<typeof DeployedSatellitesSchema>;

export async function getDeployedSatellites(): Promise<DeployedSatellites> {
  try {
    const data = JSON.parse(
      await Bun.file(await getDeployedSatellitesFilename()).text(),
    );

    return DeployedSatellitesSchema.parse(data);
  } catch {
    console.error(
      `Active environment is invalid. Run "bun env:change" or "bun env:create"`,
    );
    process.exit(1);
  }
}

export async function writeDeployedSatellites(satellites: DeployedSatellites) {
  await Bun.write(
    await getDeployedSatellitesFilename(),
    JSON.stringify(satellites, null, 2) + "\n",
  );
}

export async function isEnvironmentValid(
  name: string,
): Promise<boolean | null> {
  try {
    const file = await Bun.file(`../deployments/${name}.json`).json();
    const parsed = DeployedSatellitesSchema.safeParse(file);
    return parsed.success;
  } catch (e) {
    return e instanceof SyntaxError ? false : null;
  }
}

export function doesEnvironmentExist(name: string): Promise<boolean> {
  return Bun.file(`../deployments/${name}.json`).exists();
}
