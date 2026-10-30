import { defineConfig } from "vite";
import preact from "@preact/preset-vite";
import tailwindcss from "@tailwindcss/vite";
import { icpBindgen } from "@icp-sdk/bindgen/plugins/vite";
import { execSync } from "child_process";

const environment = process.env.ICP_ENVIRONMENT || "local";

// Canisters the frontend talks to (names from icp.yaml)
const CANISTER_NAMES = ["RegistryIndexes"];

function icp(args: string): string {
  return execSync(`icp ${args} -e ${environment}`, { encoding: "utf-8", stdio: "pipe" }).trim();
}

// In production the asset canister sets the `ic_env` cookie; in dev we simulate it
function getDevServerConfig() {
  const network = JSON.parse(icp("network status --json"));
  const canisters = CANISTER_NAMES
    .map((name) => `PUBLIC_CANISTER_ID:${name}=${icp(`canister status ${name} --id-only`)}`)
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
    icpBindgen({
      didFile: "../.mops/.build/RegistryIndexes.did",
      outDir: "./src/backend/api",
    }),
  ],
  ...(command === "serve" ? { server: getDevServerConfig() } : {}),
}));
