// src/core/mesh/tessellator.zig
// standard imports
const std = @import("std");

// external imports

// project imports
const Point = @import("../math/point.zig").Point;
const Topology = @import("../topo/topology.zig");

// Representa um malha de triangulos para GPU
pub const TriangleMesh = struct {
    allocator:  std.mem.Allocator,
    vertices:   std.ArrayList(f32),
    indices:    std.ArrayList(u32),

    pub fn init(allocator: std.mem.Allocator) TriangleMesh {
        return .{
            .allocator  = allocator,
            .vertices   = .empty,
            .indices    = .empty,
        };
    }

    pub fn deinit(self: *TriangleMesh) void {
        self.vertices.deinit(self.allocator);
        self.indices.deinit(self.allocator);
    }
};

pub const Tessellator = struct {
    pub fn tessellatorBody(body: *const Topology.BRepBody, allocator: std.mem.Allocator) !TriangleMesh {
        var mesh = TriangleMesh.init(allocator);
        errdefer mesh.deinit();

        for (body.faces.items, 0..) |_, face_idx| {
            const face_handle = @as(Topology.FaceHandle, @intCast(face_idx));
            const face = body.faces.items[face_handle];

            var face_points: std.ArrayList(Point) = .empty;
            defer face_points.deinit(allocator);

            const start_he = face.outer_edge;
            var current_he = start_he;

            while (true) {
                const he = body.half_edge.items[current_he];
                const vertex = body.vertices.items[he.origin];
                try face_points.append(allocator, vertex.point);

                current_he = he.next;
                if (current_he == start_he) break;
            }

            if (face_points.items.len < 3) continue;

            const base_vertex_idx = @as(u32, @intCast(mesh.vertices.items.len / 3));

            for (face_points.items) |pt| {
                try mesh.vertices.append(allocator, @floatCast(pt.x));
                try mesh.vertices.append(allocator, @floatCast(pt.y));
                try mesh.vertices.append(allocator, @floatCast(pt.z));
            }

            const num_pts = @as(u32, @intCast(face_points.items.len));

            var i: u32 = 1;
            while (i < num_pts - 1) : (i += 1) {
                try mesh.indices.append(allocator, base_vertex_idx);
                try mesh.indices.append(allocator, base_vertex_idx + i);
                try mesh.indices.append(allocator, base_vertex_idx + i + 1);
            }
        }

        return mesh;
    }
};