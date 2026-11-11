//! Reproduce the additional lowering forms required by the original runtime.
const std = @import("std");
const u = @import("validation/common.zig");
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const out = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    try w.writeAll(@embedFile("templates/runtime_frontier.ll"));
    var names = std.array_list.Managed([]const u8).init(c.a);
    for ([_][]const u8{ "body", "cttz", "min", "max", "pairs", "div", "ucmp", "scmp", "ucmp32", "half", "sign", "halfmax", "shuffle", "packed", "packed_call", "quad", "max80", "max128", "byval", "byval_call" }) |name| try names.append(try c.fmt("runtime_frontier_{s}", .{name}));
    for ([_]u8{ 0, 1, 63, 64, 65, 127 }) |shift| {
        const name = try c.fmt("runtime_frontier_funnel_{d}", .{shift});
        try names.append(name);
        try w.print("define i128 @{s}(i128 %a,i128 %b) {{\nentry:\n %r = call i128 @llvm.fshl.i128(i128 %a,i128 %b,i128 {d})\n ret i128 %r\n}}\n", .{ name, shift });
    }
    try c.write(try c.join(&.{ out, "runtime_frontier.ll" }), llvm.written());
    try c.write(try c.join(&.{ out, "runtime_frontier_driver.c" }), @embedFile("templates/runtime_frontier_driver.c"));
    const population = try u.toValue(c.a, .{ .population = "runtime_frontier", .prefix = "runtime-frontier", .fixture = "runtime_frontier", .functions = names.items, .codegen_args = &.{"--codegen-reachable"}, .libraries = &.{"m"}, .observations = 852, .stdout = "runtime-frontier observations=852 pairs=intrinsics=vectors=half=aliases=preserved\n" });
    try c.writeJson(try c.join(&.{ out, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "runtime_frontier")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ out, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
