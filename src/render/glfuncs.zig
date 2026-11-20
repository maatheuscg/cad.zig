// src/render/glfuncs.zig
// para este arquivo buildar, voce DEVE executar no seu terminal:
// zig translate-c -lc src/render/gl_glfw.h > src/render/c_glfw.zig
//
// leia README.md

// standard imports
const std = @import("std");

// external imports
const c = @import("c_glfw");

// project imports

pub const PFNGLGENVERTEXARRAYSPROC = *const fn (n: c.GLsizei, arrays: [*c]c.GLuint) callconv(.c) void;
pub const PFNGLGENBUFFERSPROC = *const fn (n: c.GLsizei, buffers: [*c]c.GLuint) callconv(.c) void;
pub const PFNGLBINDBUFFERPROC = *const fn (target: c.GLenum, buffer: c.GLuint) callconv(.c) void;
pub const PFNGLBUFFERDATAPROC = *const fn (target: c.GLenum, size: c.GLsizeiptr, data: ?*const anyopaque, usage: c.GLenum) callconv(.c) void;
pub const PFNGLBINDVERTEXARRAYPROC = *const fn (array: c.GLuint) callconv(.c) void;
pub const PFNGLVERTEXATTRIBPOINTERPROC = *const fn (index: c.GLuint, size: c.GLint, type_: c.GLenum, normalized: c.GLboolean, stride: c.GLsizei, pointer: ?*const anyopaque) callconv(.c) void;
pub const PFNGLENABLEVERTEXATTRIBARRAYPROC = *const fn (index: c.GLuint) callconv(.c) void;
pub const PFNGLCREATESHADERPROC = *const fn (shaderType: c.GLenum) callconv(.c) c.GLuint;
pub const PFNGLSHADERSOURCEPROC = *const fn (shader: c.GLuint, count: c.GLsizei, string: [*c]const [*c]const c.GLchar, length: [*c]const c.GLint) callconv(.c) void;
pub const PFNGLCOMPILESHADERPROC = *const fn (shader: c.GLuint) callconv(.c) void;
pub const PFNGLGETSHADERIVPROC = *const fn (shader: c.GLuint, pname: c.GLenum, params: [*c]c.GLint) callconv(.c) void;
pub const PFNGLGETSHADERINFOLOGPROC = *const fn (shader: c.GLuint, bufSize: c.GLsizei, length: [*c]c.GLsizei, infoLog: [*c]c.GLchar) callconv(.c) void;
pub const PFNGLCREATEPROGRAMPROC = *const fn () callconv(.c) c.GLuint;
pub const PFNGLATTACHSHADERPROC = *const fn (program: c.GLuint, shader: c.GLuint) callconv(.c) void;
pub const PFNGLLINKPROGRAMPROC = *const fn (program: c.GLuint) callconv(.c) void;
pub const PFNGLGETPROGRAMIVPROC = *const fn (program: c.GLuint, pname: c.GLenum, params: [*c]c.GLint) callconv(.c) void;
pub const PFNGLUSEPROGRAMPROC = *const fn (program: c.GLuint) callconv(.c) void;
pub const PFNGLGETUNIFORMLOCATIONPROC = *const fn (program: c.GLuint, name: [*c]const c.GLchar) callconv(.c) c.GLint;
pub const PFNGLUNIFORMMATRIX4FVPROC = *const fn (location: c.GLint, count: c.GLsizei, transpose: c.GLboolean, value: [*c]const c.GLfloat) callconv(.c) void;

pub const GlFuncs = struct {
    glGenVertexArrays:          PFNGLGENVERTEXARRAYSPROC,
    glGenBuffers:               PFNGLGENBUFFERSPROC,
    glBindBuffer:               PFNGLBINDBUFFERPROC,
    glBufferData:               PFNGLBUFFERDATAPROC,
    glBindVertexArray:          PFNGLBINDVERTEXARRAYPROC,
    glVertexAttribPointer:      PFNGLVERTEXATTRIBPOINTERPROC,
    glEnableVertexAttribArray:  PFNGLENABLEVERTEXATTRIBARRAYPROC,
    glCreateShader:             PFNGLCREATESHADERPROC,
    glShaderSource:             PFNGLSHADERSOURCEPROC,
    glCompileShader:            PFNGLCOMPILESHADERPROC,
    glGetShaderiv:              PFNGLGETSHADERIVPROC,
    glGetShaderInfoLog:         PFNGLGETSHADERINFOLOGPROC,
    glCreateProgram:            PFNGLCREATEPROGRAMPROC,
    glAttachShader:             PFNGLATTACHSHADERPROC,
    glLinkProgram:              PFNGLLINKPROGRAMPROC,
    glGetProgramiv:             PFNGLGETPROGRAMIVPROC,
    glUseProgram:               PFNGLUSEPROGRAMPROC,
    glGetUniformLocation:       PFNGLGETUNIFORMLOCATIONPROC,
    glUniformMatrix4fv:         PFNGLUNIFORMMATRIX4FVPROC,

    pub fn load() !GlFuncs {
        return .{
            .glGenVertexArrays = @ptrCast(c.glfwGetProcAddress("glGenVertexArrays") orelse return error.MissingGlGenVertexArrays),
            .glGenBuffers = @ptrCast(c.glfwGetProcAddress("glGenBuffers") orelse return error.MissingGlGenBuffers),
            .glBindBuffer = @ptrCast(c.glfwGetProcAddress("glBindBuffer") orelse return error.MissingGlBindBuffer),
            .glBufferData = @ptrCast(c.glfwGetProcAddress("glBufferData") orelse return error.MissingGlBufferData),
            .glBindVertexArray = @ptrCast(c.glfwGetProcAddress("glBindVertexArray") orelse return error.MissingGlBindVertexArray),
            .glVertexAttribPointer = @ptrCast(c.glfwGetProcAddress("glVertexAttribPointer") orelse return error.MissingGlVertexAttribPointer),
            .glEnableVertexAttribArray = @ptrCast(c.glfwGetProcAddress("glEnableVertexAttribArray") orelse return error.MissingGlEnableVertexAttribArray),
            .glCreateShader = @ptrCast(c.glfwGetProcAddress("glCreateShader") orelse return error.MissingGlCreateShader),
            .glShaderSource = @ptrCast(c.glfwGetProcAddress("glShaderSource") orelse return error.MissingGlShaderSource),
            .glCompileShader = @ptrCast(c.glfwGetProcAddress("glCompileShader") orelse return error.MissingGlCompileShader),
            .glGetShaderiv = @ptrCast(c.glfwGetProcAddress("glGetShaderiv") orelse return error.MissingGlGetShaderiv),
            .glGetShaderInfoLog = @ptrCast(c.glfwGetProcAddress("glGetShaderInfoLog") orelse return error.MissingGlGetShaderInfoLog),
            .glCreateProgram = @ptrCast(c.glfwGetProcAddress("glCreateProgram") orelse return error.MissingGlCreateProgram),
            .glAttachShader = @ptrCast(c.glfwGetProcAddress("glAttachShader") orelse return error.MissingGlAttachShader),
            .glLinkProgram = @ptrCast(c.glfwGetProcAddress("glLinkProgram") orelse return error.MissingGlLinkProgram),
            .glGetProgramiv = @ptrCast(c.glfwGetProcAddress("glGetProgramiv") orelse return error.MissingGlGetProgramiv),
            .glUseProgram = @ptrCast(c.glfwGetProcAddress("glUseProgram") orelse return error.MissingGlUseProgram),
            .glGetUniformLocation = @ptrCast(c.glfwGetProcAddress("glGetUniformLocation") orelse return error.MissingGlGetUniformLocation),
            .glUniformMatrix4fv = @ptrCast(c.glfwGetProcAddress("glUniformMatrix4fv") orelse return error.MissingGlUniformMatrix4fv),
        };
    }
};