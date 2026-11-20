// src/core/topo/builder.zig
// standard imports
const std = @import("std");

// external imports

// project imports
const Point = @import("../math/point.zig").Point;
const Vec3d = @import("../math/vec3d.zig").Vec3d;
const Topology = @import("./topology.zig");

const BRepBody = Topology.BRepBody;

pub const BRepBuilder = struct {
    pub fn extrudePolygon(
        allocator: std.mem.Allocator,
        profile: []const Point,
        extrusion_vector: Vec3d,
    ) !BRepBody {
        var body = BRepBody.init(allocator);
        errdefer body.deinit();

        const n = profile.len;
        if (n < 3) return error.InvalidPolygon;

        var bottom_vertices = try allocator.alloc(Topology.VertexHandle, n);
        defer allocator.free(bottom_vertices);

        var top_vertices = try allocator.alloc(Topology.VertexHandle, n);
        defer allocator.free(top_vertices);

        for (profile, 0..) |pt, i| {
            bottom_vertices[i] = try body.addVertex(pt, 0);
            const top_pt = pt.add(extrusion_vector);
            top_vertices[i] = try body.addVertex(top_pt, 0);
        }

        return body;
    }

    pub fn createBox(allocator: std.mem.Allocator, dx: f64, dy: f64, dz: f64) !BRepBody {
        var body = BRepBody.init(allocator);
        errdefer body.deinit();

        const v0 = try body.addVertex(Point.init(0.0, 0.0, 0.0), 0);
        const v1 = try body.addVertex(Point.init(dx , 0.0, 0.0), 0);
        const v2 = try body.addVertex(Point.init(dx , dy , 0.0), 0);
        const v3 = try body.addVertex(Point.init(0.0, dy , 0.0), 0);

        const v4 = try body.addVertex(Point.init(0.0, 0.0, dz ), 0);
        const v5 = try body.addVertex(Point.init(dx , 0.0, dz ), 0);
        const v6 = try body.addVertex(Point.init(dx , dy , dz ), 0);
        const v7 = try body.addVertex(Point.init(0.0, dy , dz ), 0);

        const face_verts = [6][4]Topology.VertexHandle {
            .{v0, v3, v2, v1},  // Face 0: Fundo    (z = 0)
            .{v4, v5, v6, v7},  // Face 1: Topo     (z = dz)
            .{v0, v1, v5, v4},  // Face 2: Frente   (y = 0)
            .{v1, v2, v6, v5},  // Face 3: Direita  (x = dx)
            .{v2, v3, v7, v6},  // Face 4: Costas   (y = dy)
            .{v3, v0, v4, v7},  // Face 5: Esquerda (x = 0)
        };

        try body.half_edge.resize(allocator, 24);
        try body.faces.resize(allocator, 6);

        for (0..6) |f_usize| {
            const f: Topology.FaceHandle = @intCast(f_usize);
            const base_he: Topology.HalfEdgeHandle = f * 4;
            body.faces.items[f] = .{ .outer_edge = base_he };

            for (0..4) |k_usize| {
                const k: u32 = @intCast(k_usize);
                const he_idx: Topology.HalfEdgeHandle = base_he + k;
                const next_k: u32 = (k + 1) % 4;
                const prev_k: u32 = (k + 3) % 4;

                body.half_edge.items[he_idx] = .{
                    .origin = face_verts[f_usize][k_usize],
                    .twin = 0,
                    .next = base_he + next_k,
                    .prev = base_he + prev_k,
                    .face = f,
                };
            }
        }

        for (0..24) |i_usize| {
            const i: Topology.HalfEdgeHandle = @intCast(i_usize);
            const he_a = body.half_edge.items[i];
            const end_a = body.half_edge.items[he_a.next].origin;

            for (0..24) |j_usize| {
                if (i_usize == j_usize) continue;
                 
                const j: Topology.HalfEdgeHandle = @intCast(j_usize);
                const he_b = body.half_edge.items[j];
                const end_b = body.half_edge.items[he_b.next].origin;

                if (he_a.origin == end_b and he_b.origin == end_a) {
                    body.half_edge.items[i].twin = j;
                    break;
                }
            }
        }

        for (body.vertices.items, 0..) |*vert, v_idx| {
            const vh: Topology.VertexHandle = @intCast(v_idx);
            for (body.half_edge.items, 0..) |he, he_idx| {
                if (he.origin == vh) {
                    vert.outgoing_edge = @intCast(he_idx);
                    break;
                }
            }
        }

        return body;
    }
};
