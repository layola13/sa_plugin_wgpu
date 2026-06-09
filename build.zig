const std = @import("std");
const wgpu_airlock_gen = @import("src/wgpu_airlock_gen.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const sa_repo_root = b.option([]const u8, "sa-repo-root", "SA repository root used to resolve the host binary.") orelse "/home/vscode/projects/sci";
    const sa_bin = b.option([]const u8, "sa-bin", "Path to the SA host binary used for SAX/WGPU integration tests.") orelse b.pathJoin(&.{ sa_repo_root, "zig-out/bin/sa" });
    const sax_lib = b.option([]const u8, "sax-lib", "Path to the SAX plugin dynamic library used for integration tests.") orelse "/home/vscode/projects/sa_plugins/sa_plugin_sax/zig-out/lib/libsax.so";

    const plugin_api = b.createModule(.{
        .root_source_file = b.path("src/plugin_api.zig"),
        .target = target,
        .optimize = optimize,
    });

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/plugin.zig"),
        .target = target,
        .optimize = optimize,
    });
    root_module.addImport("plugin_api", plugin_api);

    const lib = b.addLibrary(.{
        .name = "wgpu",
        .root_module = root_module,
        .linkage = .dynamic,
    });
    b.installArtifact(lib);

    const write_files = b.addWriteFiles();
    const airlock_file = write_files.add("wgpu_airlock.js", wgpu_airlock_gen.source);
    const install_airlock = b.addInstallFile(airlock_file, "share/wgpu_airlock.js");
    b.getInstallStep().dependOn(&install_airlock.step);
    b.installFile("wgpu.sai", "share/wgpu.sai");
    b.installFile("wgpu.sal", "share/wgpu.sal");
    b.installFile("demos/rotating_cube.sax", "share/demos/rotating_cube.sax");

    const tests = b.addTest(.{
        .root_module = root_module,
    });
    const run_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run WGPU plugin tests");
    test_step.dependOn(&run_tests.step);
    test_step.dependOn(b.getInstallStep());

    const sa_layout_test = b.addSystemCommand(&.{ sa_bin, "test", "tests/wgpu_layout_test.sa" });
    sa_layout_test.addFileInput(b.path("tests/wgpu_layout_test.sa"));
    sa_layout_test.addFileInput(b.path("wgpu.sal"));
    sa_layout_test.addFileInput(lib.getEmittedBin());
    sa_layout_test.step.dependOn(b.getInstallStep());
    test_step.dependOn(&sa_layout_test.step);

    const verify_airlock = b.addSystemCommand(&.{ "node", "tools/verify_wgpu_airlock.mjs" });
    verify_airlock.addFileInput(b.path("tools/verify_wgpu_airlock.mjs"));
    verify_airlock.addFileArg(airlock_file);
    test_step.dependOn(&verify_airlock.step);

    const installed_lib = b.getInstallPath(.lib, "libwgpu.so");
    const plugin_path = b.fmt("{s}:{s}", .{ sax_lib, installed_lib });
    const demo_input = b.path("demos/rotating_cube.sax");
    const sax_lib_input: std.Build.LazyPath = .{ .cwd_relative = sax_lib };

    const demo_check = b.addSystemCommand(&.{ sa_bin, "wgpu", "check", "demos/rotating_cube.sax" });
    demo_check.setEnvironmentVariable("SA_PLUGINS_PATH", plugin_path);
    demo_check.addFileInput(demo_input);
    demo_check.addFileInput(sax_lib_input);
    demo_check.addFileInput(lib.getEmittedBin());
    demo_check.step.dependOn(b.getInstallStep());
    test_step.dependOn(&demo_check.step);

    const demo_build = b.addSystemCommand(&.{ sa_bin, "sax", "build", "demos/rotating_cube.sax", "--out-dir" });
    const demo_output = demo_build.addOutputDirectoryArg("wgpu-rotating-cube");
    demo_build.setEnvironmentVariable("SA_PLUGINS_PATH", plugin_path);
    demo_build.addFileInput(demo_input);
    demo_build.addFileInput(sax_lib_input);
    demo_build.addFileInput(lib.getEmittedBin());
    demo_build.step.dependOn(b.getInstallStep());
    test_step.dependOn(&demo_build.step);

    const verify_dist = b.addSystemCommand(&.{ "node", "tools/verify_wgpu_sax_dist.mjs" });
    verify_dist.addFileInput(b.path("tools/verify_wgpu_sax_dist.mjs"));
    verify_dist.addDirectoryArg(demo_output);
    test_step.dependOn(&verify_dist.step);

    const cube_browser_step = b.step("cube-browser", "Verify the rotating WGPU cube in a browser.");
    const verify_cube_browser = b.addSystemCommand(&.{ "node", "tools/verify_wgpu_cube_browser.mjs" });
    verify_cube_browser.addFileInput(b.path("tools/verify_wgpu_cube_browser.mjs"));
    verify_cube_browser.addDirectoryArg(demo_output);
    verify_cube_browser.step.dependOn(&demo_build.step);
    cube_browser_step.dependOn(&verify_cube_browser.step);

    const smoke_home = b.option([]const u8, "smoke-home", "SA_PLUGINS_HOME used by the install-smoke step.") orelse b.pathJoin(&.{ ".zig-cache", "wgpu-install-smoke-home" });
    const install_smoke_step = b.step("install-smoke", "Install WGPU and SAX into an isolated plugin home and verify installed assets.");
    const install_smoke = b.addSystemCommand(&.{ sa_bin, "plugin", "install", "--dev", "." });
    install_smoke.setEnvironmentVariable("SA_PLUGINS_HOME", smoke_home);
    install_smoke.setEnvironmentVariable("SA_PLUGIN_DEV", "1");
    install_smoke.step.dependOn(b.getInstallStep());
    install_smoke_step.dependOn(&install_smoke.step);

    const verify_install = b.addSystemCommand(&.{ "node", "tools/verify_wgpu_install.mjs", smoke_home, sa_bin });
    verify_install.addFileInput(b.path("tools/verify_wgpu_install.mjs"));
    verify_install.step.dependOn(&install_smoke.step);
    install_smoke_step.dependOn(&verify_install.step);
}
