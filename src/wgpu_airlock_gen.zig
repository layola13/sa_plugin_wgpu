const std = @import("std");

pub const AirlockGenerator = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) AirlockGenerator {
        return .{ .allocator = allocator };
    }

    pub fn generate(self: *AirlockGenerator) !std.ArrayList(u8) {
        var out = std.ArrayList(u8).init(self.allocator);
        errdefer out.deinit();
        try out.appendSlice(source);
        return out;
    }
};

pub const source =
    \\// wgpu_airlock.js -- generated WebGPU broker for SA/SAX.
    \\// The render kernel, shader bytes, geometry bytes, and frame uniforms come from SA/WASM memory.
    \\const WGPU_AIRLOCK_VERSION = "0.1";
    \\const _contexts = new Map();
    \\const _objects = new Map();
    \\let _nextHandle = 1;
    \\let _instance = null;
    \\let _mem = null;
    \\let _lastError = "";
    \\
    \\function _handle(value) {
    \\  const h = _nextHandle++;
    \\  _objects.set(h, value);
    \\  return BigInt(h);
    \\}
    \\
    \\function _object(h) {
    \\  return _objects.get(Number(h));
    \\}
    \\
    \\function _set_error(message) {
    \\  _lastError = String(message || "unknown WebGPU error");
    \\  return 1;
    \\}
    \\
    \\function _bytes(ptr, len) {
    \\  return new Uint8Array(_mem.buffer, Number(ptr), Number(len));
    \\}
    \\
    \\function _read_str(ptr, len) {
    \\  return new TextDecoder().decode(_bytes(ptr, len));
    \\}
    \\
    \\function _read_i32(ptr) {
    \\  return new DataView(_mem.buffer).getInt32(Number(ptr), true);
    \\}
    \\
    \\function _read_i64(ptr) {
    \\  return new DataView(_mem.buffer).getBigInt64(Number(ptr), true);
    \\}
    \\
    \\function _write_i64(ptr, value) {
    \\  new DataView(_mem.buffer).setBigInt64(Number(ptr), BigInt(value), true);
    \\}
    \\
    \\function _write_str(ptr, len, text) {
    \\  const bytes = new TextEncoder().encode(String(text));
    \\  const n = Math.min(bytes.length, Number(len));
    \\  _bytes(ptr, n).set(bytes.subarray(0, n));
    \\  return BigInt(n);
    \\}
    \\
    \\function _ctx(ctx_h) {
    \\  const ctx = _contexts.get(Number(ctx_h));
    \\  if (!ctx) throw new Error("invalid WebGPU context handle");
    \\  return ctx;
    \\}
    \\
    \\function _require_ready() {
    \\  if (!_instance || !_mem) throw new Error("WebGPU airlock is not bound to WASM memory");
    \\}
    \\
    \\function _vertex_format(format) {
    \\  switch (Number(format)) {
    \\    case 1: return "float32x2";
    \\    case 2: return "float32x3";
    \\    case 3: return "float32x4";
    \\    case 4: return "uint32";
    \\    default: throw new Error(`unsupported vertex format ${format}`);
    \\  }
    \\}
    \\
    \\function _primitive_topology(primitive) {
    \\  switch (Number(primitive)) {
    \\    case 0: return "triangle-list";
    \\    case 1: return "triangle-strip";
    \\    case 2: return "line-list";
    \\    case 3: return "line-strip";
    \\    case 4: return "point-list";
    \\    default: throw new Error(`unsupported primitive topology ${primitive}`);
    \\  }
    \\}
    \\
    \\function _cull_mode(mode) {
    \\  switch (Number(mode)) {
    \\    case 0: return "none";
    \\    case 1: return "front";
    \\    case 2: return "back";
    \\    default: throw new Error(`unsupported cull mode ${mode}`);
    \\  }
    \\}
    \\
    \\function _depth_compare(mode) {
    \\  switch (Number(mode)) {
    \\    case 0: return "less";
    \\    case 1: return "less-equal";
    \\    case 2: return "always";
    \\    default: throw new Error(`unsupported depth compare ${mode}`);
    \\  }
    \\}
    \\
    \\function _index_format(format) {
    \\  switch (Number(format)) {
    \\    case 1: return "uint16";
    \\    case 2: return "uint32";
    \\    default: return null;
    \\  }
    \\}
    \\
    \\function _load_op(op) {
    \\  switch (Number(op)) {
    \\    case 0: return "load";
    \\    case 1: return "clear";
    \\    default: throw new Error(`unsupported load op ${op}`);
    \\  }
    \\}
    \\
    \\function _store_op(op) {
    \\  switch (Number(op)) {
    \\    case 0: return "discard";
    \\    case 1: return "store";
    \\    default: throw new Error(`unsupported store op ${op}`);
    \\  }
    \\}
    \\
    \\function _milli(ptr) {
    \\  return _read_i32(ptr) / 1000.0;
    \\}
    \\
    \\function _normalized_sample_count(sampleCount) {
    \\  const count = Number(sampleCount) || 1;
    \\  return count > 1 ? count : 1;
    \\}
    \\
    \\function _create_render_pipeline(ctx, shader, vsEntry, fsEntry, vertexStride, attrs, primitive, cullMode, depthEnabled, depthWriteEnabled, depthCompare, uniformBinding, sampleCount) {
    \\  const multisampleCount = _normalized_sample_count(sampleCount);
    \\  const bindGroupLayout = ctx.device.createBindGroupLayout({ entries: [{ binding: Number(uniformBinding), visibility: GPUShaderStage.VERTEX | GPUShaderStage.FRAGMENT, buffer: { type: "uniform" } }] });
    \\  const pipelineLayout = ctx.device.createPipelineLayout({ bindGroupLayouts: [bindGroupLayout] });
    \\  const desc = {
    \\    layout: pipelineLayout,
    \\    vertex: { module: shader, entryPoint: vsEntry, buffers: [{ arrayStride: Number(vertexStride), attributes: attrs }] },
    \\    fragment: { module: shader, entryPoint: fsEntry, targets: [{ format: ctx.format }] },
    \\    primitive: { topology: _primitive_topology(primitive), cullMode: _cull_mode(cullMode) },
    \\    multisample: { count: multisampleCount },
    \\  };
    \\  if (Number(depthEnabled) !== 0) {
    \\    desc.depthStencil = { format: "depth24plus", depthWriteEnabled: Number(depthWriteEnabled) !== 0, depthCompare: _depth_compare(depthCompare) };
    \\  }
    \\  const pipeline = ctx.device.createRenderPipeline(desc);
    \\  return { pipeline, bindGroupLayout, uniformBinding: Number(uniformBinding), depthEnabled: Number(depthEnabled) !== 0, sampleCount: multisampleCount };
    \\}
    \\
    \\function _msaa_color_view(ctx, sampleCount) {
    \\  _resize_canvas(ctx);
    \\  const count = _normalized_sample_count(sampleCount);
    \\  if (count <= 1) return null;
    \\  const width = ctx.canvas.width;
    \\  const height = ctx.canvas.height;
    \\  if (!ctx.msaaColorTexture || ctx.msaaWidth !== width || ctx.msaaHeight !== height || ctx.msaaSampleCount !== count) {
    \\    if (ctx.msaaColorTexture) ctx.msaaColorTexture.destroy();
    \\    ctx.msaaColorTexture = ctx.device.createTexture({
    \\      size: [width, height],
    \\      sampleCount: count,
    \\      format: ctx.format,
    \\      usage: GPUTextureUsage.RENDER_ATTACHMENT,
    \\    });
    \\    ctx.msaaWidth = width;
    \\    ctx.msaaHeight = height;
    \\    ctx.msaaSampleCount = count;
    \\  }
    \\  return ctx.msaaColorTexture.createView();
    \\}
    \\
    \\function _submit_draw(ctx, draw) {
    \\  const pipelineObj = _object(draw.pipeline_h);
    \\  const vertex = _object(draw.vertex_h);
    \\  const index = draw.index_h ? _object(draw.index_h) : null;
    \\  const uniform = draw.uniform_h ? _object(draw.uniform_h) : null;
    \\  if (!pipelineObj || !vertex) throw new Error("invalid WebGPU draw pipeline or vertex buffer handle");
    \\  if (draw.indexFormat && !index) throw new Error("indexed WebGPU draw requires an index buffer handle");
    \\  const encoder = ctx.device.createCommandEncoder();
    \\  const resolveView = ctx.context.getCurrentTexture().createView();
    \\  const msaaView = _msaa_color_view(ctx, pipelineObj.sampleCount);
    \\  const colorAttachment = msaaView
    \\    ? { view: msaaView, resolveTarget: resolveView, clearValue: draw.clearValue, loadOp: draw.loadOp, storeOp: "store" }
    \\    : { view: resolveView, clearValue: draw.clearValue, loadOp: draw.loadOp, storeOp: draw.storeOp };
    \\  const passDesc = {
    \\    colorAttachments: [colorAttachment],
    \\  };
    \\  if (pipelineObj.depthEnabled) {
    \\    passDesc.depthStencilAttachment = { view: _depth_view(ctx, pipelineObj.sampleCount), depthClearValue: draw.depthClearValue, depthLoadOp: draw.depthLoadOp, depthStoreOp: draw.depthStoreOp };
    \\  } else {
    \\    _resize_canvas(ctx);
    \\  }
    \\  const pass = encoder.beginRenderPass(passDesc);
    \\  pass.setPipeline(pipelineObj.pipeline);
    \\  if (uniform) {
    \\    const bindGroup = ctx.device.createBindGroup({ layout: pipelineObj.bindGroupLayout, entries: [{ binding: pipelineObj.uniformBinding, resource: { buffer: uniform } }] });
    \\    pass.setBindGroup(0, bindGroup);
    \\  }
    \\  pass.setVertexBuffer(0, vertex);
    \\  if (draw.indexFormat) {
    \\    pass.setIndexBuffer(index, draw.indexFormat);
    \\    pass.drawIndexed(Number(draw.indexCount));
    \\  } else {
    \\    pass.draw(Number(draw.vertexCount));
    \\  }
    \\  pass.end();
    \\  ctx.device.queue.submit([encoder.finish()]);
    \\}
    \\
    \\function _resize_canvas(ctx) {
    \\  const canvas = ctx.canvas;
    \\  const attrWidth = Number(canvas.getAttribute("width"));
    \\  const attrHeight = Number(canvas.getAttribute("height"));
    \\  const width = Math.max(1, Math.floor(attrWidth || canvas.width || 1024));
    \\  const height = Math.max(1, Math.floor(attrHeight || canvas.height || 768));
    \\  if (canvas.width !== width || canvas.height !== height || !ctx.configured) {
    \\    canvas.width = width;
    \\    canvas.height = height;
    \\    ctx.context.configure({ device: ctx.device, format: ctx.format, alphaMode: "opaque" });
    \\    if (ctx.depthTexture) ctx.depthTexture.destroy();
    \\    ctx.depthTexture = null;
    \\    ctx.depthWidth = 0;
    \\    ctx.depthHeight = 0;
    \\    if (ctx.msaaColorTexture) ctx.msaaColorTexture.destroy();
    \\    ctx.msaaColorTexture = null;
    \\    ctx.msaaWidth = 0;
    \\    ctx.msaaHeight = 0;
    \\    ctx.msaaSampleCount = 1;
    \\    ctx.configured = true;
    \\  }
    \\}
    \\
    \\function _depth_view(ctx, sampleCount) {
    \\  _resize_canvas(ctx);
    \\  const count = _normalized_sample_count(sampleCount);
    \\  const width = ctx.canvas.width;
    \\  const height = ctx.canvas.height;
    \\  if (!ctx.depthTexture || ctx.depthWidth !== width || ctx.depthHeight !== height || ctx.depthSampleCount !== count) {
    \\    if (ctx.depthTexture) ctx.depthTexture.destroy();
    \\    ctx.depthTexture = ctx.device.createTexture({
    \\      size: [width, height],
    \\      sampleCount: count,
    \\      format: "depth24plus",
    \\      usage: GPUTextureUsage.RENDER_ATTACHMENT,
    \\    });
    \\    ctx.depthWidth = width;
    \\    ctx.depthHeight = height;
    \\    ctx.depthSampleCount = count;
    \\  }
    \\  return ctx.depthTexture.createView();
    \\}
    \\
    \\export function sax_wgpu_bind_wasm(instance, memory) {
    \\  _instance = instance;
    \\  _mem = memory;
    \\}
    \\
    \\export const sax_wgpu_airlock = {
    \\  sa_wgpu_request_context(canvas_h, out_ctx_ptr) {
    \\    _require_ready();
    \\    const canvas = globalThis.sax_debug_get_node ? globalThis.sax_debug_get_node(canvas_h) : null;
    \\    if (!canvas) {
    \\      _write_i64(out_ctx_ptr, 0n);
    \\      return _set_error("WebGPU canvas handle does not resolve to a DOM node");
    \\    }
    \\    if (typeof navigator === "undefined" || !navigator.gpu) {
    \\      _write_i64(out_ctx_ptr, 0n);
    \\      return _set_error("navigator.gpu is not available");
    \\    }
    \\    const ctx_h = _nextHandle++;
    \\    const pending = (async () => {
    \\      const adapter = await navigator.gpu.requestAdapter();
    \\      if (!adapter) throw new Error("WebGPU adapter request failed");
    \\      const device = await adapter.requestDevice();
    \\      const context = canvas.getContext("webgpu");
    \\      if (!context) throw new Error("canvas.getContext('webgpu') failed");
    \\      const format = navigator.gpu.getPreferredCanvasFormat();
    \\      const ctx = { canvas, adapter, device, context, format, ready: true, raf: 0, configured: false, depthTexture: null, depthWidth: 0, depthHeight: 0, depthSampleCount: 1, msaaColorTexture: null, msaaWidth: 0, msaaHeight: 0, msaaSampleCount: 1 };
    \\      _resize_canvas(ctx);
    \\      return ctx;
    \\    })().then((ctx) => {
    \\      _contexts.set(ctx_h, ctx);
    \\      return ctx;
    \\    }).catch((err) => {
    \\      _set_error(err && err.message ? err.message : err);
    \\      throw err;
    \\    });
    \\    _contexts.set(ctx_h, { ready: false, pending, raf: 0 });
    \\    _write_i64(out_ctx_ptr, ctx_h);
    \\    return 0;
    \\  },
    \\
    \\  sa_wgpu_create_buffer(ctx_h, usage, data_ptr, data_len, out_buffer_ptr) {
    \\    _require_ready();
    \\    const ctx = _ctx(ctx_h);
    \\    if (!ctx.ready) {
    \\      _write_i64(out_buffer_ptr, 0n);
    \\      return _set_error("WebGPU context is not ready yet");
    \\    }
    \\    const src = _bytes(data_ptr, data_len);
    \\    const size = Math.max(4, Math.ceil(Number(data_len) / 4) * 4);
    \\    const buffer = ctx.device.createBuffer({ size, usage: Number(usage), mappedAtCreation: true });
    \\    new Uint8Array(buffer.getMappedRange()).set(src);
    \\    buffer.unmap();
    \\    _write_i64(out_buffer_ptr, _handle(buffer));
    \\    return 0;
    \\  },
    \\
    \\  sa_wgpu_create_shader(ctx_h, wgsl_ptr, wgsl_len, out_shader_ptr) {
    \\    _require_ready();
    \\    const ctx = _ctx(ctx_h);
    \\    if (!ctx.ready) {
    \\      _write_i64(out_shader_ptr, 0n);
    \\      return _set_error("WebGPU context is not ready yet");
    \\    }
    \\    const code = _read_str(wgsl_ptr, wgsl_len);
    \\    const shader = ctx.device.createShaderModule({ code });
    \\    _write_i64(out_shader_ptr, _handle(shader));
    \\    return 0;
    \\  },
    \\
    \\  sa_wgpu_create_render_pipeline(ctx_h, desc_ptr, out_pipeline_ptr) {
    \\    _require_ready();
    \\    const ctx = _ctx(ctx_h);
    \\    if (!ctx.ready) {
    \\      _write_i64(out_pipeline_ptr, 0n);
    \\      return _set_error("WebGPU context is not ready yet");
    \\    }
    \\    try {
    \\      const base = Number(desc_ptr);
    \\      const shader_h = _read_i64(base + 0);
    \\      const shader = _object(shader_h);
    \\      if (!shader) {
    \\        _write_i64(out_pipeline_ptr, 0n);
    \\        return _set_error("invalid shader handle");
    \\      }
    \\      const vsEntry = _read_str(_read_i64(base + 8), _read_i64(base + 16));
    \\      const fsEntry = _read_str(_read_i64(base + 24), _read_i64(base + 32));
    \\      const vertexStride = _read_i64(base + 40);
    \\      const attrsPtr = Number(_read_i64(base + 48));
    \\      const attrsLen = Number(_read_i64(base + 56));
    \\      const attrs = [];
    \\      for (let i = 0; i < attrsLen; i++) {
    \\        const attr = attrsPtr + i * 24;
    \\        attrs.push({ shaderLocation: _read_i32(attr + 0), offset: Number(_read_i64(attr + 8)), format: _vertex_format(_read_i32(attr + 16)) });
    \\      }
    \\      const pipelineObj = _create_render_pipeline(ctx, shader, vsEntry, fsEntry, vertexStride, attrs, _read_i32(base + 64), _read_i32(base + 68), _read_i32(base + 72), _read_i32(base + 76), _read_i32(base + 80), _read_i32(base + 84), _read_i32(base + 88));
    \\      _write_i64(out_pipeline_ptr, _handle(pipelineObj));
    \\      return 0;
    \\    } catch (err) {
    \\      _write_i64(out_pipeline_ptr, 0n);
    \\      return _set_error(err && err.message ? err.message : err);
    \\    }
    \\  },
    \\
    \\  sa_wgpu_create_cube_pipeline(ctx_h, shader_h, vs_entry_ptr, vs_entry_len, fs_entry_ptr, fs_entry_len, out_pipeline_ptr) {
    \\    _require_ready();
    \\    const ctx = _ctx(ctx_h);
    \\    if (!ctx.ready) {
    \\      _write_i64(out_pipeline_ptr, 0n);
    \\      return _set_error("WebGPU context is not ready yet");
    \\    }
    \\    const shader = _object(shader_h);
    \\    if (!shader) {
    \\      _write_i64(out_pipeline_ptr, 0n);
    \\      return _set_error("invalid shader handle");
    \\    }
    \\    const vsEntry = _read_str(vs_entry_ptr, vs_entry_len);
    \\    const fsEntry = _read_str(fs_entry_ptr, fs_entry_len);
    \\    const attrs = [
    \\      { shaderLocation: 0, offset: 0, format: "float32x3" },
    \\      { shaderLocation: 1, offset: 12, format: "float32x3" },
    \\    ];
    \\    const pipelineObj = _create_render_pipeline(ctx, shader, vsEntry, fsEntry, 24, attrs, 0, 0, 1, 1, 0, 0, 1);
    \\    _write_i64(out_pipeline_ptr, _handle(pipelineObj));
    \\    return 0;
    \\  },
    \\
    \\  sa_wgpu_write_buffer(ctx_h, buffer_h, offset, data_ptr, data_len) {
    \\    _require_ready();
    \\    const ctx = _ctx(ctx_h);
    \\    if (!ctx.ready) return 0;
    \\    const buffer = _object(buffer_h);
    \\    if (!buffer) return 0;
    \\    ctx.device.queue.writeBuffer(buffer, Number(offset), _bytes(data_ptr, data_len));
    \\    return 0;
    \\  },
    \\
    \\  sa_wgpu_write_buffer_frame(ctx_h, buffer_h, offset, frames_ptr, frame_len, frame_idx) {
    \\    _require_ready();
    \\    const ctx = _ctx(ctx_h);
    \\    if (!ctx.ready) return 0;
    \\    const buffer = _object(buffer_h);
    \\    if (!buffer) return 0;
    \\    const len = Number(frame_len);
    \\    const srcOffset = Number(frames_ptr) + Number(frame_idx) * len;
    \\    ctx.device.queue.writeBuffer(buffer, Number(offset), new Uint8Array(_mem.buffer, srcOffset, len));
    \\    return 0;
    \\  },
    \\
    \\  sa_wgpu_submit_indexed_draw(ctx_h, desc_ptr) {
    \\    _require_ready();
    \\    const ctx = _ctx(ctx_h);
    \\    if (!ctx.ready) return 0;
    \\    try {
    \\      const base = Number(desc_ptr);
    \\      const indexFormat = _index_format(_read_i32(base + 32));
    \\      _submit_draw(ctx, {
    \\        pipeline_h: _read_i64(base + 0),
    \\        vertex_h: _read_i64(base + 8),
    \\        index_h: _read_i64(base + 16),
    \\        uniform_h: _read_i64(base + 24),
    \\        indexFormat,
    \\        indexCount: _read_i64(base + 40),
    \\        vertexCount: _read_i64(base + 48),
    \\        loadOp: _load_op(_read_i32(base + 56)),
    \\        storeOp: _store_op(_read_i32(base + 60)),
    \\        clearValue: { r: _milli(base + 64), g: _milli(base + 68), b: _milli(base + 72), a: _milli(base + 76) },
    \\        depthLoadOp: _load_op(_read_i32(base + 80)),
    \\        depthStoreOp: _store_op(_read_i32(base + 84)),
    \\        depthClearValue: _milli(base + 88),
    \\      });
    \\      return 0;
    \\    } catch (err) {
    \\      return _set_error(err && err.message ? err.message : err);
    \\    }
    \\  },
    \\
    \\  sa_wgpu_submit_cube_frame(ctx_h, pipeline_h, vertex_h, index_h, uniform_h, index_count) {
    \\    _require_ready();
    \\    const ctx = _ctx(ctx_h);
    \\    if (!ctx.ready) return 0;
    \\    try {
    \\      _submit_draw(ctx, {
    \\        pipeline_h,
    \\        vertex_h,
    \\        index_h,
    \\        uniform_h,
    \\        indexFormat: "uint16",
    \\        indexCount: index_count,
    \\        vertexCount: 0n,
    \\        loadOp: "clear",
    \\        storeOp: "store",
    \\        clearValue: { r: 0.02, g: 0.025, b: 0.03, a: 1 },
    \\        depthLoadOp: "clear",
    \\        depthStoreOp: "store",
    \\        depthClearValue: 1.0,
    \\      });
    \\      return 0;
    \\    } catch (err) {
    \\      return _set_error(err && err.message ? err.message : err);
    \\    }
    \\  },
    \\
    \\  sa_wgpu_request_frame(ctx_h, handler_ptr, handler_len, sax_ctx) {
    \\    _require_ready();
    \\    const ctx_key = Number(ctx_h);
    \\    if (ctx_key === 0) return _set_error("cannot request WebGPU frame without a context handle");
    \\    const ctx = _contexts.get(ctx_key);
    \\    if (!ctx) return _set_error("invalid WebGPU context handle");
    \\    const handler = _read_str(handler_ptr, handler_len);
    \\    const loop = () => {
    \\      const latest = _contexts.get(ctx_key);
    \\      if (!latest) return;
    \\      if (_instance && _instance.exports[handler]) _instance.exports[handler](sax_ctx);
    \\      latest.raf = requestAnimationFrame(loop);
    \\    };
    \\    if (ctx.raf) cancelAnimationFrame(ctx.raf);
    \\    ctx.raf = requestAnimationFrame(loop);
    \\    return 0;
    \\  },
    \\
    \\  sa_wgpu_cancel_frame(ctx_h) {
    \\    const ctx_key = Number(ctx_h);
    \\    if (ctx_key === 0) return 0;
    \\    const ctx = _contexts.get(ctx_key);
    \\    if (!ctx) return 0;
    \\    if (ctx.raf) cancelAnimationFrame(ctx.raf);
    \\    ctx.raf = 0;
    \\    return 0;
    \\  },
    \\
    \\  sa_wgpu_last_error(buf_ptr, buf_len) {
    \\    _require_ready();
    \\    return _write_str(buf_ptr, buf_len, _lastError);
    \\  },
    \\};
    \\
    \\if (typeof window !== "undefined") {
    \\  window.sax_wgpu_airlock = sax_wgpu_airlock;
    \\  window.sax_wgpu_bind_wasm = sax_wgpu_bind_wasm;
    \\}
    \\
;

test "wgpu airlock exposes broker-only imports" {
    var generator = AirlockGenerator.init(std.testing.allocator);
    const js = try generator.generate();
    defer js.deinit();

    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "export const sax_wgpu_airlock"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "sa_wgpu_create_render_pipeline"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "sa_wgpu_submit_cube_frame"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "sa_wgpu_submit_indexed_draw"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "sa_wgpu_write_buffer_frame"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "typeof navigator === \"undefined\" || !navigator.gpu"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "cannot request WebGPU frame without a context handle"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "if (ctx_key === 0) return 0;"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "createRenderPipeline"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "createCommandEncoder"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "queue.submit"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "depth24plus"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "depthStencilAttachment"));
    try std.testing.expect(std.mem.containsAtLeast(u8, js.items, 1, "GPUTextureUsage.RENDER_ATTACHMENT"));
    try std.testing.expect(std.mem.indexOf(u8, js.items, "cube_vertices") == null);
    try std.testing.expect(std.mem.indexOf(u8, js.items, "struct Uniforms") == null);
}
