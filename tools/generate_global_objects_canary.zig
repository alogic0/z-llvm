//! Observed compiler globals and a relocation closure beyond 4,096 symbols.
const std = @import("std");
const u = @import("validation/common.zig");
const getters = [_][2][]const u8{
    .{ "escape", "escapes" },   .{ "poison", "poison_cells" }, .{ "float", "floats" },
    .{ "half", "halves" },      .{ "extended", "x87" },        .{ "relative", "relative_table" },
    .{ "first", "first_data" }, .{ "second", "second_data" },  .{ "many", "heads" },
};

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const out = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    try w.writeAll(@embedFile("templates/global_objects.ll"));
    for (0..4097) |index| try w.print("\n@global_objects_leaf_{d} = internal global i8 {d}", .{ index, index % 251 });
    try w.writeAll("\n@global_objects_heads = private constant [4097 x ptr] [");
    for (0..4097) |index| try w.print("{s}ptr @global_objects_leaf_{d}", .{ if (index == 0) "" else ", ", index });
    try w.writeAll("]\n");
    var names: [getters.len][]const u8 = undefined;
    for (getters, &names) |getter, *name| {
        name.* = try c.fmt("global_objects_{s}", .{getter[0]});
        try w.print("define ptr @{s}() {{\nentry:\n ret ptr @global_objects_{s}\n}}\n", .{ name.*, getter[1] });
    }
    try c.write(try c.join(&.{ out, "global_objects.ll" }), llvm.written());
    try c.write(try c.join(&.{ out, "global_objects_driver.c" }), @embedFile("templates/global_objects_driver.c"));
    const population = try u.toValue(c.a, .{
        .population = "global_objects",
        .prefix = "global-objects",
        .fixture = "global_objects",
        .functions = names,
        .observations = 12460,
        .stdout = "global-objects observations=12460 escapes=poison=floats=relative=capacity=neighbors=preserved\n",
    });
    try c.writeJson(try c.join(&.{ out, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "global_objects")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ out, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
