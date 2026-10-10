const std = @import("std");
const ir = @import("ir.zig");

pub const Enumerator = struct {
    name: []const u8,
    value: i128,
};

pub const Fact = struct {
    name: []const u8,
    backing_type: ir.Type,
    signed: bool = false,
    enumerators: []const Enumerator,
};

const io_event_enumerators = [_]Enumerator{
    .{ .name = "unset", .value = 0 },
    .{ .name = "waiting", .value = 1 },
    .{ .name = "is_set", .value = 2 },
};

const io_limit_enumerators = [_]Enumerator{
    .{ .name = "nothing", .value = 0 },
    .{ .name = "unlimited", .value = std.math.maxInt(u64) },
};

const http_reader_remaining_chunk_len_enumerators = [_]Enumerator{
    .{ .name = "head", .value = 0 },
    .{ .name = "n", .value = 1 },
    .{ .name = "rn", .value = 2 },
};

const zig_ast_optional_token_index_enumerators = [_]Enumerator{
    .{ .name = "none", .value = std.math.maxInt(u32) },
};

const intern_pool_index_enumerators = [_]Enumerator{
    .{ .name = "none", .value = std.math.maxInt(u32) },
};

const intern_pool_anal_unit_optional_enumerators = [_]Enumerator{
    .{ .name = "none", .value = std.math.maxInt(u64) },
};

const elf_program_header_index_enumerators = [_]Enumerator{
    .{ .name = "none", .value = std.math.maxInt(u16) },
};

const ast_node_optional_offset_enumerators = [_]Enumerator{
    .{ .name = "none", .value = std.math.maxInt(i32) },
};

const coff_image_file_machine_enumerators = [_]Enumerator{
    .{ .name = "UNKNOWN", .value = 0x0 },
    .{ .name = "ALPHA", .value = 0x184 },
    .{ .name = "ALPHA64", .value = 0x284 },
    .{ .name = "AM33", .value = 0x1d3 },
    .{ .name = "AMD64", .value = 0x8664 },
    .{ .name = "ARM", .value = 0x1c0 },
    .{ .name = "ARM64", .value = 0xaa64 },
    .{ .name = "ARM64EC", .value = 0xA641 },
    .{ .name = "ARM64X", .value = 0xA64E },
    .{ .name = "ARMNT", .value = 0x1c4 },
    .{ .name = "EBC", .value = 0xebc },
    .{ .name = "I386", .value = 0x14c },
    .{ .name = "IA64", .value = 0x200 },
    .{ .name = "LOONGARCH32", .value = 0x6232 },
    .{ .name = "LOONGARCH64", .value = 0x6264 },
    .{ .name = "M32R", .value = 0x9041 },
    .{ .name = "MIPS16", .value = 0x266 },
    .{ .name = "MIPSFPU", .value = 0x366 },
    .{ .name = "MIPSFPU16", .value = 0x466 },
    .{ .name = "POWERPC", .value = 0x1f0 },
    .{ .name = "POWERPCFP", .value = 0x1f1 },
    .{ .name = "R3000BE", .value = 0x160 },
    .{ .name = "R3000", .value = 0x162 },
    .{ .name = "R4000", .value = 0x166 },
    .{ .name = "R10000", .value = 0x168 },
    .{ .name = "RISCV32", .value = 0x5032 },
    .{ .name = "RISCV64", .value = 0x5064 },
    .{ .name = "RISCV128", .value = 0x5128 },
    .{ .name = "SH3", .value = 0x1a2 },
    .{ .name = "SH3DSP", .value = 0x1a3 },
    .{ .name = "SH4", .value = 0x1a6 },
    .{ .name = "SH5", .value = 0x1a8 },
    .{ .name = "THUMB", .value = 0x1c2 },
    .{ .name = "WCEMIPSV2", .value = 0x169 },
};

const lang_compiler_backend_enumerators = [_]Enumerator{
    .{ .name = "other", .value = 0 },
    .{ .name = "stage1", .value = 1 },
    .{ .name = "stage2_llvm", .value = 2 },
    .{ .name = "stage2_c", .value = 3 },
    .{ .name = "stage2_wasm", .value = 4 },
    .{ .name = "stage2_arm", .value = 5 },
    .{ .name = "stage2_x86_64", .value = 6 },
    .{ .name = "stage2_aarch64", .value = 7 },
    .{ .name = "stage2_x86", .value = 8 },
    .{ .name = "stage2_riscv64", .value = 9 },
    .{ .name = "stage2_sparc64", .value = 10 },
    .{ .name = "stage2_spirv", .value = 11 },
    .{ .name = "stage2_powerpc", .value = 12 },
    .{ .name = "stage2_loongarch", .value = 13 },
    .{ .name = "zsf_spork8", .value = 14 },
};

const math_order_enumerators = [_]Enumerator{
    .{ .name = "gt", .value = 0 },
    .{ .name = "lt", .value = 1 },
    .{ .name = "eq", .value = 2 },
};

const zig_llvm_builder_alignment_enumerators = [_]Enumerator{
    .{ .name = "default", .value = std.math.maxInt(u6) },
};

const intern_pool_alignment_enumerators = [_]Enumerator{
    .{ .name = "1", .value = 0 },
    .{ .name = "2", .value = 1 },
    .{ .name = "4", .value = 2 },
    .{ .name = "8", .value = 3 },
    .{ .name = "16", .value = 4 },
    .{ .name = "32", .value = 5 },
    .{ .name = "64", .value = 6 },
    .{ .name = "none", .value = std.math.maxInt(u6) },
};

const intern_pool_tracked_inst_maybe_lost_zir_index_enumerators = [_]Enumerator{
    .{ .name = "lost", .value = std.math.maxInt(u32) },
};

const progress_node_parent_enumerators = [_]Enumerator{
    .{ .name = "unused", .value = 254 },
    .{ .name = "none", .value = 255 },
};

const dwarf_address_size_enumerators = [_]Enumerator{
    .{ .name = "32", .value = 4 },
    .{ .name = "64", .value = 8 },
};

const no_enumerators = [_]Enumerator{};

const facts = [_]Fact{
    .{
        .name = "Progress.Node.Parent",
        .backing_type = .{ .int = 8 },
        .enumerators = progress_node_parent_enumerators[0..],
    },
    .{
        .name = "std.Progress.Node.Parent",
        .backing_type = .{ .int = 8 },
        .enumerators = progress_node_parent_enumerators[0..],
    },
    .{
        .name = "math.Order",
        .backing_type = .{ .int = 8 },
        .enumerators = math_order_enumerators[0..],
    },
    .{
        .name = "std.math.Order",
        .backing_type = .{ .int = 8 },
        .enumerators = math_order_enumerators[0..],
    },
    .{
        .name = "Io.Event",
        .backing_type = .{ .int = 32 },
        .enumerators = io_event_enumerators[0..],
    },
    .{
        .name = "Io.Limit",
        .backing_type = .{ .int = 64 },
        .enumerators = io_limit_enumerators[0..],
    },
    .{
        .name = "http.Reader.RemainingChunkLen",
        .backing_type = .{ .int = 64 },
        .enumerators = http_reader_remaining_chunk_len_enumerators[0..],
    },
    .{
        .name = "zig.Ast.OptionalTokenIndex",
        .backing_type = .{ .int = 32 },
        .enumerators = zig_ast_optional_token_index_enumerators[0..],
    },
    .{
        .name = "InternPool.AnalUnit.Optional",
        .backing_type = .{ .int = 64 },
        .enumerators = intern_pool_anal_unit_optional_enumerators[0..],
    },
    .{
        .name = "coff.IMAGE.FILE.MACHINE",
        .backing_type = .{ .int = 16 },
        .enumerators = coff_image_file_machine_enumerators[0..],
    },
    .{
        .name = "std.coff.IMAGE.FILE.MACHINE",
        .backing_type = .{ .int = 16 },
        .enumerators = coff_image_file_machine_enumerators[0..],
    },
    .{
        .name = "Air.ShuffleTwoMask",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "link.File.LazySymbol.Kind",
        .backing_type = .{ .int = 1 },
        .enumerators = lazy_symbol_kind_enumerators[0..],
    },
    .{
        .name = "LazySymbol.Kind",
        .backing_type = .{ .int = 1 },
        .enumerators = lazy_symbol_kind_enumerators[0..],
    },
    .{
        .name = "link.Wasm.String",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "link.Wasm.DataPayload.Off",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "Wasm.DataPayload.Off",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "zig.llvm.Builder.Linkage",
        .backing_type = .{ .int = 8 },
        .enumerators = zig_llvm_builder_linkage_enumerators[0..],
    },
    .{
        .name = "std.zig.llvm.Builder.Linkage",
        .backing_type = .{ .int = 8 },
        .enumerators = zig_llvm_builder_linkage_enumerators[0..],
    },
    .{
        .name = "InternPool.NullTerminatedString",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "InternPool.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "std.zig.InternPool.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "zig.llvm.Builder.Type",
        .backing_type = .{ .int = 32 },
        .enumerators = zig_llvm_builder_type_enumerators[0..],
    },
    .{
        .name = "std.zig.llvm.Builder.Type",
        .backing_type = .{ .int = 32 },
        .enumerators = zig_llvm_builder_type_enumerators[0..],
    },
    .{
        .name = "zig.llvm.Builder.Attributes",
        .backing_type = .{ .int = 32 },
        .enumerators = zig_llvm_builder_attributes_enumerators[0..],
    },
    .{
        .name = "std.zig.llvm.Builder.Attributes",
        .backing_type = .{ .int = 32 },
        .enumerators = zig_llvm_builder_attributes_enumerators[0..],
    },
    .{
        .name = "zig.llvm.Builder.Constant",
        .backing_type = .{ .int = 32 },
        .enumerators = zig_llvm_builder_constant_enumerators[0..],
    },
    .{
        .name = "std.zig.llvm.Builder.Constant",
        .backing_type = .{ .int = 32 },
        .enumerators = zig_llvm_builder_constant_enumerators[0..],
    },
    .{
        .name = "codegen.aarch64.Select.Value.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = select_value_index_enumerators[0..],
    },
    .{
        .name = "Select.Value.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = select_value_index_enumerators[0..],
    },
    .{
        .name = "codegen.aarch64.encoding.Register.Alias",
        .backing_type = .{ .int = 7 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "Register.Alias",
        .backing_type = .{ .int = 7 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "libs.freebsd.CrtFile",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "libs.netbsd.CrtFile",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "libs.openbsd.CrtFile",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "libs.mingw.CrtFile",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "libs.musl.CrtFile",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "lang.CompilerBackend",
        .backing_type = .{ .int = 64 },
        .enumerators = lang_compiler_backend_enumerators[0..],
    },
    .{
        .name = "std.lang.CompilerBackend",
        .backing_type = .{ .int = 64 },
        .enumerators = lang_compiler_backend_enumerators[0..],
    },
    .{
        .name = "Sema.RuntimeIndex",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "std.zig.Sema.RuntimeIndex",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },

    .{
        .name = "InternPool.GlobalErrorSet.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "zig.llvm.Builder.Global.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "std.zig.llvm.Builder.Global.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "zig.llvm.Builder.Metadata.String",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "std.zig.llvm.Builder.Metadata.String",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "zig.llvm.Builder.Metadata.String.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "std.zig.llvm.Builder.Metadata.String.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "zig.llvm.Builder.String",
        .backing_type = .{ .int = 32 },
        .enumerators = zig_llvm_builder_string_enumerators[0..],
    },
    .{
        .name = "std.zig.llvm.Builder.String",
        .backing_type = .{ .int = 32 },
        .enumerators = zig_llvm_builder_string_enumerators[0..],
    },
    .{
        .name = "zig.llvm.Builder.QuoteBehavior",
        .backing_type = .{ .int = 8 },
        .enumerators = zig_llvm_builder_quote_behavior_enumerators[0..],
    },
    .{
        .name = "std.zig.llvm.Builder.QuoteBehavior",
        .backing_type = .{ .int = 8 },
        .enumerators = zig_llvm_builder_quote_behavior_enumerators[0..],
    },
    .{
        .name = "?zig.llvm.Builder.QuoteBehavior",
        .backing_type = .{ .int = 8 },
        .enumerators = zig_llvm_builder_quote_behavior_enumerators[0..],
    },
    .{
        .name = "?std.zig.llvm.Builder.QuoteBehavior",
        .backing_type = .{ .int = 8 },
        .enumerators = zig_llvm_builder_quote_behavior_enumerators[0..],
    },
    .{
        .name = "InternPool.OptionalNullTerminatedString",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "InternPool.TrackedInst.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "std.zig.InternPool.TrackedInst.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "InternPool.TrackedInst.Index.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "std.zig.InternPool.TrackedInst.Index.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "InternPool.DepEntry.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "std.zig.InternPool.DepEntry.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "InternPool.DepEntry.Index.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "std.zig.InternPool.DepEntry.Index.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "InternPool.FileIndex",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "std.zig.InternPool.FileIndex",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "InternPool.FileIndex.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "std.zig.InternPool.FileIndex.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "InternPool.Nav.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "std.zig.InternPool.Nav.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "InternPool.Nav.Index.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "std.zig.InternPool.Nav.Index.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "InternPool.TrackedInst.MaybeLost.ZirIndex",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_tracked_inst_maybe_lost_zir_index_enumerators[0..],
    },
    .{
        .name = "std.zig.InternPool.TrackedInst.MaybeLost.ZirIndex",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_tracked_inst_maybe_lost_zir_index_enumerators[0..],
    },
    .{
        .name = "zig.Zir.Inst.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "std.zig.Zir.Inst.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "Zir.Inst.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "Zcu.CompileLogLine.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "std.zig.Zcu.CompileLogLine.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "Zcu.CompileLogLine.Index.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "std.zig.Zcu.CompileLogLine.Index.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "Zcu.InlineReferenceFrame.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "std.zig.Zcu.InlineReferenceFrame.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "Zcu.InlineReferenceFrame.Index.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "std.zig.Zcu.InlineReferenceFrame.Index.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "link.ConstPool.ContainerDepEntry.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "link.ConstPool.ContainerDepEntry.Index.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "ConstPool.ContainerDepEntry.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "ConstPool.ContainerDepEntry.Index.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "link.Coff.String",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "link.Coff.String.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "Coff.String",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "Coff.String.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "link.Dwarf.AddressSize",
        .backing_type = .{ .int = 8 },
        .enumerators = dwarf_address_size_enumerators[0..],
    },
    .{
        .name = "Dwarf.AddressSize",
        .backing_type = .{ .int = 8 },
        .enumerators = dwarf_address_size_enumerators[0..],
    },
    .{
        .name = "link.Dwarf.Entry.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "link.Dwarf.Entry.Index.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "Dwarf.Entry.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "Dwarf.Entry.Index.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "link.Dwarf.Unit.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "link.Dwarf.Unit.Index.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "Dwarf.Unit.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "Dwarf.Unit.Index.Optional",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "link.Elf.ProgramHeaderIndex",
        .backing_type = .{ .int = 16 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "link.Elf.OptionalProgramHeaderIndex",
        .backing_type = .{ .int = 16 },
        .enumerators = elf_program_header_index_enumerators[0..],
    },
    .{
        .name = "Elf.ProgramHeaderIndex",
        .backing_type = .{ .int = 16 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "Elf.OptionalProgramHeaderIndex",
        .backing_type = .{ .int = 16 },
        .enumerators = elf_program_header_index_enumerators[0..],
    },
    .{
        .name = "zig.Ast.Node.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "Ast.Node.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "std.zig.Ast.Node.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "zig.Ast.Node.OptionalIndex",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "Ast.Node.OptionalIndex",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "std.zig.Ast.Node.OptionalIndex",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "zig.Ast.Node.Offset",
        .backing_type = .{ .int = 32 },
        .signed = true,
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "Ast.Node.Offset",
        .backing_type = .{ .int = 32 },
        .signed = true,
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "std.zig.Ast.Node.Offset",
        .backing_type = .{ .int = 32 },
        .signed = true,
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "zig.Ast.Node.OptionalOffset",
        .backing_type = .{ .int = 32 },
        .signed = true,
        .enumerators = ast_node_optional_offset_enumerators[0..],
    },
    .{
        .name = "Ast.Node.OptionalOffset",
        .backing_type = .{ .int = 32 },
        .signed = true,
        .enumerators = ast_node_optional_offset_enumerators[0..],
    },
    .{
        .name = "std.zig.Ast.Node.OptionalOffset",
        .backing_type = .{ .int = 32 },
        .signed = true,
        .enumerators = ast_node_optional_offset_enumerators[0..],
    },
    .{
        .name = "zig.Zir.Inst.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "Zir.Inst.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "std.zig.Zir.Inst.Index",
        .backing_type = .{ .int = 32 },
        .enumerators = no_enumerators[0..],
    },
    .{
        .name = "zig.Zir.Inst.OptionalIndex",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "Zir.Inst.OptionalIndex",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "std.zig.Zir.Inst.OptionalIndex",
        .backing_type = .{ .int = 32 },
        .enumerators = intern_pool_index_enumerators[0..],
    },
    .{
        .name = "zig.llvm.Builder.Alignment",
        .backing_type = .{ .int = 6 },
        .enumerators = zig_llvm_builder_alignment_enumerators[0..],
    },
    .{
        .name = "std.zig.llvm.Builder.Alignment",
        .backing_type = .{ .int = 6 },
        .enumerators = zig_llvm_builder_alignment_enumerators[0..],
    },
    .{
        .name = "InternPool.Alignment",
        .backing_type = .{ .int = 6 },
        .enumerators = intern_pool_alignment_enumerators[0..],
    },
    .{
        .name = "std.zig.InternPool.Alignment",
        .backing_type = .{ .int = 6 },
        .enumerators = intern_pool_alignment_enumerators[0..],
    },
    .{
        .name = "compress.zstd.Decompress.Frame.Magic",
        .backing_type = .{ .int = 32 },
        .enumerators = compress_zstd_magic_enumerators[0..],
    },
    .{
        .name = "compress.zstd.Decompress.Frame.Kind",
        .backing_type = .{ .int = 8 },
        .enumerators = compress_zstd_kind_enumerators[0..],
    },
    .{
        .name = "?compress.zstd.Decompress.Frame.Kind",
        .backing_type = .{ .int = 8 },
        .enumerators = compress_zstd_kind_enumerators[0..],
    },
};

const compress_zstd_magic_enumerators = [_]Enumerator{
    .{ .name = "zstandard", .value = 4247762216 },
};

const compress_zstd_kind_enumerators = [_]Enumerator{
    .{ .name = "zstandard", .value = 0 },
    .{ .name = "skippable", .value = 1 },
    .{ .name = "null", .value = 2 },
};

const select_value_index_enumerators = [_]Enumerator{
    .{ .name = "allocating", .value = std.math.maxInt(u32) - 1 },
    .{ .name = "free", .value = std.math.maxInt(u32) },
};

const lazy_symbol_kind_enumerators = [_]Enumerator{
    .{ .name = "code", .value = 0 },
    .{ .name = "const_data", .value = 1 },
};

const zig_llvm_builder_type_enumerators = [_]Enumerator{
    .{ .name = "void", .value = 0 },
    .{ .name = "half", .value = 1 },
    .{ .name = "bfloat", .value = 2 },
    .{ .name = "float", .value = 3 },
    .{ .name = "double", .value = 4 },
    .{ .name = "fp128", .value = 5 },
    .{ .name = "x86_fp80", .value = 6 },
    .{ .name = "ppc_fp128", .value = 7 },
    .{ .name = "x86_amx", .value = 8 },
    .{ .name = "x86_mmx", .value = 9 },
    .{ .name = "label", .value = 10 },
    .{ .name = "token", .value = 11 },
    .{ .name = "metadata", .value = 12 },
    .{ .name = "i1", .value = 13 },
    .{ .name = "i8", .value = 14 },
    .{ .name = "i16", .value = 15 },
    .{ .name = "i29", .value = 16 },
    .{ .name = "i32", .value = 17 },
    .{ .name = "i64", .value = 18 },
    .{ .name = "i80", .value = 19 },
    .{ .name = "i128", .value = 20 },
    .{ .name = "ptr", .value = 21 },
};

const zig_llvm_builder_linkage_enumerators = [_]Enumerator{
    .{ .name = "external", .value = 0 },
    .{ .name = "weak", .value = 1 },
    .{ .name = "appending", .value = 2 },
    .{ .name = "internal", .value = 3 },
    .{ .name = "linkonce", .value = 4 },
    .{ .name = "extern_weak", .value = 7 },
    .{ .name = "common", .value = 8 },
    .{ .name = "private", .value = 9 },
    .{ .name = "weak_odr", .value = 10 },
    .{ .name = "linkonce_odr", .value = 11 },
    .{ .name = "available_externally", .value = 12 },
};

const shuffle_one_mask_kind_enumerators = [_]Enumerator{
    .{ .name = "elem", .value = 0 },
    .{ .name = "value", .value = 1 },
};

const ctype_formatter_kind_enumerators = [_]Enumerator{
    .{ .name = "type_name", .value = 0 },
    .{ .name = "declarator_prefix", .value = 1 },
    .{ .name = "declarator_suffix", .value = 2 },
    .{ .name = "declarator_suffix_ignore_nonstring", .value = 3 },
};

const zig_llvm_builder_string_enumerators = [_]Enumerator{
    .{ .name = "none", .value = std.math.maxInt(u31) },
    .{ .name = "empty", .value = std.math.maxInt(u31) + 1 },
};

const zig_llvm_builder_quote_behavior_enumerators = [_]Enumerator{
    .{ .name = "always_quote", .value = 0 },
    .{ .name = "quote_unless_valid_identifier", .value = 1 },
    .{ .name = "null", .value = 2 },
};

const zig_llvm_builder_attributes_enumerators = [_]Enumerator{
    .{ .name = "none", .value = 0 },
};

const zig_llvm_builder_constant_enumerators = [_]Enumerator{
    .{ .name = "false", .value = 0 },
    .{ .name = "true", .value = 1 },
    .{ .name = "0", .value = 2 },
    .{ .name = "1", .value = 3 },
    .{ .name = "none", .value = 4 },
    .{ .name = "no_init", .value = (1 << 30) - 1 },
};

pub fn lookup(nominal: []const u8) ?Fact {
    const normalized = stripNominalSigil(std.mem.trim(u8, nominal, " "));
    if (std.mem.startsWith(u8, normalized, "Air.ShuffleOneMask__enum_") or
        std.mem.startsWith(u8, normalized, "ShuffleOneMask__enum_"))
    {
        return .{
            .name = normalized,
            .backing_type = .{ .int = 1 },
            .enumerators = shuffle_one_mask_kind_enumerators[0..],
        };
    }
    if (std.mem.indexOf(u8, normalized, "Formatter__enum_") != null) {
        return .{
            .name = normalized,
            .backing_type = .{ .int = 8 },
            .enumerators = ctype_formatter_kind_enumerators[0..],
        };
    }
    for (facts) |fact| {
        if (std.mem.eql(u8, normalized, fact.name)) return fact;
    }
    return null;
}

pub fn enumeratorValue(nominal: []const u8, literal: []const u8) ?i128 {
    const fact = lookup(nominal) orelse return null;
    const trimmed = std.mem.trim(u8, literal, " ");
    if (trimmed.len == 0) return null;
    const name = if (trimmed.len >= 2 and trimmed[0] == '.') trimmed[1..] else trimmed;
    for (fact.enumerators) |enumerator| {
        if (std.mem.eql(u8, name, enumerator.name)) return enumerator.value;
    }
    return null;
}

fn stripNominalSigil(text: []const u8) []const u8 {
    if (text.len != 0 and (text[0] == '%' or text[0] == '@')) return text[1..];
    return text;
}

test "enum facts expose exact nominal backing types and literals" {
    const fact = lookup("Io.Event") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 32 }, fact.backing_type);
    try std.testing.expectEqual(@as(?i128, 0), enumeratorValue("Io.Event", ".unset"));
    try std.testing.expectEqual(@as(?i128, 2), enumeratorValue("Io.Event", ".is_set"));
    try std.testing.expect(enumeratorValue("Event", ".unset") == null);

    const limit = lookup("Io.Limit") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 64 }, limit.backing_type);
    try std.testing.expectEqual(@as(?i128, 0), enumeratorValue("Io.Limit", ".nothing"));

    const chunk_len = lookup("http.Reader.RemainingChunkLen") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 64 }, chunk_len.backing_type);
    try std.testing.expectEqual(@as(?i128, 2), enumeratorValue("http.Reader.RemainingChunkLen", ".rn"));

    const optional_token = lookup("zig.Ast.OptionalTokenIndex") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 32 }, optional_token.backing_type);
    try std.testing.expectEqual(@as(?i128, std.math.maxInt(u32)), enumeratorValue("zig.Ast.OptionalTokenIndex", ".none"));

    const shuffle_mask = lookup("Air.ShuffleTwoMask") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 32 }, shuffle_mask.backing_type);
    try std.testing.expect(enumeratorValue("Air.ShuffleTwoMask", ".undef") == null);

    const coff_machine = lookup("coff.IMAGE.FILE.MACHINE") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 16 }, coff_machine.backing_type);
    try std.testing.expectEqual(@as(?i128, 0x8664), enumeratorValue("coff.IMAGE.FILE.MACHINE", ".AMD64"));
    try std.testing.expectEqual(@as(?i128, 0xaa64), enumeratorValue("coff.IMAGE.FILE.MACHINE", ".ARM64"));
    try std.testing.expectEqual(@as(?i128, 0xA641), enumeratorValue("coff.IMAGE.FILE.MACHINE", ".ARM64EC"));
    try std.testing.expectEqual(@as(?i128, 0xA64E), enumeratorValue("coff.IMAGE.FILE.MACHINE", ".ARM64X"));

    const std_coff_machine = lookup("std.coff.IMAGE.FILE.MACHINE") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 16 }, std_coff_machine.backing_type);

    const linkage = lookup("zig.llvm.Builder.Linkage") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 8 }, linkage.backing_type);
    try std.testing.expectEqual(@as(?i128, 0), enumeratorValue("zig.llvm.Builder.Linkage", ".external"));
    try std.testing.expectEqual(@as(?i128, 9), enumeratorValue("zig.llvm.Builder.Linkage", ".private"));

    const val_index = lookup("codegen.aarch64.Select.Value.Index") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 32 }, val_index.backing_type);
    try std.testing.expectEqual(@as(?i128, std.math.maxInt(u32) - 1), enumeratorValue("codegen.aarch64.Select.Value.Index", ".allocating"));
    try std.testing.expectEqual(@as(?i128, std.math.maxInt(u32)), enumeratorValue("codegen.aarch64.Select.Value.Index", ".free"));

    const llvm_align = lookup("zig.llvm.Builder.Alignment") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 6 }, llvm_align.backing_type);
    try std.testing.expectEqual(@as(?i128, 63), enumeratorValue("zig.llvm.Builder.Alignment", ".default"));

    const ip_align = lookup("InternPool.Alignment") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 6 }, ip_align.backing_type);
    try std.testing.expectEqual(@as(?i128, 63), enumeratorValue("InternPool.Alignment", ".none"));
    try std.testing.expectEqual(@as(?i128, 0), enumeratorValue("InternPool.Alignment", ".1"));
}
