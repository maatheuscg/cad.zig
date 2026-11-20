const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Módulo traduzido a partir de src/render/gl_glfw.h
    const c_glfw_mod = b.createModule(.{
        .root_source_file = b.path("src/render/c_glfw.zig"),
        .target = target,
        .optimize = optimize,
    });

    const gui_mod = b.createModule(.{
        .root_source_file = b.path("src/main_gui.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{
            .{ .name = "c_glfw", .module = c_glfw_mod },
        },
    });

    const gui_exe = b.addExecutable(.{
        .name = "cad_zig",
        .root_module = gui_mod,
    });

    gui_exe.root_module.linkSystemLibrary("glfw", .{});

    switch (builtin.target.os.tag) {
        .macos => {
            gui_exe.root_module.linkFramework("OpenGL", .{});
            gui_exe.root_module.linkFramework("Cocoa", .{});
            gui_exe.root_module.linkFramework("IOKit", .{});
            gui_exe.root_module.linkFramework("CoreVideo", .{});
        },
        .windows => {
            gui_exe.root_module.linkSystemLibrary("opengl32", .{});
            gui_exe.root_module.linkSystemLibrary("gdi32", .{});
            gui_exe.root_module.linkSystemLibrary("user32", .{});
            gui_exe.root_module.linkSystemLibrary("shell32", .{});
        },
        else => {
            // Linux/BSD based systems
            gui_exe.root_module.linkSystemLibrary("GL", .{});
        }
    }

    b.installArtifact(gui_exe);

    const run_cmd = b.addRunArtifact(gui_exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run-gui", "Run the CAD GUI");
    run_step.dependOn(&run_cmd.step);
}
