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

const PFNGLGENVERTEXARRAYSPROC = *const fn (n: c.GLsizei, arrays: [*c]c.GLuint) callconv(.c) void;
const PFNGLGENBUFFERSPROC = *const fn (n: c.GLsizei, buffers: [*c]c.GLuint) callconv(.c) void;
const PFNGLBINDBUFFERPROC = *const fn (target: c.GLenum, buffer: c.GLuint) callconv(.c) void;
const PFNGLBUFFERDATAPROC = *const fn (target: c.GLenum, size: c.GLsizeiptr, data: ?*const anyopaque, usage: c.GLenum) callconv(.c) void;
const PFNGLBINDVERTEXARRAYPROC = *const fn (array: c.GLuint) callconv(.c) void;
const PFNGLVERTEXATTRIBPOINTERPROC = *const fn (index: c.GLuint, size: c.GLint, type_: c.GLenum, normalized: c.GLboolean, stride: c.GLsizei, pointer: ?*const anyopaque) callconv(.c) void;
const PFNGLENABLEVERTEXATTRIBARRAYPROC = *const fn (index: c.GLuint) callconv(.c) void;

pub const GlFuncs = struct {
    glGenVertexArrays:          PFNGLGENVERTEXARRAYSPROC,
    glGenBuffers:               PFNGLGENBUFFERSPROC,
    glBindBuffer:               PFNGLBINDBUFFERPROC,
    glBufferData:               PFNGLBUFFERDATAPROC,
    glBindVertexArray:          PFNGLBINDVERTEXARRAYPROC,
    glVertexAttribPointer:      PFNGLVERTEXATTRIBPOINTERPROC,
    glEnableVertexAttribArray:  PFNGLENABLEVERTEXATTRIBARRAYPROC,

    pub fn load() !GlFuncs {
        return .{
            .glGenVertexArrays = @ptrCast(c.glfwGetProcAddress("glGenVertexArrays") orelse return error.MissingGlGenVertexArrays),
            .glGenBuffers = @ptrCast(c.glfwGetProcAddress("glGenBuffers") orelse return error.MissingGlGenBuffers),
            .glBindBuffer = @ptrCast(c.glfwGetProcAddress("glBindBuffer") orelse return error.MissingGlBindBuffer),
            .glBufferData = @ptrCast(c.glfwGetProcAddress("glBufferData") orelse return error.MissingGlBufferData),
            .glBindVertexArray = @ptrCast(c.glfwGetProcAddress("glBindVertexArray") orelse return error.MissingGlBindVertexArray),
            .glVertexAttribPointer = @ptrCast(c.glfwGetProcAddress("glVertexAttribPointer") orelse return error.MissingGlVertexAttribPointer),
            .glEnableVertexAttribArray = @ptrCast(c.glfwGetProcAddress("glEnableVertexAttribArray") orelse return error.MissingGlEnableVertexAttribArray),
        };
    }
};