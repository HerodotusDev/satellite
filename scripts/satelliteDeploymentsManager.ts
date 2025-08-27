import fs from "fs";
import { z } from "zod";
import settings from "../solidity/settings.json";

const DEPLOYMENTS_DIR =
  import.meta.dir.split("/").slice(0, -1).join("/") + "/deployments";

export async function getAllEnvironments() {
  const files = fs.readdirSync(DEPLOYMENTS_DIR);
  return files
    .filter((file) => file.endsWith(".json"))
    .map((file) => file.substring(0, file.length - 5));
}

export async function getActiveEnvironmentSafe() {
  try {
    return fs
      .readFileSync(DEPLOYMENTS_DIR + "/_activeEnvironment", "utf8")
      .trim();
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
  return `${DEPLOYMENTS_DIR}/${await getActiveEnvironment()}.json`;
}

export async function changeEnvironment(name: string | null) {
  if (name === null) {
    await Bun.file(DEPLOYMENTS_DIR + "/_activeEnvironment").delete();
  } else {
    await Bun.write(DEPLOYMENTS_DIR + "/_activeEnvironment", name);
  }
}

export async function deleteEnvironment(name: string) {
  const file = Bun.file(`${DEPLOYMENTS_DIR}/${name}.json`);
  // if it errors here, you have an old version of bun
  await file.delete();
}

const DeployedSatellitesSchema = z.object({
  satellites: z.record(
    z.string(), // chainId
    z.object({
      contractAddress: z.string(),
      connections: z.record(z.string(), z.object({})).optional(),
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
    const file = await Bun.file(`${DEPLOYMENTS_DIR}/${name}.json`).json();
    const parsed = DeployedSatellitesSchema.safeParse(file);
    return parsed.success;
  } catch (e) {
    return e instanceof SyntaxError ? false : null;
  }
}

export function doesEnvironmentExist(name: string): Promise<boolean> {
  return Bun.file(`${DEPLOYMENTS_DIR}/${name}.json`).exists();
}

export const STARKNET_CHAIN_IDS = [23448594291968334, 393402133025997798000961];

export function parseChainId(chainId: string) {
  let asInt = parseInt(chainId);
  if (!isNaN(asInt)) return asInt;
  else
    asInt = parseInt(
      chainId
        .split("")
        .map((x) => x.charCodeAt(0).toString(16).padStart(2, ""))
        .join(""),
      16,
    );

  if (isNaN(asInt)) return null;
  if (asInt in settings) return asInt;
  return null;
}
