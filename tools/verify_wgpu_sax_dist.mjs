import { readFileSync, statSync } from "node:fs";
import { join } from "node:path";

const dir = process.argv[2];
if (!dir) {
  console.error("usage: node tools/verify_wgpu_sax_dist.mjs <dist-dir>");
  process.exit(2);
}

for (const name of ["app.sa", "app.wasm", "airlock.js", "wgpu_airlock.js", "index.html"]) {
  const path = join(dir, name);
  if (!statSync(path).isFile()) {
    console.error(`missing ${name}`);
    process.exit(1);
  }
}

const wasm = readFileSync(join(dir, "app.wasm"));
if (wasm.length < 8 || wasm.subarray(0, 8).toString("hex") !== "0061736d01000000") {
  console.error("app.wasm is not a WebAssembly module");
  process.exit(1);
}

const appSa = readFileSync(join(dir, "app.sa"), "utf8");
for (const needle of ["WGPU_CUBE_SHADER", "struct Uniforms", "WGPU_CUBE_VERTICES", "sa_wgpu_submit_cube_frame"]) {
  if (!appSa.includes(needle)) {
    console.error(`app.sa missing SA-owned WGPU token: ${needle}`);
    process.exit(1);
  }
}

const airlock = readFileSync(join(dir, "airlock.js"), "utf8");
for (const needle of ["const SAX_WGPU_REQUIRED = true;", "await import(\"./wgpu_airlock.js\")", "sax_wgpu_bind_wasm(instance, _mem)"]) {
  if (!airlock.includes(needle)) {
    console.error(`airlock.js missing WGPU integration token: ${needle}`);
    process.exit(1);
  }
}

const wgpuAirlock = readFileSync(join(dir, "wgpu_airlock.js"), "utf8");
for (const forbidden of ["WGPU_CUBE_VERTICES", "WGPU_CUBE_SHADER", "struct Uniforms", "cube_vertices"]) {
  if (wgpuAirlock.includes(forbidden)) {
    console.error(`wgpu_airlock.js contains SA-owned WGPU token: ${forbidden}`);
    process.exit(1);
  }
}
