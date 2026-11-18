//! Relate a successful compiler build's hook markers to its local captures.
const std = @import("std");
const u = @import("common.zig");
const preopt = @import("preopt_capture.zig");

const Module = enum { compiler, runtime, other };

fn module(path: []const u8, suffix: []const u8) Module {
    const name = std.fs.path.basename(path);
    if (!std.mem.endsWith(u8, name, suffix)) return .other;
    const stem = name[0 .. name.len - suffix.len];
    if (u.contains(&.{ "zig_zcu.o", "zig.o", "zig" }, stem)) return .compiler;
    if (u.contains(&.{ "compiler_rt_zcu.o", "compiler_rt.o", "compiler_rt" }, stem)) return .runtime;
    return .other;
}

pub const Evidence = struct {
    compiler: bool = false,
    runtime: bool = false,
    objects_complete: bool,
    failure_stage: ?u.Value = null,
};

pub fn record(c: *u.Context, parent: *u.Value, captures: preopt.Captures, is_preopt: bool, self_rebuild: bool) !Evidence {
    try u.put(c.a, parent, if (self_rebuild) "self_rebuild_invocations" else "invocations", captures.objects);
    var result = Evidence{ .objects_complete = captures.objects.array.items.len != 0 };
    if (is_preopt) {
        try u.put(c.a, parent, if (self_rebuild) "self_rebuild_optimizations" else "optimizations", captures.optimizations);
        for (captures.optimizations.array.items) |opt| {
            if (!u.json.eql(opt.object.get("output_delivered") orelse .null, u.b(true))) result.failure_stage = try u.get(opt, "failure_stage");
        }
    }
    for (captures.objects.array.items) |object| {
        switch (module(try u.str(object, "original_input"), if (is_preopt) ".zllvm.optimized.ll" else ".zllvm.ll")) {
            .compiler => result.compiler = true,
            .runtime => result.runtime = true,
            .other => {},
        }
        if (!u.json.eql(try u.get(object, "object_complete"), u.b(true))) {
            result.objects_complete = false;
            result.failure_stage = try u.get(object, "failure_stage");
        }
    }
    try u.put(c.a, parent, if (self_rebuild) "self_rebuild_compiler_object_captured" else "compiler_object_captured", u.b(result.compiler));
    try u.put(c.a, parent, if (self_rebuild) "self_rebuild_all_hook_objects_complete" else "all_hook_objects_complete", u.b(result.objects_complete));
    return result;
}

fn verifyMarkers(a: std.mem.Allocator, markers: []const u8, optimizations: u.Value) !void {
    const suffix = ".zllvm.preopt.ll";
    var pending = std.StringHashMap(void).init(a);
    defer pending.deinit();
    for (optimizations.array.items) |opt| {
        const raw = try u.str(opt, "original_input");
        if (!std.mem.endsWith(u8, raw, suffix)) return error.UnboundPreoptMarker;
        const pair = try std.fmt.allocPrint(a, " object={s} ir={s}", .{ raw[0 .. raw.len - suffix.len], raw });
        if ((try pending.getOrPut(pair)).found_existing) return error.UnboundPreoptMarker;
    }
    var lines = std.mem.tokenizeScalar(u8, markers, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "pipeline=preopt zllvm_passes=zig-release-fast-accepted target=x86_64-unknown-linux-gnu zig_target=") or
            !std.mem.endsWith(u8, line, " mode=ReleaseFast")) return error.UnboundPreoptMarker;
        const start = std.mem.indexOf(u8, line, " object=") orelse return error.UnboundPreoptMarker;
        const end = std.mem.lastIndexOf(u8, line, " case_id=") orelse return error.UnboundPreoptMarker;
        if (end <= start or !pending.remove(line[start..end])) return error.UnboundPreoptMarker;
    }
    if (pending.count() != 0) return error.UnboundPreoptMarker;
}

fn verifyObjectDelivery(object: u.Value) !void {
    const input = try u.str(object, "original_input_resolved");
    const suffix = ".zllvm.optimized.ll";
    const delivered = try u.get(object, "delivery");
    if (!std.mem.endsWith(u8, input, suffix) or !u.json.is(try u.get(delivered, "path"), input[0 .. input.len - suffix.len])) return error.WrongBuildObjectDelivery;
    const emitted = try u.get(object, "object");
    for ([_][]const u8{ "bytes", "sha256" }) |key| {
        if (!u.json.eql(try u.get(emitted, key), try u.get(delivered, key))) return error.WrongBuildObjectDelivery;
    }
}

pub fn verify(c: *u.Context, run: []const u8, generation: []const u8, parent: u.Value, captures: preopt.Captures, evidence: Evidence, is_preopt: bool) !void {
    if (!evidence.compiler) return error.MissingCompilerObjectCapture;
    const markers = try c.read(try c.join(&.{ generation, "hook.marker" }));
    if (!is_preopt) {
        if (std.mem.indexOf(u8, markers, "pipeline=postopt") == null) return error.MissingPostoptHookMarker;
        return;
    }
    if (!evidence.runtime) return error.MissingRuntimeObjectCapture;
    try preopt.reconcile(c.a, captures);
    try verifyMarkers(c.a, markers, captures.optimizations);
    for (captures.objects.array.items) |object| {
        if (!u.json.eql(try u.get(object, "backend_executed"), u.b(true))) return error.MissingLocalObjectExecution;
        try preopt.audit(c, run, parent, object);
        try verifyObjectDelivery(object);
    }
}

test "preopt whole-build binds the delivered object to the emitted bytes and frontend object path" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const emitted = .{ .bytes = 12, .sha256 = "digest" };
    var object = try u.toValue(a, .{ .original_input_resolved = "/cache/zig.o.zllvm.optimized.ll", .object = emitted, .delivery = .{ .path = "/cache/zig.o", .bytes = 12, .sha256 = "digest" } });
    try verifyObjectDelivery(object);
    try u.put(a, &object, "object", try u.toValue(a, .{ .bytes = 12, .sha256 = "other" }));
    try std.testing.expectError(error.WrongBuildObjectDelivery, verifyObjectDelivery(object));
    try u.put(a, &object, "object", try u.toValue(a, emitted));
    try u.put(a, &object, "original_input_resolved", u.s("/other/zig.o.zllvm.optimized.ll"));
    try std.testing.expectError(error.WrongBuildObjectDelivery, verifyObjectDelivery(object));
}

test "preopt whole-build distinguishes the actual compiler and runtime modules" {
    try std.testing.expectEqual(Module.compiler, module("cache/zig_zcu.o.zllvm.optimized.ll", ".zllvm.optimized.ll"));
    try std.testing.expectEqual(Module.runtime, module("zig/compiler_rt_zcu.o.zllvm.optimized.ll", ".zllvm.optimized.ll"));
    try std.testing.expectEqual(Module.other, module("cache/not_zig_zcu.o.zllvm.optimized.ll", ".zllvm.optimized.ll"));
    try std.testing.expectEqual(Module.other, module("cache/zig_zcu.o.zllvm.preopt.ll", ".zllvm.optimized.ll"));
}

test "preopt whole-build matches every hook marker to one original input" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const opts = try u.toValue(a, .{.{ .original_input = "cache/zig.o.zllvm.preopt.ll" }});
    const marker = "pipeline=preopt zllvm_passes=zig-release-fast-accepted target=x86_64-unknown-linux-gnu zig_target=x object=cache/zig.o ir=cache/zig.o.zllvm.preopt.ll case_id= wrapper= mode=ReleaseFast\n";
    try verifyMarkers(a, marker, opts);
    try std.testing.expectError(error.UnboundPreoptMarker, verifyMarkers(a, "", opts));
    try std.testing.expectError(error.UnboundPreoptMarker, verifyMarkers(a, marker ++ marker, opts));
    try std.testing.expectError(error.UnboundPreoptMarker, verifyMarkers(a, marker, try u.toValue(a, .{.{ .original_input = "other/zig.o.zllvm.preopt.ll" }})));
}
