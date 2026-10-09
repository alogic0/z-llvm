const std = @import("std");

pub const Match = enum {
    exact,
    basename,
};

pub const Evidence = struct {
    construction: bool = false,
    store: bool = false,
    load: bool = false,
};

pub const Fact = struct {
    name: []const u8,
    aggregate_text: []const u8,
    match: Match = .basename,
    evidence: Evidence = .{
        .construction = true,
        .store = true,
        .load = true,
    },
};

const facts = [_]Fact{
    .{
        .name = "BiasedFp(f64)",
        .aggregate_text = "{ i64, i32 }",
        .match = .basename,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "BiasedFp(f32)",
        .aggregate_text = "{ i32, i32 }",
        .match = .basename,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "PartIterator",
        .aggregate_text = "{ i32, i5 }",
        .match = .basename,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "Progress.Node",
        .aggregate_text = "{ i8 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "RegisterFormatter",
        .aggregate_text = "{ i64, i32 }",
        .match = .basename,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "FormatZigType",
        .aggregate_text = "{ { i32 }, ptr }",
        .match = .basename,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "LazyMapRef",
        .aggregate_text = "{ i1, i32 }",
        .match = .basename,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "ArenaAllocator",
        .aggregate_text = "{ { ptr, ptr }, { ptr, ptr } }",
        .match = .basename,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "codegen.c.type.CType.Formatter",
        .aggregate_text = "{ i32, ptr, i8 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "link.Wasm.FunctionType.Formatter",
        .aggregate_text = "{ ptr, { i32, i32 } }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "link.Elf",
        .aggregate_text = "{ [109 x i64], ptr }",
        .match = .exact,
        .evidence = .{
            .construction = false,
            .store = false,
            .load = true,
        },
    },
    .{
        .name = "section_64",
        .aggregate_text = "{ [16 x i8], [16 x i8], i64, i64, i32, i32, i32, i32, i32, i32, i32, i32 }",
        .match = .basename,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "ShuffleOneMask",
        .aggregate_text = "{ i31, i1 }",
        .match = .basename,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "link.Elf.eh_frame.Cie",
        .aggregate_text = "{ i64, i64, i32, i32, i32, i32, i64, i1 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "link.Elf.eh_frame.Fde",
        .aggregate_text = "{ i64, i64, i32, i32, i32, i32, i1, i64 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
};

pub fn lookup(nominal: []const u8) ?Fact {
    const normalized = stripNominalSigil(std.mem.trim(u8, nominal, " "));
    for (facts) |fact| {
        if (factMatches(normalized, fact)) return fact;
    }
    return null;
}

pub fn count() usize {
    return facts.len;
}

pub fn all() []const Fact {
    return facts[0..];
}

fn factMatches(nominal: []const u8, fact: Fact) bool {
    return switch (fact.match) {
        .exact => std.mem.eql(u8, nominal, fact.name),
        .basename => std.mem.eql(u8, typeBasename(nominal), fact.name),
    };
}

fn typeBasename(text: []const u8) []const u8 {
    const trimmed = stripNominalSigil(std.mem.trim(u8, text, " "));
    if (std.mem.lastIndexOfScalar(u8, trimmed, '.')) |dot| return trimmed[dot + 1 ..];
    return trimmed;
}

fn stripNominalSigil(text: []const u8) []const u8 {
    if (text.len != 0 and (text[0] == '%' or text[0] == '@')) return text[1..];
    return text;
}

pub fn nominalFieldByteOffset(nominal_name: []const u8, field_index: usize) ?u64 {
    const trimmed = std.mem.trim(u8, nominal_name, " ");
    const name = if (std.mem.startsWith(u8, trimmed, "const ")) std.mem.trim(u8, trimmed[6..], " ") else trimmed;
    if (std.mem.eql(u8, name, "macho.section_64") or std.mem.endsWith(u8, name, ".section_64") or std.mem.eql(u8, name, "section_64")) {
        return switch (field_index) {
            8 => 64, // flags: u32
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "math.big.int.Managed") or std.mem.endsWith(u8, name, ".math.big.int.Managed") or std.mem.eql(u8, name, "Managed") or std.mem.endsWith(u8, name, ".Managed")) {
        return switch (field_index) {
            2 => 32, // metadata: usize
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "zig.Ast.Render.AutoIndentingStream") or std.mem.endsWith(u8, name, ".AutoIndentingStream") or std.mem.eql(u8, name, "AutoIndentingStream")) {
        return switch (field_index) {
            7 => 104, // indent: usize
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Compilation") or std.mem.endsWith(u8, name, ".Compilation")) {
        return switch (field_index) {
            7 => 88, // root_mod: *Module
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Module") or std.mem.endsWith(u8, name, ".Module")) {
        return switch (field_index) {
            11 => 622, // strip: bool
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "codegen.c.type.CType.Formatter") or std.mem.endsWith(u8, name, ".codegen.c.type.CType.Formatter") or std.mem.eql(u8, name, "CType.Formatter") or std.mem.endsWith(u8, name, ".CType.Formatter") or std.mem.eql(u8, name, "Formatter") or std.mem.endsWith(u8, name, ".Formatter")) {
        return switch (field_index) {
            0 => 8, // cty: CType
            1 => 0, // zcu: *const Zcu
            2 => 12, // kind: enum
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "codegen.c.Function") or std.mem.endsWith(u8, name, ".codegen.c.Function") or std.mem.eql(u8, name, "Function") or std.mem.endsWith(u8, name, ".Function")) {
        return switch (field_index) {
            8 => 64, // indent: usize
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Io.Writer.Allocating") or std.mem.endsWith(u8, name, ".Io.Writer.Allocating")) {
        return switch (field_index) {
            1 => 16, // writer: Writer
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Io.Writer") or std.mem.endsWith(u8, name, ".Io.Writer") or std.mem.eql(u8, name, "Writer") or std.mem.endsWith(u8, name, ".Writer")) {
        return switch (field_index) {
            2 => 24, // end: usize
            else => null,
        };
    }
    return null;
}

test "aggregate layout facts keep exact pair ownership narrow" {
    try std.testing.expectEqual(@as(usize, 15), count());
    try std.testing.expect(lookup("aggregate_abi.Pair") == null);
    try std.testing.expect(lookup("%runtime_aggregate_pair_main.Pair") == null);
    try std.testing.expect(lookup("other.Pair") == null);
    try std.testing.expect(lookup("fmt.parse_float.common.BiasedFp(f64)") != null);
    try std.testing.expect(lookup("fmt.parse_float.common.BiasedFp(f32)") != null);
    try std.testing.expect(lookup("codegen.aarch64.Select.Value.PartIterator") != null);
    try std.testing.expect(lookup("Progress.Node") != null);
    try std.testing.expect(lookup("codegen.aarch64.Disassemble.RegisterFormatter") != null);
    try std.testing.expect(lookup("codegen.c.type.CType.FormatZigType") != null);
    try std.testing.expect(lookup("codegen.c.type.CType.Formatter") != null);
    try std.testing.expect(lookup("link.Coff.Node.LazyMapRef") != null);
    try std.testing.expect(lookup("heap.ArenaAllocator") != null);
    try std.testing.expect(lookup("link.Wasm.FunctionType.Formatter") != null);
    try std.testing.expect(lookup("macho.section_64") != null);
    try std.testing.expect(lookup("Air.ShuffleOneMask") != null);
    try std.testing.expect(lookup("link.Elf.eh_frame.Cie") != null);
    try std.testing.expect(lookup("link.Elf.eh_frame.Fde") != null);
}
