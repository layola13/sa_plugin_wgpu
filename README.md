# sa_plugin_wgpu

`sa_plugin_wgpu` is a browser WebGPU sidecar plugin for SAX.

It deliberately keeps WebGPU kernel material out of JavaScript. The broker in `wgpu_airlock.js` only owns browser-only operations: `navigator.gpu`, GPU object handles, byte uploads, and command submission. WGSL, vertex bytes, index bytes, uniform frames, and frame selection are emitted by SA/WASM.

The v0.1 acceptance target is a rotating 3D cube built from SAX and rendered in the browser through WebGPU. The shared sidecar now also exposes the first generic render-pipeline and draw-submit contract used by `sa_plugin_3dengines/sa_plugin_3d_render_wgpu`. This is still not a complete WebGPU engine: compute pipelines, textures, render graph scheduling, multi-pass render composition, and high-performance dashboard primitives are future work.

## Commands

```bash
sa wgpu airlock --out dist/wgpu_airlock.js
sa wgpu new cube-demo
sa wgpu check app.sax
```

## Build

```bash
zig build test
zig build install-smoke
```

`zig build test` builds the native plugin, runs SA `@test` coverage for the shared WGPU descriptors, installs the generated share assets, verifies that the JS broker does not contain SA-owned WGSL/geometry data, runs `sa wgpu check`, builds the rotating cube SAX demo, and statically verifies the generated SAX dist.

`zig build install-smoke` installs WGPU and SAX into an isolated plugin home and verifies that the installed layout exposes the expected share and SA interface files.

## Plugin install

`sap.json` declares a required dependency on the sibling SAX plugin:

```json
"dependencies": {
  "sax": {
    "version": ">=0.1.0",
    "abi": 1,
    "path": "../sa_plugin_sax",
    "optional": false
  }
}
```

From this directory, install the WGPU plugin with the SA host. For a local development checkout, use `--dev` so the installer accepts the local dependency path and development artifacts:

```bash
SA_PLUGIN_DEV=1 \
  /home/vscode/projects/sci/zig-out/bin/sa plugin install --dev .
```

For an isolated install home, which is what the smoke test uses:

```bash
SA_PLUGINS_HOME=/home/vscode/projects/sa_plugins/sa_plugin_wgpu/.zig-cache/wgpu-install-smoke-home \
SA_PLUGIN_DEV=1 \
  /home/vscode/projects/sci/zig-out/bin/sa plugin install --dev .

node tools/verify_wgpu_install.mjs \
  /home/vscode/projects/sa_plugins/sa_plugin_wgpu/.zig-cache/wgpu-install-smoke-home \
  /home/vscode/projects/sci/zig-out/bin/sa
```

The installer reads `sap.json`, installs the required `sax` dependency from `../sa_plugin_sax`, then installs `wgpu`. The expected installed layout is:

- `$SA_PLUGINS_HOME/installed/sax/current/libsax.so`
- `$SA_PLUGINS_HOME/installed/wgpu/current/libwgpu.so`
- `$SA_PLUGINS_HOME/installed/wgpu/current/sa/wgpu.sai`
- `$SA_PLUGINS_HOME/installed/wgpu/current/sa/wgpu.sal`
- `$SA_PLUGINS_HOME/installed/wgpu/current/share/wgpu_airlock.js`
- `$SA_PLUGINS_HOME/installed/wgpu/current/share/demos/rotating_cube.sax`

After installation, SAX can discover the WGPU sidecar from `SA_PLUGINS_HOME`, so the browser demo can be built without manually setting `SA_PLUGINS_PATH`:

```bash
SA_PLUGINS_HOME=/home/vscode/projects/sa_plugins/sa_plugin_wgpu/.zig-cache/wgpu-install-smoke-home \
SA_PLUGIN_DEV=1 \
  /home/vscode/projects/sci/zig-out/bin/sa sax build demos/rotating_cube.sax \
  --out-dir .zig-cache/acceptance-rotating-cube
```

The build installs:

- `zig-out/lib/libwgpu.so`
- `zig-out/share/wgpu_airlock.js`
- `zig-out/share/wgpu.sai`
- `zig-out/share/wgpu.sal`
- `zig-out/share/demos/rotating_cube.sax`

The browser acceptance build used during development is generated here:

- `.zig-cache/acceptance-rotating-cube/index.html`
- `.zig-cache/acceptance-rotating-cube/airlock.js`
- `.zig-cache/acceptance-rotating-cube/wgpu_airlock.js`
- `.zig-cache/acceptance-rotating-cube/app.wasm`
- `.zig-cache/acceptance-rotating-cube/app.sa`

The isolated install-smoke plugin home is:

- `.zig-cache/wgpu-install-smoke-home/installed/wgpu/current/`
- `.zig-cache/wgpu-install-smoke-home/installed/sax/current/`

Formal plugin install also copies these files into `installed/wgpu/current/share/`, and copies `wgpu.sai` / `wgpu.sal` into `installed/wgpu/current/sa/`. The `.sai` entries are browser WASM imports, so native plugin symbol smoke does not expect `libwgpu.so` to export `sa_wgpu_*`.

For a SAX build, include both plugins in `SA_PLUGINS_PATH` so SAX can find the WGPU sidecar:

```bash
SA_PLUGINS_PATH=/home/vscode/projects/sa_plugins/sa_plugin_sax/zig-out/lib/libsax.so:/home/vscode/projects/sa_plugins/sa_plugin_wgpu/zig-out/lib/libwgpu.so \
  sa sax build demos/rotating_cube.sax --out-dir dist
```

If the plugins are formally installed, `sa sax build demos/rotating_cube.sax --out-dir dist` can discover `installed/wgpu/current/share/` from `SA_PLUGINS_HOME`. For explicit wiring, set `SA_WGPU_SHARE_DIR=/path/to/wgpu/share`.

## Browser acceptance

Build the acceptance dist from the isolated installed plugin layout:

```bash
SA_PLUGINS_HOME=/home/vscode/projects/sa_plugins/sa_plugin_wgpu/.zig-cache/wgpu-install-smoke-home \
SA_PLUGIN_DEV=1 \
  /home/vscode/projects/sci/zig-out/bin/sa sax build demos/rotating_cube.sax \
  --out-dir .zig-cache/acceptance-rotating-cube

node tools/verify_wgpu_sax_dist.mjs .zig-cache/acceptance-rotating-cube
```

Serve the generated browser files with Bun:

```bash
setsid bun -e '
const root = ".zig-cache/acceptance-rotating-cube";
const port = 5173;
const types = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".wasm": "application/wasm", ".sa": "text/plain; charset=utf-8" };
function ext(path) { const i = path.lastIndexOf("."); return i < 0 ? "" : path.slice(i); }
const server = Bun.serve({
  hostname: "0.0.0.0",
  port,
  async fetch(req) {
    const url = new URL(req.url);
    let name = url.pathname === "/" ? "index.html" : decodeURIComponent(url.pathname.slice(1));
    name = name.replace(/^\.\.(\/|$)/g, "");
    const file = Bun.file(`${root}/${name}`);
    if (!(await file.exists())) return new Response("Not found", { status: 404 });
    return new Response(file, { headers: { "Content-Type": types[ext(name)] || "application/octet-stream", "Cache-Control": "no-store" } });
  },
});
console.log(`SAX WGPU cube server: http://127.0.0.1:${server.port}/`);
await new Promise(() => {});
' >/tmp/sa_plugin_wgpu_cube_server_5173.log 2>&1 < /dev/null &
```

Open `http://127.0.0.1:5173/`. The current acceptance canvas is fixed at `1024 x 768`.

## Current cube implementation

- `wgpu.sal` owns the WGSL shader, 24 cube vertices, 36 `uint16` indices, and 240 uniform frames. At 60 FPS, that is roughly one full rotation every four seconds.
- `demos/rotating_cube.sax` and `src/rotating_cube.sax` create the WebGPU buffers from SA/WASM memory, write the selected uniform frame each RAF tick, submit the indexed draw, and wrap the frame counter.
- `wgpu_airlock.js` remains a browser broker only: it requests `navigator.gpu`, creates GPU handles, uploads byte slices, configures a fixed-size canvas, owns the `depth24plus` depth texture, creates render pipelines from SA-owned descriptors, and submits render passes.
- `sa_wgpu_write_buffer_frame` was added so SAX can pass the SA-owned uniform frame table to the broker without moving the frame data into JavaScript.
- The demo references the `gpu-curtains` basic cube shape by using per-face cube vertices and indexed triangle-list drawing, while keeping the rendering kernel and data in SA-owned files.

## Shared WGPU Contract

The shared WebGPU sidecar covers the first Bevy render-device path:

- `sa_wgpu_create_buffer` maps to Bevy's `RenderDevice::create_buffer_with_data` style upload path.
- `sa_wgpu_create_shader` maps to WebGPU shader module creation with WGSL still owned by SA/WASM.
- `sa_wgpu_create_render_pipeline` reads a SA `WGPU_RENDER_PIPELINE_DESC` and creates a browser `GPURenderPipeline` with vertex layout, primitive topology, cull mode, one uniform bind group, and optional `depth24plus`.
- `sa_wgpu_submit_indexed_draw` reads a SA `WGPU_DRAW_DESC`, begins a render pass, binds pipeline/buffers/uniforms, issues indexed or non-indexed draw, and submits the command buffer.
- `sa_wgpu_create_cube_pipeline` and `sa_wgpu_submit_cube_frame` remain compatibility wrappers for the rotating cube demo, but now reuse the same pipeline and draw helpers.

The matching `tests/wgpu_layout_test.sa` validates descriptor layout and legality with SA `@test`; browser-only GPU behavior remains covered by the generated airlock verifier and rotating cube SAX build/browser acceptance steps.
