<img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/zig/zig-original.svg" alt="zig-icon" width=40 align="right"/>

# **cad.zig**

A CAD Software written in Zig.

## Goals

- [ ] Geometric Core
- [ ] GUI Interface
- [ ] TUI Interface
- [ ] Persistence

## Dependecies

| Tech      | Version   |
| --------- | --------- |
| Zig       | 0.17      |
| OpenGL    | 4.6.0     |

## Build

In your terminal use:

> `~$ cd cad.zig`  
> `~/cad.zig$ zig translate-c -lc src/render/gl_glfw.h > src/render/c_glfw.zig`  
> `~/cad.zig$ zig build run-gui`  
