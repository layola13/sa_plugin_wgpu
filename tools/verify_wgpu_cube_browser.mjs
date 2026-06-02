import { access, readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import http from "node:http";
import path from "node:path";
import { pathToFileURL } from "node:url";

async function loadPlaywright() {
  try {
    return await import("playwright");
  } catch {
    const fallback = "/home/vscode/projects/sa_plugins/sa_plugin_sax/node_modules/playwright/index.mjs";
    return await import(pathToFileURL(fallback).href);
  }
}

function contentType(file) {
  if (file.endsWith(".html")) return "text/html; charset=utf-8";
  if (file.endsWith(".js")) return "text/javascript; charset=utf-8";
  if (file.endsWith(".wasm")) return "application/wasm";
  if (file.endsWith(".sa")) return "text/plain; charset=utf-8";
  return "application/octet-stream";
}

function startStaticServer(rootDir) {
  return new Promise((resolve, reject) => {
    const server = http.createServer(async (req, res) => {
      try {
        const url = new URL(req.url ?? "/", "http://127.0.0.1");
        const fileName = url.pathname === "/" ? "index.html" : url.pathname.slice(1);
        const safePath = path.normalize(fileName).replace(/^(\.\.(\/|\\|$))+/, "");
        const filePath = path.join(rootDir, safePath);
        const body = await readFile(filePath);
        res.writeHead(200, { "Content-Type": contentType(filePath), "Cache-Control": "no-store" });
        res.end(body);
      } catch (err) {
        res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
        res.end(err instanceof Error ? err.message : String(err));
      }
    });
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const address = server.address();
      if (!address || typeof address === "string") return reject(new Error("failed to bind test server"));
      resolve({ server, url: `http://127.0.0.1:${address.port}/` });
    });
  });
}

function systemChromiumPath() {
  for (const candidate of ["/usr/bin/chromium-browser", "/snap/bin/chromium", "/usr/bin/chromium"]) {
    if (existsSync(candidate)) return candidate;
  }
  return undefined;
}

async function readCanvasStats(page) {
  return await page.evaluate(() => {
    const canvas = document.querySelector("#wgpu-canvas");
    if (!canvas) throw new Error("missing #wgpu-canvas");
    const probe = document.createElement("canvas");
    probe.width = canvas.width || canvas.clientWidth;
    probe.height = canvas.height || canvas.clientHeight;
    const ctx = probe.getContext("2d");
    if (!ctx) throw new Error("2D probe canvas unavailable");
    ctx.drawImage(canvas, 0, 0, probe.width, probe.height);
    const data = ctx.getImageData(0, 0, probe.width, probe.height).data;
    let nonBg = 0;
    let checksum = 2166136261;
    for (let i = 0; i < data.length; i += 4) {
      const r = data[i];
      const g = data[i + 1];
      const b = data[i + 2];
      if (r > 12 || g > 12 || b > 12) nonBg += 1;
      checksum ^= r;
      checksum = Math.imul(checksum, 16777619) >>> 0;
      checksum ^= g;
      checksum = Math.imul(checksum, 16777619) >>> 0;
      checksum ^= b;
      checksum = Math.imul(checksum, 16777619) >>> 0;
    }
    return { width: probe.width, height: probe.height, nonBg, checksum };
  });
}

async function verifyCube(page) {
  await page.waitForSelector("#wgpu-canvas", { timeout: 10_000 });
  const hasWebGpu = await page.evaluate(() => !!globalThis.navigator?.gpu);
  if (!hasWebGpu) throw new Error("navigator.gpu is unavailable in this browser environment");
  await page.waitForTimeout(1800);
  const first = await readCanvasStats(page);
  if (first.width !== 1024 || first.height !== 768) {
    throw new Error(`WebGPU canvas size mismatch: expected 1024x768, got ${first.width}x${first.height}`);
  }
  await page.waitForTimeout(900);
  const second = await readCanvasStats(page);
  const minPixels = Math.max(64, Math.floor((first.width * first.height) / 500));
  if (first.nonBg < minPixels || second.nonBg < minPixels) {
    throw new Error(`WebGPU canvas appears blank: first=${JSON.stringify(first)} second=${JSON.stringify(second)}`);
  }
  if (first.checksum === second.checksum) {
    throw new Error(`WebGPU canvas did not change between frames: ${JSON.stringify(first)} -> ${JSON.stringify(second)}`);
  }
}

const [, , outDir] = process.argv;
if (!outDir) {
  console.error("usage: node tools/verify_wgpu_cube_browser.mjs <dist-dir>");
  process.exit(2);
}

await access(path.join(outDir, "index.html"));
await access(path.join(outDir, "airlock.js"));
await access(path.join(outDir, "wgpu_airlock.js"));
await access(path.join(outDir, "app.wasm"));

const { chromium } = await loadPlaywright();
const { server, url } = await startStaticServer(outDir);
const browser = await chromium.launch({
  headless: true,
  executablePath: process.env.CHROMIUM_PATH || systemChromiumPath(),
  args: [
    "--no-sandbox",
    "--enable-unsafe-webgpu",
    "--ignore-gpu-blocklist",
    "--enable-features=Vulkan,WebGPU",
  ],
});

try {
  const page = await browser.newPage({ viewport: { width: 1024, height: 768 } });
  const errors = [];
  page.on("pageerror", (err) => errors.push(err.stack || err.message));
  page.on("console", (msg) => {
    if (msg.type() === "error" && !msg.text().includes("Failed to load resource")) errors.push(msg.text());
  });
  await page.goto(url, { waitUntil: "networkidle" });
  await verifyCube(page);
  if (errors.length !== 0) throw new Error(`browser errors:\n${errors.join("\n")}`);
  console.log("[PASS] wgpu rotating cube browser");
} finally {
  await browser.close();
  await new Promise((resolve, reject) => server.close((err) => (err ? reject(err) : resolve())));
}
