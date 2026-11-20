// src/main_gui.zig
// standard imports
const std = @import("std");

// external imports
const c = @import("c_glfw");

// project imports
const core_builder = @import("core/topo/builder.zig");
const core_tesselator = @import("core/mesh/tessellator.zig");

const core_topo = @import("core/topo/topology.zig");
const glfuncs = @import("render/glfuncs.zig").GlFuncs;

const vertex_shader_src: [*c]const c.GLchar =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\uniform mat4 uMvp;
    \\out vec3 vLocalPos;
    \\void main() {
    \\    vLocalPos = aPos;
    \\    gl_Position = uMvp * vec4(aPos, 1.0);
    \\}
;

const fragment_shader_src: [*c]const c.GLchar =
    \\#version 330 core
    \\in vec3 vLocalPos;
    \\out vec4 FragColor;
    \\void main() {
    \\    // Gradiente sutil baseado na posição local para diferenciar faces/arestas
    \\    vec3 col = clamp(vLocalPos * 0.08 + vec3(0.25, 0.45, 0.70), 0.0, 1.0);
    \\    FragColor = vec4(col, 1.0);
    \\}
;

fn mat4Identity() [16]f32 {
    return .{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    };
}

fn mat4Mul(a: [16]f32, b: [16]f32) [16]f32 {
    var res: [16]f32 = undefined;
    for (0..4) |col| {
        for (0..4) |row| {
            res[col * 4 + row] =
                a[0 * 4 + row] * b[col * 4 + 0] +
                a[1 * 4 + row] * b[col * 4 + 1] +
                a[2 * 4 + row] * b[col * 4 + 2] +
                a[3 * 4 + row] * b[col * 4 + 3];
        }
    }
    return res;
}

fn mat4Translate(tx: f32, ty: f32, tz: f32) [16]f32 {
    var m = mat4Identity();
    m[12] = tx;
    m[13] = ty;
    m[14] = tz;
    return m;
}

fn mat4Scale(sx: f32, sy: f32, sz: f32) [16]f32 {
    var m = mat4Identity();
    m[0] = sx;
    m[5] = sy;
    m[10] = sz;
    return m;
}

fn mat4RotateX(angle_red: f32) [16]f32 {
    const co = @cos(angle_red);
    const si = @sin(angle_red);
    var m = mat4Identity();
    m[5] = co;
    m[6] = si;
    m[9] = -si;
    m[10] = co;
    return m;
}

fn mat4RotateZ(angle_rad: f32) [16]f32 {
    const co = @cos(angle_rad);
    const si = @sin(angle_rad);
    var m = mat4Identity();
    m[0] = co;
    m[1] = si;
    m[4] = -si;
    m[5] = co;
    return m;
}

fn mat4Perspective(fov_rad: f32, aspect: f32, near: f32, far: f32) [16]f32 {
    const f = 1.0 / @tan(fov_rad * 0.5);
    const nf = 1.0 / (near - far);
    return .{
        f / aspect, 0, 0,                      0,
        0,          f, 0,                      0,
        0,          0, (far + near) * nf,     -1,
        0,          0, (2.0 * far * near) * nf, 0,
    };
}

fn compileShader(gl: anytype, shader_type: c.GLenum, src: [*c]const c.GLchar) !c.GLuint {
    const shader = gl.glCreateShader(shader_type);
    if (shader == 0) return error.ShaderCreateFailed;

    var ok: c.GLint = 0;
    gl.glShaderSource(shader, 1, &src, null);
    gl.glCompileShader(shader);
    gl.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &ok);

    if (ok == c.GL_FALSE) {
        var log_buf: [512]u8 = undefined;
        var log_len: c.GLsizei = 0;
        gl.glGetShaderInfoLog(shader, log_buf.len, &log_len, &log_buf);
        std.debug.print("Erro de compilação do shader:\n{s}\n", .{log_buf[0..@intCast(log_len)]});
        return error.ShaderCompileFailed;
    }

    return shader;
}

pub fn main() !void {
    var sfa: std.heap.SafeAllocator = .init(std.heap.smp_allocator, .{});
    const allocator = sfa.allocator();
    defer _ = sfa.deinit();

    // Gerando sólido BRep e tesselando em uma malha de triangulos
    var body = try core_builder.BRepBuilder.createBox(allocator, 10.0, 10.0, 10.0);
    defer body.deinit();

    var mesh = try core_tesselator.Tessellator.tessellateBody(&body, allocator);
    defer mesh.deinit();

    std.debug.print("Malha pronta: {} vertices, {} indices\n", .{
        mesh.vertices.items.len / 3,
        mesh.indices.items.len,
    });
    // --

    // Inicializando GLFW e OpenGL
    if (c.glfwInit() == c.GLFW_FALSE) return error.GlfwInitFailed;
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
    
    const gl  = try glfuncs.load();

    // Compila e linka o programa de shader
    const vs = try compileShader(gl, c.GL_VERTEX_SHADER, vertex_shader_src);
    const fs = try compileShader(gl, c.GL_FRAGMENT_SHADER, fragment_shader_src);
    const program = gl.glCreateProgram();
    gl.glAttachShader(program, vs);
    gl.glAttachShader(program, fs);
    gl.glLinkProgram(program);

    var linked: c.GLint = 0;
    gl.glGetProgramiv(program, c.GL_LINK_STATUS, &linked);
    if (linked == c.GL_FALSE) return error.ProgramLinkFailed;

    const u_mvp_loc = gl.glGetUniformLocation(program, "uMvp");
    // -- 

    // Subir vertices e indices da malha para VAO / VBO / EBO
    var vao: c.GLuint = 0;
    var vbo: c.GLuint = 0;
    var ebo: c.GLuint = 0;

    gl.glGenVertexArrays(1, &vao);
    gl.glGenBuffers(1, &vbo);
    gl.glGenBuffers(1, &ebo);
    gl.glBindVertexArray(vao);

    gl.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    gl.glBufferData(
        c.GL_ARRAY_BUFFER,
        @intCast(mesh.vertices.items.len * @sizeOf(u32)),
        mesh.vertices.items.ptr,
        c.GL_STATIC_DRAW,
    );

    gl.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
    gl.glBufferData(
        c.GL_ELEMENT_ARRAY_BUFFER,
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
        var fb_w: c_int = 0;
        var fb_h: c_int = 0;
        
        c.glfwGetFramebufferSize(window, &fb_w, &fb_h);
        const w: f32 = if (fb_w > 0) @floatFromInt(fb_w) else 1.0;
        const h: f32 = if (fb_h > 0) @floatFromInt(fb_h) else 1.0;

        c.glViewport(0, 0, fb_w, fb_h);
        c.glClearColor(0.14, 0.15, 0.18, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        // Centraliza o cubo na origem
        const center_box = mat4Translate(-5.0, -5.0, -5.0);
        const rot_x = mat4RotateX(-0.6);
        const rot_z = mat4RotateZ(0.6);
        const model = mat4Mul(rot_x, mat4Mul(rot_z, center_box));

        const view = mat4Translate(0.0, 0.0, -28.0);
        const proj = mat4Perspective(std.math.degreesToRadians(45.0), w / h, 0.1, 200.0);
        const mvp = mat4Mul(proj, mat4Mul(view, model));

        gl.glUseProgram(program);
        if (u_mvp_loc >= 0) {
            gl.glUniformMatrix4fv(u_mvp_loc, 1, c.GL_FALSE, &mvp);
        }

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