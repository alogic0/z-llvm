const std = @import("std");
const ir = @import("../ir.zig");
const function_attrs = @import("../passes/function_attrs.zig");
const pass_manager = @import("../pass_manager.zig");

test "function attributes: inferred attributes precede metadata and trailing header clauses" {
    for ([_][]const u8{
        "!dbg !0",
        "unnamed_addr #0 !dbg !0",
        "#0 \"note\"=\"!dbg false boundary\" !dbg !0",
        "#0 section \".text !fake\" align 16 !dbg !0",
    }) |attrs| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i32 @entry() {s} {{\nentry:\n  ret i32 7\n}}\nattributes #0 = {{ nounwind }}\n!0 = !{{}}\n", .{attrs});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
        _ = try function_attrs.pass.run(&module, &context);
        const actual = module.functions.items[0].attrs.?;
        try std.testing.expect(std.mem.endsWith(u8, actual, "!dbg !0"));
        const memory = std.mem.indexOf(u8, actual, "memory(none)").?;
        const metadata_start = std.mem.lastIndexOf(u8, actual, "!dbg !0").?;
        try std.testing.expect(memory < metadata_start);
        if (std.mem.indexOf(u8, actual, "section")) |section| try std.testing.expect(memory < section);
        if (std.mem.indexOf(u8, attrs, "unnamed_addr") != null) try std.testing.expect(std.mem.startsWith(u8, actual, "unnamed_addr #0 "));
        if (std.mem.indexOf(u8, attrs, "\"note\"")) |_| try std.testing.expect(std.mem.indexOf(u8, actual, "\"note\"=\"!dbg false boundary\"") != null);
        try module.verify();
    }
}
