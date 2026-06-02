const std = @import("std");
const plugin_api = @import("plugin_api");
const wgpu_airlock_gen = @import("wgpu_airlock_gen.zig");

const skills = [_]plugin_api.SkillSection{
    .{
        .name = "wgpu",
        .summary = "Browser WebGPU sidecar for SAX",
        .items = &.{
            "wgpu airlock [--out <path>]",
            "wgpu check <file.sax>",
            "wgpu new <dir>",
            "ships browser-only WebGPU broker imports for SAX WASM",
        },
    },
    .{
        .name = "sax.wgpu",
        .summary = "SAX integration contract for SA-produced WebGPU scenes",
        .items = &.{
            "requires the sax plugin at build time",
            "keeps WGSL, geometry, indices, and uniforms in SA/WASM memory",
            "installs zig-out/share/wgpu_airlock.js for SAX to copy",
        },
    },
};

const rotating_cube_sax = @embedFile("rotating_cube.sax");

fn cArgvToSlice(argv: [*]const [*:0]const u8, argv_len: usize, allocator: std.mem.Allocator) ![]const []const u8 {
    const slice = argv[0..argv_len];
    var out = try allocator.alloc([]const u8, slice.len);
    errdefer allocator.free(out);
    for (slice, 0..) |arg, idx| out[idx] = std.mem.span(arg);
    return out;
}

fn ensureParentDir(path: []const u8) !void {
    if (std.fs.path.dirname(path)) |dir| {
        if (dir.len != 0) try std.fs.cwd().makePath(dir);
    }
}

fn writeAllFile(path: []const u8, bytes: []const u8) !void {
    try ensureParentDir(path);
    var file = try std.fs.cwd().createFile(path, .{ .truncate = true });
    defer file.close();
    try file.writeAll(bytes);
}

fn readSource(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    return std.fs.cwd().readFileAlloc(allocator, path, 16 * 1024 * 1024) catch |err| switch (err) {
        error.FileNotFound => return error.FileNotFound,
        error.AccessDenied => return error.AccessDenied,
        error.IsDir => return error.NotDir,
        else => return error.InvalidPath,
    };
}

fn sourceLooksLikeWgpuSax(source: []const u8) bool {
    return std.mem.containsAtLeast(u8, source, 1, "renderer=\"wgpu\"") or
        std.mem.containsAtLeast(u8, source, 1, "sa_wgpu_") or
        std.mem.containsAtLeast(u8, source, 1, "WGPU_CUBE_");
}

fn sourceKeepsKernelOutOfJs(source: []const u8) bool {
    return std.mem.indexOf(u8, source, "<script") == null and
        std.mem.indexOf(u8, source, "navigator.gpu") == null and
        std.mem.indexOf(u8, source, "createShaderModule") == null;
}

fn executeAirlock(ctx: *const plugin_api.Context, argv: []const []const u8, stdout: std.io.AnyWriter) !u8 {
    var out_path: ?[]const u8 = null;
    var i: usize = 3;
    while (i < argv.len) : (i += 1) {
        if (std.mem.eql(u8, argv[i], "--out") or std.mem.eql(u8, argv[i], "-o")) {
            if (i + 1 >= argv.len) return error.MissingSourcePath;
            if (out_path != null) return error.UnexpectedArgument;
            out_path = argv[i + 1];
            i += 1;
            continue;
        }
        return error.UnexpectedArgument;
    }

    var generator = wgpu_airlock_gen.AirlockGenerator.init(ctx.allocator);
    const js = try generator.generate();
    defer js.deinit();

    if (out_path) |path| {
        try writeAllFile(path, js.items);
        try stdout.print("WGPU airlock written: {s}\n", .{path});
    } else {
        try stdout.writeAll(js.items);
    }
    return 0;
}

fn executeCheck(ctx: *const plugin_api.Context, sax_file: []const u8, stdout: std.io.AnyWriter, stderr: std.io.AnyWriter) !u8 {
    const source = try readSource(ctx.allocator, sax_file);
    defer ctx.allocator.free(source);

    if (!sourceLooksLikeWgpuSax(source)) {
        try stderr.print("error[SA-WGPU-CHECK]: {s} does not declare a WGPU SAX surface\n", .{sax_file});
        return 1;
    }
    if (!sourceKeepsKernelOutOfJs(source)) {
        try stderr.print("error[SA-WGPU-CHECK]: {s} embeds browser WebGPU or script code; keep kernel material in SA/WASM\n", .{sax_file});
        return 1;
    }

    try stdout.print("WGPU SAX check passed: {s}\n", .{sax_file});
    return 0;
}

fn executeNew(ctx: *const plugin_api.Context, project_name: []const u8, stdout: std.io.AnyWriter) !u8 {
    try std.fs.cwd().makePath(project_name);

    const sax_path = try std.fs.path.join(ctx.allocator, &.{ project_name, "app.sax" });
    defer ctx.allocator.free(sax_path);
    try writeAllFile(sax_path, rotating_cube_sax);

    const readme_path = try std.fs.path.join(ctx.allocator, &.{ project_name, "README.md" });
    defer ctx.allocator.free(readme_path);
    const readme = try std.fmt.allocPrint(ctx.allocator,
        \\# {s}
        \\
        \\SAX + WGPU rotating cube scaffold.
        \\
        \\Build with both plugins on `SA_PLUGINS_PATH`:
        \\
        \\```bash
        \\SA_PLUGINS_PATH=/home/vscode/projects/sa_plugins/sa_plugin_sax/zig-out/lib/libsax.so:/home/vscode/projects/sa_plugins/sa_plugin_wgpu/zig-out/lib/libwgpu.so \\
        \\  sa sax build app.sax --out-dir dist
        \\```
        \\
    , .{project_name});
    defer ctx.allocator.free(readme);
    try writeAllFile(readme_path, readme);

    const package_path = try std.fs.path.join(ctx.allocator, &.{ project_name, "package.json" });
    defer ctx.allocator.free(package_path);
    const package_json = try std.fmt.allocPrint(ctx.allocator,
        \\{{
        \\  "name": "{s}",
        \\  "private": true,
        \\  "type": "module",
        \\  "scripts": {{
        \\    "check": "sa wgpu check app.sax",
        \\    "build": "sa sax build app.sax --out-dir dist"
        \\  }}
        \\}}
        \\
    , .{project_name});
    defer ctx.allocator.free(package_json);
    try writeAllFile(package_path, package_json);

    try stdout.print("WGPU SAX project created: {s}\n", .{project_name});
    try stdout.print("  app.sax: {s}\n", .{sax_path});
    try stdout.print("  README.md: {s}\n", .{readme_path});
    try stdout.print("  package.json: {s}\n", .{package_path});
    return 0;
}

fn runWgpuCommandImpl(ctx: *const plugin_api.Context, argv: []const []const u8, stdout: std.io.AnyWriter, stderr: std.io.AnyWriter) anyerror!?u8 {
    if (argv.len < 2) return null;
    if (!std.mem.eql(u8, argv[1], "wgpu")) return null;
    if (argv.len < 3) return error.MissingSourcePath;

    const sub = argv[2];
    if (std.mem.eql(u8, sub, "airlock")) return try executeAirlock(ctx, argv, stdout);
    if (std.mem.eql(u8, sub, "check")) {
        if (argv.len != 4) return if (argv.len < 4) error.MissingSourcePath else error.UnexpectedArgument;
        return try executeCheck(ctx, argv[3], stdout, stderr);
    }
    if (std.mem.eql(u8, sub, "new")) {
        if (argv.len != 4) return if (argv.len < 4) error.MissingSourcePath else error.UnexpectedArgument;
        return try executeNew(ctx, argv[3], stdout);
    }
    return error.UnknownCommand;
}

fn isWgpuCliError(err: anyerror) bool {
    return switch (err) {
        error.MissingSourcePath,
        error.UnexpectedArgument,
        error.UnknownCommand,
        error.InvalidPath,
        error.FileNotFound,
        error.NotDir,
        error.AccessDenied,
        => true,
        else => false,
    };
}

fn wgpuCliExitCode(err: anyerror) u8 {
    return switch (err) {
        error.UnknownCommand,
        error.MissingSourcePath,
        error.UnexpectedArgument,
        => 2,
        error.InvalidPath,
        error.FileNotFound,
        error.NotDir,
        error.AccessDenied,
        => 3,
        else => 1,
    };
}

fn writeWgpuCliError(writer: std.io.AnyWriter, argv: []const []const u8, err: anyerror) !void {
    _ = argv;
    const message = switch (err) {
        error.MissingSourcePath => "missing required WGPU operand",
        error.UnexpectedArgument => "unexpected WGPU argument",
        error.UnknownCommand => "unknown WGPU subcommand",
        error.InvalidPath => "invalid WGPU path",
        error.FileNotFound => "WGPU file or directory not found",
        error.NotDir => "WGPU path is not a directory",
        error.AccessDenied => "WGPU path access denied",
        else => @errorName(err),
    };
    try writer.print("error[SA-WGPU-CLI]: {s}\n  help: sa wgpu <airlock|check|new> ...\n", .{message});
}

fn anyWriterFromHostStream(stream: plugin_api.HostStream, storage: *plugin_api.HostStream) std.io.AnyWriter {
    storage.* = stream;
    return .{ .context = storage, .writeFn = struct {
        fn write(ctx: *const anyopaque, bytes: []const u8) anyerror!usize {
            const hs = @as(*const plugin_api.HostStream, @ptrCast(@alignCast(ctx)));
            const write_all = hs.write_all orelse return error.WriteFailed;
            if (write_all(hs.ctx, bytes.ptr, bytes.len) != @intFromEnum(plugin_api.AbiStatus.ok)) return error.WriteFailed;
            return bytes.len;
        }
    }.write };
}

fn runWgpuCommandAbi(ctx: *const plugin_api.Context, argv: [*]const [*:0]const u8, argv_len: usize, stdout: plugin_api.HostStream, stderr: plugin_api.HostStream, out_code: *u8) callconv(.c) u32 {
    out_code.* = 0;
    const args = cArgvToSlice(argv, argv_len, ctx.allocator) catch return @intFromEnum(plugin_api.AbiStatus.failed);
    defer ctx.allocator.free(args);

    var stdout_storage = stdout;
    var stderr_storage = stderr;
    const stdout_writer = anyWriterFromHostStream(stdout, &stdout_storage);
    const stderr_writer = anyWriterFromHostStream(stderr, &stderr_storage);

    const result = runWgpuCommandImpl(ctx, args, stdout_writer, stderr_writer) catch |err| {
        if (!isWgpuCliError(err)) return @intFromEnum(plugin_api.AbiStatus.failed);
        writeWgpuCliError(stderr_writer, args, err) catch return @intFromEnum(plugin_api.AbiStatus.failed);
        out_code.* = wgpuCliExitCode(err);
        return @intFromEnum(plugin_api.AbiStatus.ok);
    };
    if (result) |code| {
        out_code.* = code;
        return @intFromEnum(plugin_api.AbiStatus.ok);
    }
    return @intFromEnum(plugin_api.AbiStatus.unknown_command);
}

const descriptor = plugin_api.PluginDescriptor{
    .abi_version = plugin_api.abi_version,
    .descriptor_size = @as(u32, @intCast(@sizeOf(plugin_api.PluginDescriptor))),
    .name = "wgpu",
    .init = null,
    .prebuild = null,
    .postbuild = null,
    .handle_command = runWgpuCommandAbi,
    .skills_ptr = skills[0..].ptr,
    .skills_len = skills.len,
};

pub export const saasm_plugin_descriptor_v1: plugin_api.PluginDescriptor = descriptor;
pub export fn saasm_plugin_descriptor_v1_fn(out: *plugin_api.PluginDescriptor) callconv(.c) void {
    out.* = descriptor;
}

const CaptureStream = struct {
    buffer: *std.ArrayList(u8),
};

fn captureWriteAll(ctx: ?*anyopaque, bytes: [*]const u8, len: usize) callconv(.c) u32 {
    const stream = @as(*CaptureStream, @ptrCast(@alignCast(ctx orelse return @intFromEnum(plugin_api.AbiStatus.failed))));
    stream.buffer.appendSlice(bytes[0..len]) catch return @intFromEnum(plugin_api.AbiStatus.failed);
    return @intFromEnum(plugin_api.AbiStatus.ok);
}

fn captureHostStream(ctx: *CaptureStream) plugin_api.HostStream {
    return .{ .ctx = ctx, .write_all = captureWriteAll };
}

fn dupeZArgs(allocator: std.mem.Allocator, argv: []const []const u8) ![][*:0]const u8 {
    var out = try allocator.alloc([*:0]const u8, argv.len);
    errdefer allocator.free(out);
    var copied: usize = 0;
    errdefer {
        for (out[0..copied]) |arg| allocator.free(std.mem.sliceTo(arg, 0));
    }
    for (argv, 0..) |arg, idx| {
        out[idx] = try allocator.dupeZ(u8, arg);
        copied += 1;
    }
    return out;
}

fn freeZArgs(allocator: std.mem.Allocator, argv: [][*:0]const u8) void {
    for (argv) |arg| allocator.free(std.mem.sliceTo(arg, 0));
    allocator.free(argv);
}

fn invokeForTest(argv: []const []const u8, stdout_buffer: *std.ArrayList(u8), stderr_buffer: *std.ArrayList(u8), allocator: std.mem.Allocator) !u8 {
    var ctx = plugin_api.Context{ .allocator = allocator };
    var stdout_ctx = CaptureStream{ .buffer = stdout_buffer };
    var stderr_ctx = CaptureStream{ .buffer = stderr_buffer };
    const c_argv = try dupeZArgs(allocator, argv);
    defer freeZArgs(allocator, c_argv);
    var out_code: u8 = 255;
    const status = runWgpuCommandAbi(&ctx, c_argv.ptr, c_argv.len, captureHostStream(&stdout_ctx), captureHostStream(&stderr_ctx), &out_code);
    try std.testing.expectEqual(@as(u32, @intFromEnum(plugin_api.AbiStatus.ok)), status);
    return out_code;
}

test "wgpu plugin exports descriptor and skills" {
    try std.testing.expectEqualStrings("wgpu", std.mem.span(descriptor.name));
    try std.testing.expectEqual(@as(usize, 2), descriptor.skills_len);
}

test "wgpu airlock command emits broker source" {
    var stdout_buf = std.ArrayList(u8).init(std.testing.allocator);
    defer stdout_buf.deinit();
    var stderr_buf = std.ArrayList(u8).init(std.testing.allocator);
    defer stderr_buf.deinit();

    const code = try invokeForTest(&.{ "sa", "wgpu", "airlock" }, &stdout_buf, &stderr_buf, std.testing.allocator);
    try std.testing.expectEqual(@as(u8, 0), code);
    try std.testing.expect(std.mem.containsAtLeast(u8, stdout_buf.items, 1, "export const sax_wgpu_airlock"));
    try std.testing.expectEqual(@as(usize, 0), stderr_buf.items.len);
}

test "wgpu check accepts rotating cube demo shape" {
    var original_cwd = try std.fs.cwd().openDir(".", .{});
    defer original_cwd.close();
    var tmp = std.testing.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try tmp.dir.setAsCwd();
    defer original_cwd.setAsCwd() catch {};

    try writeAllFile("cube.sax", rotating_cube_sax);
    var stdout_buf = std.ArrayList(u8).init(std.testing.allocator);
    defer stdout_buf.deinit();
    var stderr_buf = std.ArrayList(u8).init(std.testing.allocator);
    defer stderr_buf.deinit();

    const code = try invokeForTest(&.{ "sa", "wgpu", "check", "cube.sax" }, &stdout_buf, &stderr_buf, std.testing.allocator);
    try std.testing.expectEqual(@as(u8, 0), code);
    try std.testing.expect(std.mem.containsAtLeast(u8, stdout_buf.items, 1, "WGPU SAX check passed"));
    try std.testing.expectEqual(@as(usize, 0), stderr_buf.items.len);
}

test "wgpu new writes a sax scaffold" {
    var original_cwd = try std.fs.cwd().openDir(".", .{});
    defer original_cwd.close();
    var tmp = std.testing.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try tmp.dir.setAsCwd();
    defer original_cwd.setAsCwd() catch {};

    var stdout_buf = std.ArrayList(u8).init(std.testing.allocator);
    defer stdout_buf.deinit();
    var stderr_buf = std.ArrayList(u8).init(std.testing.allocator);
    defer stderr_buf.deinit();

    const code = try invokeForTest(&.{ "sa", "wgpu", "new", "demo" }, &stdout_buf, &stderr_buf, std.testing.allocator);
    try std.testing.expectEqual(@as(u8, 0), code);
    try std.testing.expectEqual(@as(usize, 0), stderr_buf.items.len);

    const app = try std.fs.cwd().readFileAlloc(std.testing.allocator, "demo/app.sax", 1024 * 1024);
    defer std.testing.allocator.free(app);
    try std.testing.expect(std.mem.containsAtLeast(u8, app, 1, "renderer=\"wgpu\""));
    try std.testing.expect(std.mem.containsAtLeast(u8, app, 1, "sa_wgpu_submit_cube_frame"));
}
