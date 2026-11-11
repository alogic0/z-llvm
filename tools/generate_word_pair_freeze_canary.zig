//! Two-word freeze fields remain stable through actual caller-register clobbers.
const std = @import("std");
const u = @import("validation/common.zig");

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "registry-input" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var llvm: std.Io.Writer.Allocating = .init(c.a);
    var driver: std.Io.Writer.Allocating = .init(c.a);
    const w = &llvm.writer;
    const d = &driver.writer;
    try w.writeAll("target triple = \"x86_64-unknown-linux-gnu\"\ndeclare void @word_pair_freeze_clobber()\n");
    try d.writeAll("#include <stdint.h>\ntypedef uint64_t (*freeze_fn)(uint64_t,uint64_t,uint64_t,uint8_t*);\n");
    var names: std.ArrayList([]const u8) = .empty;
    var cases: std.Io.Writer.Allocating = .init(c.a);
    for ([_][2][]const u8{ .{ "ptr", "i64" }, .{ "i64", "ptr" }, .{ "ptr", "ptr" }, .{ "i64", "i64" } }, 0..) |types, kind| {
        for (0..4) |variant| {
            const name = try c.fmt("word_pair_freeze_{d}_{d}", .{ kind, variant });
            try names.append(c.a, name);
            const ty = try c.fmt("{{ {s}, {s} }}", .{ types[0], types[1] });
            try w.print("define i64 @{s}(i64 %a, i64 %b, i64 %live, ptr %out) {{\nentry:\n", .{name});
            for (types, 0..) |field_ty, field| {
                const input = if (field == 0) "a" else "b";
                if (std.mem.eql(u8, field_ty, "ptr"))
                    try w.print(" %v{d} = inttoptr i64 %{s} to ptr\n", .{ field, input })
                else
                    try w.print(" %v{d} = add i64 %{s}, 0\n", .{ field, input });
            }
            try w.print(" %first = insertvalue {s} {s}, {s} %v0, 0\n %whole = insertvalue {s} %first, {s} %v1, 1\n", .{ ty, if (variant == 2) "undef" else "poison", types[0], ty, types[1] });
            const input = if (variant == 0) "%whole" else if (variant == 3) "zeroinitializer" else "%first";
            try w.print(" %frozen = freeze {s} {s}\n call void @word_pair_freeze_clobber()\n", .{ ty, input });
            for (0..4) |copy| {
                const field = copy % 2;
                try w.print(" %field{d} = extractvalue {s} %frozen, {d}\n %word{d} = {s} {s} %field{d}{s}\n", .{
                    copy,         ty,   field,                                                          copy, if (std.mem.eql(u8, types[field], "ptr")) "ptrtoint" else "add",
                    types[field], copy, if (std.mem.eql(u8, types[field], "ptr")) " to i64" else ", 0",
                });
                try w.print(" %address{d} = getelementptr i8, ptr %out, i64 {d}\n store {s} %field{d}, ptr %address{d}, align 1\n", .{ copy, copy * 8, types[field], copy, copy });
            }
            try w.writeAll(" %same_first = xor i64 %word0, %word2\n %same_second = xor i64 %word1, %word3\n %stable = or i64 %same_first, %same_second\n");
            try w.print(" %observed = xor i64 %word0, %{s}\n %checked = xor i64 %observed, %stable\n %answer = xor i64 %checked, %live\n ret i64 %answer\n}}\n", .{if (variant == 1 or variant == 2) "same_second" else "word1"});
            try d.print("extern uint64_t {s}(uint64_t,uint64_t,uint64_t,uint8_t*);\n", .{name});
            try cases.writer.print(" {{{s},{d}}},\n", .{ name, variant });
        }
    }
    try d.writeAll("static const struct { freeze_fn run; unsigned variant; } cases[]={\n");
    try d.writeAll(cases.written());
    try d.writeAll("};\n");
    try d.writeAll(@embedFile("templates/word_pair_freeze_driver.c"));
    try c.write(try c.join(&.{ output, "word_pair_freeze.ll" }), llvm.written());
    try c.write(try c.join(&.{ output, "word_pair_freeze_driver.c" }), driver.written());
    const population = try u.toValue(c.a, .{
        .population = "word_pair_freeze",
        .prefix = "word-pair-freeze",
        .fixture = "word_pair_freeze",
        .functions = names.items,
        .observations = 1024,
        .stdout = "word-pair-freeze observations=1024 defined=stable=clobbers=stores=guards=preserved\n",
    });
    try c.writeJson(try c.join(&.{ output, "population.json" }), population);
    if (args.get("registry-input")) |path| {
        const original = try c.read(try c.join(&.{path}));
        const registry = try c.load(try c.join(&.{path}));
        for (try u.json.array(try u.get(registry, "canaries"))) |entry| if (std.mem.eql(u8, try u.str(entry, "population"), "word_pair_freeze")) return error.PopulationAlreadyRegistered;
        const end = std.mem.lastIndexOf(u8, original, "\n  ]") orelse return error.UnexpectedRegistryLayout;
        const rendered = try std.json.Stringify.valueAlloc(c.a, population, .{ .whitespace = .indent_2 });
        const indented = try std.mem.replaceOwned(u8, c.a, rendered, "\n", "\n    ");
        try c.write(try c.join(&.{ output, "native_canaries.json" }), try c.fmt("{s},\n    {s}{s}", .{ original[0..end], indented, original[end..] }));
    }
}
