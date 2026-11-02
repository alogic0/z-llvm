const std = @import("std");
const enum_facts = @import("zig_air_enum_facts.zig");

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
        .name = "Imm64",
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
    .{
        .name = "hash.xxhash.XxHash64.Accumulator",
        .aggregate_text = "{ i64, i64, i64, i64 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "XxHash64.Accumulator",
        .aggregate_text = "{ i64, i64, i64, i64 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "zig.llvm.Builder.Metadata.CompositeType",
        .aggregate_text = "{ i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "CompositeType",
        .aggregate_text = "{ i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 }",
        .match = .basename,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "zig.llvm.Builder.Metadata.DerivedType",
        .aggregate_text = "{ i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "DerivedType",
        .aggregate_text = "{ i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 }",
        .match = .basename,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "zig.llvm.Builder.Value.FormatData",
        .aggregate_text = "{ i32, i32, ptr, i32 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "Value.FormatData",
        .aggregate_text = "{ i32, i32, ptr, i32 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "InternPool.Float64",
        .aggregate_text = "{ i32, i32 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "Float64",
        .aggregate_text = "{ i32, i32 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "InternPool.PtrInt",
        .aggregate_text = "{ i32, i32, i32 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "PtrInt",
        .aggregate_text = "{ i32, i32, i32 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "Io.LockedStderr",
        .aggregate_text = "{ ptr, i8 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "LockedStderr",
        .aggregate_text = "{ ptr, i8 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "Io.Terminal",
        .aggregate_text = "{ ptr, i8 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "Terminal",
        .aggregate_text = "{ ptr, i8 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "crypto.blake3.ChunkState",
        .aggregate_text = "{ [8 x i32], i64, [64 x i8], i8, i8, i8 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "ChunkState",
        .aggregate_text = "{ [8 x i32], i64, [64 x i8], i8, i8, i8 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "elf.Elf64.Phdr",
        .aggregate_text = "{ i32, i32, i64, i64, i64, i64, i64, i64 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "Elf64.Phdr",
        .aggregate_text = "{ i32, i32, i64, i64, i64, i64, i64, i64 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "Phdr",
        .aggregate_text = "{ i32, i32, i64, i64, i64, i64, i64, i64 }",
        .match = .basename,
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

pub var active_mode: ?[]const u8 = null;

pub fn setActiveMode(mode: ?[]const u8) void {
    active_mode = mode;
}

pub fn nominalFieldByteOffset(nominal_name: []const u8, field_index: usize) ?u64 {
    const trimmed = std.mem.trim(u8, nominal_name, " ");
    const name = if (std.mem.startsWith(u8, trimmed, "const ")) std.mem.trim(u8, trimmed[6..], " ") else trimmed;
    if (std.mem.eql(u8, name, "Target.Query") or std.mem.eql(u8, name, "std.Target.Query") or std.mem.endsWith(u8, name, ".Target.Query") or std.mem.eql(u8, name, "Query")) {
        return switch (field_index) {
            0 => 328, // cpu_arch: ?Target.Cpu.Arch
            1 => 0, // cpu_model: CpuModel
            2 => 16, // cpu_features_add: Target.Cpu.Feature.Set
            3 => 64, // cpu_features_sub: Target.Cpu.Feature.Set
            4 => 330, // os_tag: ?Target.Os.Tag
            5 => 112, // os_version_min: ?OsVersion
            6 => 184, // os_version_max: ?OsVersion
            7 => 256, // glibc_version: ?SemanticVersion
            8 => 320, // android_api_level: ?u32
            9 => 332, // abi: ?Target.Abi
            10 => 334, // ofmt: ?Target.ObjectFormat
            11 => 336, // dynamic_linker: ?Target.DynamicLinker
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "SemanticVersion") or std.mem.eql(u8, name, "std.SemanticVersion") or std.mem.endsWith(u8, name, ".SemanticVersion")) {
        return switch (field_index) {
            0 => 0, // major: usize
            1 => 8, // minor: usize
            2 => 16, // patch: usize
            3 => 24, // pre: ?[]const u8
            4 => 40, // build: ?[]const u8
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "link.Elf.Atom") or std.mem.endsWith(u8, name, ".Atom") or std.mem.eql(u8, name, "Atom")) {
        return switch (field_index) {
            0 => 0, // value: i64
            1 => 16, // name_offset: u32
            2 => 20, // file_index: u32
            3 => 8, // size: u64
            4 => 60, // alignment: Alignment (u6)
            5 => 24, // input_section_index: u32
            6 => 28, // output_section_index: u32
            7 => 32, // relocs_section_index: u32
            8 => 36, // atom_index: Index (u32)
            9 => 40, // prev_atom_ref: Ref
            10 => 48, // next_atom_ref: Ref
            11 => 61, // alive: bool
            12 => 62, // visited: bool
            13 => 56, // extra_index: u32
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "link.Elf.Ref") or std.mem.endsWith(u8, name, ".Ref") or std.mem.eql(u8, name, "Ref")) {
        return switch (field_index) {
            0 => 0, // index: u32
            1 => 4, // file: u32
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "elf.Elf64.Phdr") or
        std.mem.eql(u8, name, "Elf64.Phdr") or
        std.mem.endsWith(u8, name, ".Elf64.Phdr") or
        std.mem.eql(u8, name, "Phdr") or
        std.mem.endsWith(u8, name, ".Phdr"))
    {
        return switch (field_index) {
            0 => 0, // type: PT
            1 => 4, // flags: PF
            2 => 8, // offset: Elf64.Off
            3 => 16, // vaddr: Elf64.Addr
            4 => 24, // paddr: Elf64.Addr
            5 => 32, // filesz: Xword
            6 => 40, // memsz: Xword
            7 => 48, // align: Xword
            else => null,
        };
    }
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
    if (std.mem.eql(u8, name, "fmt.parse_float.FloatStream") or std.mem.endsWith(u8, name, ".FloatStream") or std.mem.eql(u8, name, "FloatStream")) {
        return switch (field_index) {
            0 => 0, // slice: []const u8
            1 => 16, // offset: usize
            2 => 24, // underscore_count: usize
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "libs.mingw.def.Parser") or std.mem.endsWith(u8, name, ".Parser") or std.mem.eql(u8, name, "Parser")) {
        return switch (field_index) {
            0 => 0, // tokenizer: *Tokenizer
            1 => 8, // diagnostics: *Diagnostics
            2 => 16, // lookahead_tokenizer: Tokenizer
            3 => 64, // machine_type: IMAGE.FILE.MACHINE
            4 => 66, // module_definition_type: ModuleDefinitionType
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "libs.mingw.def.Tokenizer") or std.mem.endsWith(u8, name, ".Tokenizer") or std.mem.eql(u8, name, "Tokenizer")) {
        return switch (field_index) {
            0 => 0, // source: [:0]const u8
            1 => 16, // index: usize
            2 => 24, // error_context_token: ?Token
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "array_hash_map.IndexHeader") or std.mem.endsWith(u8, name, ".IndexHeader") or std.mem.eql(u8, name, "IndexHeader")) {
        return switch (field_index) {
            0 => 0, // bit_index: u8
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "InternPool.Key.ArrayType") or std.mem.endsWith(u8, name, ".Key.ArrayType") or std.mem.eql(u8, name, "ArrayType")) {
        return switch (field_index) {
            0 => 0, // len: u64
            1 => 8, // child: Index
            2 => 12, // sentinel: Index
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Progress.Node.Storage") or std.mem.endsWith(u8, name, ".Progress.Node.Storage") or std.mem.eql(u8, name, "Storage")) {
        return switch (field_index) {
            0 => 0, // completed_count: u32
            1 => 4, // estimated_total_count: u32
            2 => 8, // name: [120]u8
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "InternPool.PtrBase") or std.mem.endsWith(u8, name, ".PtrBase") or std.mem.eql(u8, name, "PtrBase") or
        std.mem.eql(u8, name, "InternPool.PtrComptimeAlloc") or std.mem.endsWith(u8, name, ".PtrComptimeAlloc") or std.mem.eql(u8, name, "PtrComptimeAlloc") or
        std.mem.eql(u8, name, "InternPool.PtrComptimeField") or std.mem.endsWith(u8, name, ".PtrComptimeField") or std.mem.eql(u8, name, "PtrComptimeField") or
        std.mem.eql(u8, name, "InternPool.PtrNav") or std.mem.endsWith(u8, name, ".PtrNav") or std.mem.eql(u8, name, "PtrNav") or
        std.mem.eql(u8, name, "InternPool.PtrUav") or std.mem.endsWith(u8, name, ".PtrUav") or std.mem.eql(u8, name, "PtrUav"))
    {
        return switch (field_index) {
            0 => 0, // ty: Index
            1 => 4, // base/index/field_val/nav/val
            2 => 8, // byte_offset_a: u32
            3 => 12, // byte_offset_b: u32
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "InternPool.PtrBaseIndex") or std.mem.endsWith(u8, name, ".PtrBaseIndex") or std.mem.eql(u8, name, "PtrBaseIndex") or
        std.mem.eql(u8, name, "InternPool.PtrUavAligned") or std.mem.endsWith(u8, name, ".PtrUavAligned") or std.mem.eql(u8, name, "PtrUavAligned"))
    {
        return switch (field_index) {
            0 => 0, // ty: Index
            1 => 4, // base/val
            2 => 8, // index/orig_ty
            3 => 12, // byte_offset_a: u32
            4 => 16, // byte_offset_b: u32
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "InternPool.PtrInt") or std.mem.endsWith(u8, name, ".PtrInt") or std.mem.eql(u8, name, "PtrInt")) {
        return switch (field_index) {
            0 => 0, // ty: Index
            1 => 4, // byte_offset_a: u32
            2 => 8, // byte_offset_b: u32
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "link.MachO.Relocation") or std.mem.endsWith(u8, name, ".link.MachO.Relocation") or std.mem.eql(u8, name, "Relocation") or std.mem.endsWith(u8, name, ".Relocation")) {
        return switch (field_index) {
            0 => 0, // tag: Tag
            1 => 4, // offset: u32
            2 => 8, // target: u32
            3 => 16, // addend: i64
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "link.File") or std.mem.endsWith(u8, name, ".link.File") or std.mem.eql(u8, name, "File") or std.mem.endsWith(u8, name, ".File")) {
        return switch (field_index) {
            1 => 8, // comp: *Compilation
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Compilation") or std.mem.endsWith(u8, name, ".Compilation")) {
        return switch (field_index) {
            7 => 88, // root_mod: *Module
            8 => 96, // config: Config
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Compilation.Config") or std.mem.endsWith(u8, name, ".Compilation.Config") or std.mem.eql(u8, name, "Config") or std.mem.endsWith(u8, name, ".Config")) {
        return switch (field_index) {
            0 => 0, // have_zcu: bool
            1 => 1, // output_mode: OutputMode
            2 => 2, // link_mode: LinkMode
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Progress") or std.mem.endsWith(u8, name, ".Progress")) {
        return switch (field_index) {
            9 => 17884, // rows: u16
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Sema") or std.mem.endsWith(u8, name, ".Sema")) {
        return switch (field_index) {
            0 => 0, // pt: Zcu.PerThread
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Zcu.PerThread") or std.mem.endsWith(u8, name, ".Zcu.PerThread") or std.mem.endsWith(u8, name, ".PerThread")) {
        return switch (field_index) {
            0 => 0, // zcu: *Zcu
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "print_value.FormatContext") or std.mem.endsWith(u8, name, ".FormatContext") or std.mem.eql(u8, name, "FormatContext")) {
        return switch (field_index) {
            0 => 0, // val: Value
            1 => 8, // zcu: *Zcu
            2 => 16, // opt_sema: ?*Sema
            3 => 24, // depth: u8
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Sema.Block") or std.mem.endsWith(u8, name, ".Sema.Block") or std.mem.eql(u8, name, "Block") or std.mem.endsWith(u8, name, ".Block")) {
        return switch (field_index) {
            17 => if (active_mode) |m| (if (std.mem.eql(u8, m, "ReleaseSafe") or std.mem.eql(u8, m, "safe")) @as(u64, 256) else @as(u64, 248)) else 248, // src_baseline: Baseline
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Zcu.LazySrcLoc") or std.mem.endsWith(u8, name, ".LazySrcLoc") or std.mem.eql(u8, name, "LazySrcLoc")) {
        return switch (field_index) {
            0 => 16, // baseline: Baseline
            1 => 0, // offset: Offset
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Zcu.LazySrcLoc.Baseline") or std.mem.endsWith(u8, name, ".LazySrcLoc.Baseline") or std.mem.eql(u8, name, "Baseline")) {
        return switch (field_index) {
            0 => 0, // inst: TrackedInst.Index
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Zcu") or std.mem.endsWith(u8, name, ".Zcu")) {
        return switch (field_index) {
            3 => 32, // root_mod: *Module
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Module") or std.mem.endsWith(u8, name, ".Module")) {
        return switch (field_index) {
            4 => 96, // resolved_target: ResolvedTarget
            11 => 622, // strip: bool
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Module.ResolvedTarget") or std.mem.endsWith(u8, name, ".Module.ResolvedTarget") or std.mem.eql(u8, name, "ResolvedTarget") or std.mem.endsWith(u8, name, ".ResolvedTarget")) {
        return switch (field_index) {
            0 => 0, // result: Target
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "link.Dwarf") or std.mem.endsWith(u8, name, ".link.Dwarf") or std.mem.eql(u8, name, "Dwarf") or std.mem.endsWith(u8, name, ".Dwarf")) {
        return switch (field_index) {
            4 => 26, // address_size: AddressSize
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "link.MachO") or std.mem.endsWith(u8, name, ".link.MachO") or std.mem.eql(u8, name, "MachO") or std.mem.endsWith(u8, name, ".MachO")) {
        return switch (field_index) {
            3 => 72, // d_sym: ?DebugSymbols
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
    if (std.mem.eql(u8, name, "Io.LockedStderr") or std.mem.endsWith(u8, name, ".Io.LockedStderr") or std.mem.eql(u8, name, "LockedStderr") or std.mem.endsWith(u8, name, ".LockedStderr")) {
        return switch (field_index) {
            0 => 0, // file_writer: *File.Writer
            1 => 8, // terminal_mode: Terminal.Mode
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Io.Terminal") or std.mem.endsWith(u8, name, ".Io.Terminal") or std.mem.eql(u8, name, "Terminal") or std.mem.endsWith(u8, name, ".Terminal")) {
        return switch (field_index) {
            0 => 0, // writer: *Io.Writer
            1 => 8, // mode: Mode
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "crypto.blake3.ChunkState") or std.mem.endsWith(u8, name, ".crypto.blake3.ChunkState") or std.mem.eql(u8, name, "ChunkState") or std.mem.endsWith(u8, name, ".ChunkState")) {
        return switch (field_index) {
            0 => 0, // cv: [8]u32
            1 => 96, // chunk_counter: u64
            2 => 32, // buf: [64]u8
            3 => 104, // buf_len: u8
            4 => 105, // blocks_compressed: u8
            5 => 106, // flags: Flags
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Io.File.Writer") or std.mem.endsWith(u8, name, ".Io.File.Writer") or std.mem.eql(u8, name, "File.Writer") or std.mem.endsWith(u8, name, ".File.Writer")) {
        return switch (field_index) {
            7 => 24, // interface: Io.Writer
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Io.Writer.Allocating") or std.mem.endsWith(u8, name, ".Io.Writer.Allocating")) {
        return switch (field_index) {
            1 => 16, // writer: Writer
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Io.Writer") or std.mem.endsWith(u8, name, ".Io.Writer") or std.mem.eql(u8, name, "Writer") or (std.mem.endsWith(u8, name, ".Writer") and !std.mem.endsWith(u8, name, ".File.Writer"))) {
        return switch (field_index) {
            0 => 0, // vtable: *const VTable
            1 => 8, // buffer: []u8
            2 => 24, // end: usize
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Io.Reader") or std.mem.endsWith(u8, name, ".Io.Reader") or std.mem.eql(u8, name, "Reader") or std.mem.endsWith(u8, name, ".Reader")) {
        return switch (field_index) {
            0 => 0, // vtable: *const VTable
            1 => 8, // buffer: []u8
            2 => 24, // seek: usize
            3 => 32, // end: usize
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Io.Group") or std.mem.endsWith(u8, name, ".Io.Group") or std.mem.eql(u8, name, "Group") or std.mem.endsWith(u8, name, ".Group")) {
        return switch (field_index) {
            0 => 0, // token: std.atomic.Value(?*anyopaque)
            1 => 8, // state: usize
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "Io.Threaded.Group") or std.mem.endsWith(u8, name, ".Io.Threaded.Group")) {
        return switch (field_index) {
            0 => 0, // ptr: *Io.Group
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "codegen.spirv.CodeGen.Temporary") or std.mem.endsWith(u8, name, ".CodeGen.Temporary") or std.mem.endsWith(u8, name, ".Temporary") or std.mem.eql(u8, name, "Temporary")) {
        return switch (field_index) {
            0 => 0, // ty: Type
            1 => 4, // value: Value
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "hash.xxhash.XxHash64.Accumulator") or std.mem.endsWith(u8, name, ".XxHash64.Accumulator") or std.mem.eql(u8, name, "XxHash64.Accumulator") or std.mem.eql(u8, name, "Accumulator")) {
        return switch (field_index) {
            0 => 0,
            1 => 8,
            2 => 16,
            3 => 24,
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "zig.llvm.Builder.Metadata.CompositeType") or std.mem.endsWith(u8, name, ".CompositeType") or std.mem.eql(u8, name, "CompositeType")) {
        return switch (field_index) {
            0...9 => field_index * 4,
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "zig.llvm.Builder.Metadata.DerivedType") or std.mem.endsWith(u8, name, ".DerivedType") or std.mem.eql(u8, name, "DerivedType")) {
        return switch (field_index) {
            0...10 => field_index * 4,
            else => null,
        };
    }
    if (std.mem.startsWith(u8, name, "fmt.Alt(") or std.mem.startsWith(u8, name, "std.fmt.Alt(")) {
        return switch (field_index) {
            0 => 0,
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "zig.llvm.Builder.Value.FormatData") or std.mem.endsWith(u8, name, ".Value.FormatData") or std.mem.eql(u8, name, "Value.FormatData")) {
        return switch (field_index) {
            0 => 0,
            1 => 4,
            2 => 8,
            3 => 16,
            else => null,
        };
    }
    if (std.mem.eql(u8, name, "InternPool.Float64") or std.mem.endsWith(u8, name, ".Float64") or std.mem.eql(u8, name, "Float64")) {
        return switch (field_index) {
            0 => 0,
            1 => 4,
            else => null,
        };
    }
    return null;
}

pub fn nominalTypeByteSize(nominal_name: []const u8) ?u64 {
    const trimmed = stripNominalSigil(std.mem.trim(u8, nominal_name, " "));
    if (std.mem.eql(u8, trimmed, "hash.xxhash.XxHash64.Accumulator") or std.mem.endsWith(u8, trimmed, ".XxHash64.Accumulator") or std.mem.eql(u8, trimmed, "XxHash64.Accumulator") or std.mem.eql(u8, trimmed, "Accumulator")) {
        return 32;
    }
    if (std.mem.eql(u8, trimmed, "link.MachO.Relocation") or std.mem.endsWith(u8, trimmed, ".link.MachO.Relocation") or std.mem.eql(u8, trimmed, "Relocation") or std.mem.endsWith(u8, trimmed, ".Relocation")) {
        return 32;
    }
    if (std.mem.eql(u8, trimmed, "link.MachO.DebugSymbols") or std.mem.endsWith(u8, trimmed, ".link.MachO.DebugSymbols") or std.mem.eql(u8, trimmed, "DebugSymbols") or std.mem.endsWith(u8, trimmed, ".DebugSymbols")) {
        return 272;
    }
    if (std.mem.eql(u8, trimmed, "codegen.spirv.CodeGen.Temporary.Value") or std.mem.endsWith(u8, trimmed, ".CodeGen.Temporary.Value") or std.mem.endsWith(u8, trimmed, ".Temporary.Value")) {
        return 12;
    }
    if (std.mem.eql(u8, trimmed, "codegen.spirv.CodeGen.Temporary") or std.mem.endsWith(u8, trimmed, ".CodeGen.Temporary") or std.mem.endsWith(u8, trimmed, ".Temporary") or std.mem.eql(u8, trimmed, "Temporary")) {
        return 16;
    }
    if (std.mem.eql(u8, trimmed, "print_value.FormatContext") or std.mem.endsWith(u8, trimmed, ".FormatContext") or std.mem.eql(u8, trimmed, "FormatContext")) {
        return 32;
    }
    if (std.mem.eql(u8, trimmed, "zig.llvm.Builder.Metadata.CompositeType") or std.mem.endsWith(u8, trimmed, ".CompositeType") or std.mem.eql(u8, trimmed, "CompositeType")) {
        return 40;
    }
    if (std.mem.eql(u8, trimmed, "zig.llvm.Builder.Metadata.DerivedType") or std.mem.endsWith(u8, trimmed, ".DerivedType") or std.mem.eql(u8, trimmed, "DerivedType")) {
        return 44;
    }
    if (std.mem.startsWith(u8, trimmed, "fmt.Alt(") or std.mem.startsWith(u8, trimmed, "std.fmt.Alt(")) {
        if (std.mem.indexOf(u8, trimmed, "Value.FormatData") != null) {
            return 24;
        }
    }
    if (std.mem.eql(u8, trimmed, "zig.llvm.Builder.Value.FormatData") or std.mem.endsWith(u8, trimmed, ".Value.FormatData") or std.mem.eql(u8, trimmed, "Value.FormatData")) {
        return 24;
    }
    if (std.mem.eql(u8, trimmed, "InternPool.Float64") or std.mem.endsWith(u8, trimmed, ".Float64") or std.mem.eql(u8, trimmed, "Float64")) {
        return 8;
    }
    if (std.mem.eql(u8, trimmed, "InternPool.PtrInt") or std.mem.endsWith(u8, trimmed, ".PtrInt") or std.mem.eql(u8, trimmed, "PtrInt")) {
        return 12;
    }
    if (std.mem.eql(u8, trimmed, "link.Elf.Atom") or std.mem.endsWith(u8, trimmed, ".Atom") or std.mem.eql(u8, trimmed, "Atom")) {
        return 64;
    }
    if (std.mem.eql(u8, trimmed, "link.Elf.Ref") or std.mem.endsWith(u8, trimmed, ".Ref") or std.mem.eql(u8, trimmed, "Ref")) {
        return 8;
    }
    if (std.mem.eql(u8, trimmed, "elf.Elf64.Phdr") or
        std.mem.eql(u8, trimmed, "Elf64.Phdr") or
        std.mem.endsWith(u8, trimmed, ".Elf64.Phdr") or
        std.mem.eql(u8, trimmed, "Phdr") or
        std.mem.endsWith(u8, trimmed, ".Phdr"))
    {
        return 56;
    }
    if (std.mem.eql(u8, trimmed, "Target.Query") or std.mem.eql(u8, trimmed, "std.Target.Query") or std.mem.endsWith(u8, trimmed, ".Target.Query") or std.mem.eql(u8, trimmed, "Query")) {
        return 600;
    }
    if (std.mem.eql(u8, trimmed, "SemanticVersion") or std.mem.eql(u8, trimmed, "std.SemanticVersion") or std.mem.endsWith(u8, trimmed, ".SemanticVersion")) {
        return 56;
    }
    if (std.mem.eql(u8, trimmed, "Target.Os.Tag") or std.mem.eql(u8, trimmed, "std.Target.Os.Tag") or std.mem.endsWith(u8, trimmed, ".Target.Os.Tag") or
        std.mem.eql(u8, trimmed, "Target.Abi") or std.mem.eql(u8, trimmed, "std.Target.Abi") or std.mem.endsWith(u8, trimmed, ".Target.Abi") or
        std.mem.eql(u8, trimmed, "Target.ObjectFormat") or std.mem.eql(u8, trimmed, "std.Target.ObjectFormat") or std.mem.endsWith(u8, trimmed, ".Target.ObjectFormat"))
    {
        return 1;
    }
    if (std.mem.eql(u8, trimmed, "Io.LockedStderr") or std.mem.endsWith(u8, trimmed, ".LockedStderr") or std.mem.eql(u8, trimmed, "LockedStderr")) {
        return 16;
    }
    if (std.mem.eql(u8, trimmed, "Io.Terminal") or std.mem.endsWith(u8, trimmed, ".Terminal") or std.mem.eql(u8, trimmed, "Terminal")) {
        return 16;
    }
    if (std.mem.eql(u8, trimmed, "Io.Terminal.Mode") or std.mem.endsWith(u8, trimmed, ".Terminal.Mode") or std.mem.eql(u8, trimmed, "Terminal.Mode") or std.mem.eql(u8, trimmed, "Mode")) {
        return 1;
    }
    if (std.mem.eql(u8, trimmed, "Io.File.Writer") or std.mem.endsWith(u8, trimmed, ".File.Writer") or std.mem.eql(u8, trimmed, "File.Writer")) {
        return 72;
    }
    if (std.mem.eql(u8, trimmed, "crypto.blake3.ChunkState") or std.mem.endsWith(u8, trimmed, ".ChunkState") or std.mem.eql(u8, trimmed, "ChunkState")) {
        return 112;
    }
    return null;
}

pub fn optionalPayloadByteSize(type_text: []const u8) ?u64 {
    const trimmed = std.mem.trim(u8, type_text, " ");
    const name = if (std.mem.startsWith(u8, trimmed, "?"))
        std.mem.trim(u8, trimmed[1..], " ")
    else
        trimmed;
    if (name.len == 0) return null;
    if (name[0] == '*' or std.mem.startsWith(u8, name, "[*]")) return null;
    if (nominalTypeByteSize(name)) |sz| return sz;
    if (std.mem.eql(u8, name, "bool")) return 1;
    if (name.len > 1 and (name[0] == 'u' or name[0] == 'i')) {
        const bits = std.fmt.parseInt(u16, name[1..], 10) catch return null;
        if (bits == 0) return 0;
        return (bits + 7) / 8;
    }
    if (enum_facts.lookup(name)) |fact| {
        if (fact.backing_type == .int) {
            return (fact.backing_type.int + 7) / 8;
        }
    }
    return null;
}

test "aggregate layout facts keep exact pair ownership narrow" {
    try std.testing.expectEqual(@as(usize, 37), count());
    try std.testing.expect(lookup("aggregate_abi.Pair") == null);
    try std.testing.expect(lookup("%runtime_aggregate_pair_main.Pair") == null);
    try std.testing.expect(lookup("other.Pair") == null);
    try std.testing.expect(lookup("codegen.wasm.Mir.Imm64") != null);
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
    try std.testing.expect(lookup("hash.xxhash.XxHash64.Accumulator") != null);
    try std.testing.expect(lookup("XxHash64.Accumulator") != null);
    try std.testing.expect(lookup("zig.llvm.Builder.Metadata.CompositeType") != null);
    try std.testing.expect(lookup("CompositeType") != null);
    try std.testing.expect(lookup("zig.llvm.Builder.Metadata.DerivedType") != null);
    try std.testing.expect(lookup("DerivedType") != null);
    try std.testing.expect(lookup("zig.llvm.Builder.Value.FormatData") != null);
    try std.testing.expect(lookup("Value.FormatData") != null);
    try std.testing.expect(lookup("InternPool.Float64") != null);
    try std.testing.expect(lookup("Float64") != null);
    try std.testing.expect(lookup("InternPool.PtrInt") != null);
    try std.testing.expect(lookup("PtrInt") != null);
    try std.testing.expect(lookup("Io.LockedStderr") != null);
    try std.testing.expect(lookup("LockedStderr") != null);
    try std.testing.expect(lookup("Io.Terminal") != null);
    try std.testing.expect(lookup("Terminal") != null);
    try std.testing.expect(lookup("crypto.blake3.ChunkState") != null);
    try std.testing.expect(lookup("ChunkState") != null);
    try std.testing.expect(lookup("elf.Elf64.Phdr") != null);
    try std.testing.expect(lookup("Elf64.Phdr") != null);
    try std.testing.expect(lookup("Phdr") != null);
}

test "nominal layout facts link.MachO and DebugSymbols" {
    try std.testing.expectEqual(@as(?u64, 72), nominalFieldByteOffset("link.MachO", 3));
    try std.testing.expectEqual(@as(?u64, 272), nominalTypeByteSize("link.MachO.DebugSymbols"));
    try std.testing.expectEqual(@as(?u64, 272), optionalPayloadByteSize("?link.MachO.DebugSymbols"));
    try std.testing.expectEqual(@as(?u64, 0), nominalFieldByteOffset("Io.LockedStderr", 0));
    try std.testing.expectEqual(@as(?u64, 8), nominalFieldByteOffset("Io.LockedStderr", 1));
    try std.testing.expectEqual(@as(?u64, 0), nominalFieldByteOffset("Io.Terminal", 0));
    try std.testing.expectEqual(@as(?u64, 8), nominalFieldByteOffset("Io.Terminal", 1));
    try std.testing.expectEqual(@as(?u64, 24), nominalFieldByteOffset("Io.File.Writer", 7));
    try std.testing.expectEqual(@as(?u64, 16), nominalTypeByteSize("Io.LockedStderr"));
    try std.testing.expectEqual(@as(?u64, 16), nominalTypeByteSize("Io.Terminal"));
    try std.testing.expectEqual(@as(?u64, 1), nominalTypeByteSize("Io.Terminal.Mode"));
    try std.testing.expectEqual(@as(?u64, 72), nominalTypeByteSize("Io.File.Writer"));
    try std.testing.expectEqual(@as(?u64, 0), nominalFieldByteOffset("crypto.blake3.ChunkState", 0));
    try std.testing.expectEqual(@as(?u64, 96), nominalFieldByteOffset("crypto.blake3.ChunkState", 1));
    try std.testing.expectEqual(@as(?u64, 32), nominalFieldByteOffset("crypto.blake3.ChunkState", 2));
    try std.testing.expectEqual(@as(?u64, 104), nominalFieldByteOffset("crypto.blake3.ChunkState", 3));
    try std.testing.expectEqual(@as(?u64, 105), nominalFieldByteOffset("crypto.blake3.ChunkState", 4));
    try std.testing.expectEqual(@as(?u64, 106), nominalFieldByteOffset("crypto.blake3.ChunkState", 5));
    try std.testing.expectEqual(@as(?u64, 112), nominalTypeByteSize("crypto.blake3.ChunkState"));
    try std.testing.expectEqual(@as(?u64, 0), nominalFieldByteOffset("elf.Elf64.Phdr", 0));
    try std.testing.expectEqual(@as(?u64, 4), nominalFieldByteOffset("elf.Elf64.Phdr", 1));
    try std.testing.expectEqual(@as(?u64, 8), nominalFieldByteOffset("elf.Elf64.Phdr", 2));
    try std.testing.expectEqual(@as(?u64, 56), nominalTypeByteSize("elf.Elf64.Phdr"));
}
