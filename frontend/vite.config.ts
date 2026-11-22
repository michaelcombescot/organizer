import { defineConfig } from "vite";
import preact from "@preact/preset-vite";
import tailwindcss from "@tailwindcss/vite";
import { icpBindgen } from "@icp-sdk/bindgen/plugins/vite";
import { execSync } from "child_process";
import { readFileSync } from "fs";

const environment = process.env.ICP_ENVIRONMENT || "local";
const CANISTER_NAMES = ["RegistryIndexes"];

const icp = (args: string) =>
  execSync(`icp ${args} -e ${environment}`, { encoding: "utf-8", stdio: "pipe" }).trim();

function getCanisterId(name: string): string {
  try {
    const ids = JSON.parse(readFileSync(`../.icp/cache/mapping/${environment}.ids.json`, "utf-8"));
    if (ids[name]) return ids[name];
  } catch {}
  return icp(`canister status ${name} --id-only`);
}

function getDevServerConfig() {
  const network = JSON.parse(icp("network status --json"));
  const canisters = CANISTER_NAMES
    .map((name) => `PUBLIC_CANISTER_ID:${name}=${getCanisterId(name)}`)
    .join("&");

  return {
    headers: {
      "Set-Cookie": `ic_env=${encodeURIComponent(`${canisters}&ic_root_key=${network.root_key}`)}; SameSite=Lax;`,
    },
    proxy: {
      "/api": { target: network.api_url, changeOrigin: true },
    },
  };
}

export default defineConfig(({ command }) => ({
  plugins: [
    preact(),
    tailwindcss(),
    ...["RegistryIndexes", "IndexMain", "BucketUsers", "SearchIndexes"].map((name) =>
      icpBindgen({
        didFile: `../.mops/.build/${name}.did`,
        outDir: "./src/backend/api",
      })
    ),
  ],
  ...(command === "serve" ? { server: getDevServerConfig() } : {}),
}));
