// src/main_gui.zig
// standard imports
const std = @import("std");

// external imports
const c = @import("c_glfw");

// project imports
const core_topo = @import("core/topo/topology.zig");
const core_builder = @import("core/topo/builder.zig");
const core_tesselator = @import("core/mesh/tessellator.zig");
const glfuncs = @import("render/glfuncs.zig").GlFuncs;

pub fn main() !void {
    var sfa: std.heap.SafeAllocator = .init(std.heap.smp_allocator, .{});
    const allocator = sfa.allocator();
    defer _ = sfa.deinit();
    // Gerando sólido BRep e tesselando em uma malha de triangulos
    var body = try core_builder.BRepBuilder.createBox(allocator, 10.0, 10.0, 10.0);
    defer body.deinit();

    var mesh = try core_tesselator.Tessellator.tessellatorBody(&body, allocator);
    defer mesh.deinit();

    std.debug.print("Malha pronta: {} vertices, {} indices\n", .{
        mesh.vertices.items.len,
        mesh.indices.items.len,
    });
    // --

    // Inicializando GLFW e OpenGL
    if (c.glfwInit() == c.GLFW_FALSE) {
        return error.GlfwInitFailed;
    }
    defer c.glfwTerminate();

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    if (@import("builtin").os.tag == .macos) {
        c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GLFW_TRUE);
    }

    const window = c.glfwCreateWindow(800, 600, "Zig CAD Kernel", null, null) orelse {
        return error.WindowCreationFailed;
    };
    defer c.glfwDestroyWindow(window);

    c.glfwMakeContextCurrent(window);
    c.glfwSwapInterval(1);  // V-Sync
    // --

    // Subir vertices e indices da malha para VAO / VBO / EBO
    var vao: c.GLuint = 0;
    var vbo: c.GLuint = 0;
    var ebo: c.GLuint = 0;

    const gl  = try glfuncs.load();
    gl.glGenVertexArrays(1, &vao);
    gl.glGenBuffers(1, &vbo);
    gl.glGenBuffers(1, &ebo);
    gl.glBindVertexArray(vao);

    gl.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    gl.glBufferData(
        c.GL_ARRAY_BUFFER,
        @intCast(mesh.indices.items.len * @sizeOf(u32)),
        mesh.indices.items.ptr,
        c.GL_STATIC_DRAW,
    );

    gl.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
    gl.glEnableVertexAttribArray(0);
    c.glEnable(c.GL_DEPTH_TEST);
    // --

    // Loop de renderizaçao
    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        c.glClearColor(0.14, 0.15, 0.18, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        gl.glBindVertexArray(vao);
        c.glDrawElements(
            c.GL_TRIANGLES,
            @intCast(mesh.indices.items.len),
            c.GL_UNSIGNED_INT,
            null,
        );

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
    // --
}