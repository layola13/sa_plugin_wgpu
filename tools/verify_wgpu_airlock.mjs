import { readFileSync } from "node:fs";

const path = process.argv[2];
if (!path) {
  console.error("usage: node tools/verify_wgpu_airlock.mjs <wgpu_airlock.js>");
  process.exit(2);
}

const source = readFileSync(path, "utf8");
const required = [
  "export const sax_wgpu_airlock",
  "sa_wgpu_request_context",
  "sa_wgpu_create_buffer",
  "sa_wgpu_create_shader",
  "sa_wgpu_create_cube_pipeline",
  "sa_wgpu_write_buffer_frame",
  "sa_wgpu_submit_cube_frame",
  "export function sax_wgpu_bind_wasm",
  "typeof navigator === \"undefined\" || !navigator.gpu",
  "cannot request WebGPU frame without a context handle",
  "if (ctx_key === 0) return 0;",
  "depth24plus",
  "depthStencilAttachment",
  "GPUTextureUsage.RENDER_ATTACHMENT",
];
for (const needle of required) {
  if (!source.includes(needle)) {
    console.error(`missing broker symbol: ${needle}`);
    process.exit(1);
  }
}

const forbidden = [
  "WGPU_CUBE_VERTICES",
  "WGPU_CUBE_SHADER",
  "struct Uniforms",
  "cube_vertices",
];
for (const needle of forbidden) {
  if (source.includes(needle)) {
    console.error(`broker contains SA-owned kernel/data token: ${needle}`);
    process.exit(1);
  }
}
