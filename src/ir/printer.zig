const std = @import("std");

const core = @import("core.zig");
const local_names = @import("local_names.zig");

pub const Options = struct {
    numeric_names: local_names.Mode = .repair,
};

pub fn print(module: core.Module, writer: anytype) !void {
    return printWithOptions(module, writer, .{});
}

pub fn printWithOptions(module: core.Module, writer: anytype, options: Options) !void {
    var name_plan = try local_names.Plan.init(module, options.numeric_names);
    defer name_plan.deinit();
    const module_names = name_plan.moduleNames();
    var printed_module_record = false;
    if (module.source_filename) |source_filename| {
        try writer.print("source_filename = \"{s}\"\n", .{source_filename});
        printed_module_record = true;
    }
    if (module.target_datalayout) |target_datalayout| {
        try writer.print("target datalayout = \"{s}\"\n", .{target_datalayout});
        printed_module_record = true;
    }
    if (module.target_triple) |target_triple| {
        try writer.print("target triple = \"{s}\"\n", .{target_triple});
        printed_module_record = true;
    }
    if (printed_module_record and (module.module_asm.items.len != 0 or module.named_types.items.len != 0 or module.comdats.items.len != 0 or module.globals.items.len != 0 or module.aliases.items.len != 0 or module.declarations.items.len != 0 or module.functions.items.len != 0 or module.attribute_groups.items.len != 0 or module.metadata.items.len != 0)) try writer.writeByte('\n');

    for (module.module_asm.items) |module_asm| try writer.print("{s}\n", .{module_asm});
    if (module.module_asm.items.len != 0 and (module.named_types.items.len != 0 or module.comdats.items.len != 0 or module.globals.items.len != 0 or module.aliases.items.len != 0 or module.declarations.items.len != 0 or module.functions.items.len != 0 or module.attribute_groups.items.len != 0 or module.metadata.items.len != 0)) try writer.writeByte('\n');

    for (module.named_types.items) |named_type| try writer.print("{s}\n", .{named_type.raw});
    if (module.named_types.items.len != 0 and (module.comdats.items.len != 0 or module.globals.items.len != 0 or module.aliases.items.len != 0 or module.declarations.items.len != 0 or module.functions.items.len != 0 or module.attribute_groups.items.len != 0 or module.metadata.items.len != 0)) try writer.writeByte('\n');

    for (module.comdats.items) |comdat| try writer.print("{s}\n", .{comdat});
    if (module.comdats.items.len != 0 and (module.globals.items.len != 0 or module.aliases.items.len != 0 or module.declarations.items.len != 0 or module.functions.items.len != 0)) try writer.writeByte('\n');

    for (module.globals.items) |global| {
        try writer.print("@{s} = ", .{global.name});
        try global.linkage.format(writer);
        if (global.address_attrs) |address_attrs| try writer.print("{s} ", .{module_names.text(address_attrs)});
        try writer.print("{s} ", .{global.kind.name()});
        try global.ty.format(writer);
        if (global.initializer != .none) {
            try writer.writeByte(' ');
            try printGlobalInitializer(global.initializer, module_names, writer);
        }
        if (global.attrs) |attrs| try writer.print(", {s}", .{module_names.text(attrs)});
        try writer.writeByte('\n');
    }
    if (module.globals.items.len != 0 and (module.aliases.items.len != 0 or module.declarations.items.len != 0 or module.functions.items.len != 0)) try writer.writeByte('\n');

    for (module.aliases.items) |alias| {
        try writer.print("@{s} = ", .{alias.name});
        try alias.linkage.format(writer);
        try alias.visibility.format(writer);
        try writer.print("alias {s}, ", .{alias.aliased_ty});
        try alias.target_ty.format(writer);
        try writer.print(" @{s}\n", .{alias.target});
    }
    if (module.aliases.items.len != 0 and (module.declarations.items.len != 0 or module.functions.items.len != 0)) try writer.writeByte('\n');

    for (module.declarations.items, 0..) |decl, decl_index| {
        if (decl_index != 0) try writer.writeByte('\n');
        try writer.writeAll("declare ");
        try decl.linkage.format(writer);
        try decl.visibility.format(writer);
        if (decl.calling_conv) |calling_conv| try writer.print("{s} ", .{calling_conv});
        try printReturnType(decl.ret_ty, module_names.optionalText(decl.ret_attrs), writer);
        try writer.print(" @{s}(", .{decl.name});
        for (decl.params.items, 0..) |param, index| {
            if (index != 0) try writer.writeAll(", ");
            try param.ty.format(writer);
            if (param.attrs) |attrs| try writer.print(" {s}", .{module_names.text(attrs)});
        }
        if (decl.is_varargs) {
            if (decl.params.items.len != 0) try writer.writeAll(", ");
            try writer.writeAll("...");
        }
        try writer.writeByte(')');
        if (decl.attrs) |attrs| try writer.print(" {s}", .{module_names.text(attrs)});
        try writer.writeByte('\n');
    }
    if (module.declarations.items.len != 0 and module.functions.items.len != 0) try writer.writeByte('\n');

    for (module.functions.items, 0..) |function, function_index| {
        const names = name_plan.forFunction(function_index);
        if (function_index != 0) try writer.writeByte('\n');
        try writer.writeAll("define ");
        try function.linkage.format(writer);
        try function.visibility.format(writer);
        if (function.calling_conv) |calling_conv| try writer.print("{s} ", .{calling_conv});
        try printReturnType(function.ret_ty, names.optionalText(function.ret_attrs), writer);
        try writer.print(" @{s}(", .{function.name});
        for (function.params.items, 0..) |param, index| {
            if (index != 0) try writer.writeAll(", ");
            try param.ty.format(writer);
            if (param.attrs) |attrs| try writer.print(" {s}", .{names.text(attrs)});
            try writer.print(" %{s}", .{names.name(param.name)});
        }
        if (function.is_varargs) {
            if (function.params.items.len != 0) try writer.writeAll(", ");
            try writer.writeAll("...");
        }
        try writer.writeByte(')');
        if (function.attrs) |attrs| try writer.print(" {s}", .{names.text(attrs)});
        try writer.writeAll(" {\n");

        for (function.blocks.items) |block| {
            try writer.print("{s}:\n", .{names.name(block.name)});
            for (block.instructions.items) |instruction| {
                if (instruction.removed) continue;
                if (instruction.result) |result| {
                    try writer.print("  %{s} = ", .{names.name(result)});
                } else {
                    try writer.writeAll("  ");
                }
                switch (instruction.kind) {
                    .binary => |binary| {
                        try writer.print("{s} ", .{binary.op.name()});
                        try printBinaryFlags(binary.flags, writer);
                        try printFastMathFlags(binary.fp_flags, writer);
                        try binary.ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(binary.lhs).format(writer);
                        try writer.writeAll(", ");
                        try names.value(binary.rhs).format(writer);
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .cast => |cast| {
                        try writer.print("{s} ", .{cast.op.name()});
                        try printCastFlags(cast.flags, writer);
                        try cast.from_ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(cast.value).format(writer);
                        try writer.writeAll(" to ");
                        try cast.to_ty.format(writer);
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .freeze => |freeze| {
                        try writer.writeAll("freeze ");
                        try freeze.ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(freeze.value).format(writer);
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .icmp => |icmp| {
                        try writer.writeAll("icmp ");
                        if (icmp.samesign) try writer.writeAll("samesign ");
                        try writer.print("{s} ", .{icmp.predicate.name()});
                        try icmp.operand_ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(icmp.lhs).format(writer);
                        try writer.writeAll(", ");
                        try names.value(icmp.rhs).format(writer);
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .fcmp => |fcmp| {
                        try writer.writeAll("fcmp ");
                        try printFastMathFlags(fcmp.fp_flags, writer);
                        try writer.print("{s} ", .{fcmp.predicate.name()});
                        try fcmp.operand_ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(fcmp.lhs).format(writer);
                        try writer.writeAll(", ");
                        try names.value(fcmp.rhs).format(writer);
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .select => |select| {
                        try writer.writeAll("select ");
                        try select.cond_ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(select.cond).format(writer);
                        try writer.writeAll(", ");
                        try select.ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(select.true_value).format(writer);
                        try writer.writeAll(", ");
                        try select.ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(select.false_value).format(writer);
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .phi => |phi| {
                        try writer.writeAll("phi ");
                        try phi.ty.format(writer);
                        try writer.writeByte(' ');
                        for (phi.incoming.items, 0..) |incoming, index| {
                            if (index != 0) try writer.writeAll(", ");
                            try writer.writeAll("[ ");
                            try names.value(incoming.value).format(writer);
                            try writer.print(", %{s} ]", .{names.name(incoming.block)});
                        }
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .alloca => |alloca| {
                        try writer.writeAll("alloca ");
                        try printTypeWithAddressSpace(alloca.allocated_ty, alloca.allocated_ty_addrspace, writer);
                        if (alloca.count) |count| {
                            try writer.writeAll(", ");
                            try count.ty.format(writer);
                            try writer.writeByte(' ');
                            try names.value(count.value).format(writer);
                        }
                        if (alloca.attrs) |attrs| try writer.print(", {s}", .{names.text(attrs)});
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .load => |load| {
                        try writer.writeAll("load ");
                        try printMemoryPrefix(load.attrs, writer);
                        try printTypeWithAddressSpace(load.ty, load.ty_addrspace, writer);
                        try writer.writeAll(", ptr ");
                        if (load.ptr_addrspace) |addrspace_name| try writer.print("{s} ", .{addrspace_name});
                        try names.value(load.ptr).format(writer);
                        try printMemorySuffix(load.attrs, writer);
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .store => |store| {
                        try writer.writeAll("store ");
                        try printMemoryPrefix(store.attrs, writer);
                        try printTypeWithAddressSpace(store.ty, store.ty_addrspace, writer);
                        try writer.writeByte(' ');
                        try names.value(store.value).format(writer);
                        try writer.writeAll(", ptr ");
                        if (store.ptr_addrspace) |addrspace_name| try writer.print("{s} ", .{addrspace_name});
                        try names.value(store.ptr).format(writer);
                        try printMemorySuffix(store.attrs, writer);
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .atomicrmw => |atomicrmw| {
                        try writer.writeAll("atomicrmw ");
                        if (atomicrmw.is_volatile) try writer.writeAll("volatile ");
                        try writer.print("{s} ptr ", .{atomicrmw.op});
                        try names.value(atomicrmw.ptr).format(writer);
                        try writer.writeAll(", ");
                        try atomicrmw.ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(atomicrmw.value).format(writer);
                        if (atomicrmw.syncscope) |syncscope| try writer.print(" {s}", .{syncscope});
                        try writer.print(" {s}", .{atomicrmw.ordering});
                        if (atomicrmw.@"align") |alignment| try writer.print(", align {}", .{alignment});
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .cmpxchg => |cmpxchg| {
                        try writer.writeAll("cmpxchg ");
                        if (cmpxchg.is_weak) try writer.writeAll("weak ");
                        if (cmpxchg.is_volatile) try writer.writeAll("volatile ");
                        try writer.writeAll("ptr ");
                        try names.value(cmpxchg.ptr).format(writer);
                        try writer.writeAll(", ");
                        try cmpxchg.ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(cmpxchg.expected).format(writer);
                        try writer.writeAll(", ");
                        try cmpxchg.ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(cmpxchg.replacement).format(writer);
                        if (cmpxchg.syncscope) |syncscope| try writer.print(" {s}", .{syncscope});
                        try writer.print(" {s} {s}", .{ cmpxchg.success_ordering, cmpxchg.failure_ordering });
                        if (cmpxchg.@"align") |alignment| try writer.print(", align {}", .{alignment});
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .fence => |fence| {
                        try writer.writeAll("fence ");
                        if (fence.syncscope) |syncscope| try writer.print("{s} ", .{syncscope});
                        try writer.print("{s}", .{fence.ordering});
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .extractelement => |extract| {
                        try writer.writeAll("extractelement ");
                        try extract.vector_ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(extract.vector).format(writer);
                        try writer.writeAll(", ");
                        try extract.index_ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(extract.index).format(writer);
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .insertelement => |insert| {
                        try writer.writeAll("insertelement ");
                        try insert.vector_ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(insert.vector).format(writer);
                        try writer.writeAll(", ");
                        try insert.value_ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(insert.value).format(writer);
                        try writer.writeAll(", ");
                        try insert.index_ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(insert.index).format(writer);
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .shufflevector => |shuffle| {
                        try writer.writeAll("shufflevector ");
                        try shuffle.lhs_ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(shuffle.lhs).format(writer);
                        try writer.writeAll(", ");
                        try shuffle.rhs_ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(shuffle.rhs).format(writer);
                        try writer.writeAll(", ");
                        try shuffle.mask_ty.format(writer);
                        try writer.writeByte(' ');
                        try printShuffleMask(names.value(shuffle.mask), writer);
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .extractvalue => |extract| {
                        try writer.writeAll("extractvalue ");
                        try extract.aggregate_ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(extract.aggregate).format(writer);
                        try writer.print(", {s}", .{extract.indices});
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .insertvalue => |insert| {
                        try writer.writeAll("insertvalue ");
                        try insert.aggregate_ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(insert.aggregate).format(writer);
                        try writer.writeAll(", ");
                        try insert.value_ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(insert.value).format(writer);
                        try writer.print(", {s}", .{insert.indices});
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .gep => |gep| {
                        try writer.writeAll("getelementptr ");
                        try gep.source_ty.format(writer);
                        try writer.writeAll(", ptr ");
                        if (gep.ptr_addrspace) |addrspace_text| try writer.print("{s} ", .{addrspace_text});
                        try names.value(gep.ptr).format(writer);
                        for (gep.indices.items) |index| {
                            try writer.writeAll(", ");
                            try index.ty.format(writer);
                            try writer.writeByte(' ');
                            try names.value(index.value).format(writer);
                        }
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                    .call => |call| {
                        if (call.va_arg) {
                            try writer.writeAll("va_arg ptr ");
                            try names.value(call.args.items[0].value).format(writer);
                            try writer.writeAll(", ");
                            try call.ret_ty.format(writer);
                            try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                            continue;
                        }
                        if (call.tail_kind) |tail_kind| try writer.print("{s} ", .{tail_kind});
                        try writer.writeAll("call ");
                        if (call.calling_conv) |calling_conv| try writer.print("{s} ", .{calling_conv});
                        try printReturnType(call.ret_ty, names.optionalText(call.ret_attrs), writer);
                        if (call.callee_function_ty) |function_ty| try writer.print(" {s}", .{function_ty});
                        if (call.inline_asm) |inline_asm| {
                            try writer.writeAll(" asm ");
                            if (inline_asm.sideeffect) try writer.writeAll("sideeffect ");
                            try writer.print("\"{s}\", \"{s}\"(", .{ inline_asm.template, inline_asm.constraints });
                        } else if (call.callee_value) |callee_value| {
                            try writer.writeByte(' ');
                            try names.value(callee_value).format(writer);
                            try writer.writeByte('(');
                        } else {
                            try writer.print(" @{s}(", .{call.callee});
                        }
                        if (call.raw_args) |raw_args| {
                            try writer.writeAll(names.text(raw_args));
                        } else {
                            for (call.args.items, 0..) |arg, index| {
                                if (index != 0) try writer.writeAll(", ");
                                try arg.ty.format(writer);
                                if (arg.attrs) |attrs| try writer.print(" {s}", .{names.text(attrs)});
                                try writer.writeByte(' ');
                                try names.value(arg.value).format(writer);
                            }
                        }
                        try writer.writeByte(')');
                        if (call.attrs) |attrs| try writer.print(" {s}", .{names.text(attrs)});
                        if (call.operand_bundle) |operand_bundle| try writer.print(" {s}", .{names.text(operand_bundle)});
                        try printInstructionMetadata(names.optionalText(instruction.metadata), writer);
                    },
                }
            }
            if (block.terminator) |terminator| switch (terminator) {
                .ret => |ret| {
                    try writer.writeAll("  ret ");
                    try ret.ty.format(writer);
                    if (ret.ptr_addrspace) |addrspace_text| try writer.print(" {s}", .{addrspace_text});
                    if (ret.value) |value| {
                        try writer.writeByte(' ');
                        try names.value(value).format(writer);
                    }
                    try writer.writeByte('\n');
                },
                .br => |br| {
                    try writer.print("  br label %{s}", .{names.name(br.target)});
                    if (br.metadata) |metadata| try writer.print(", {s}", .{names.text(metadata)});
                    try writer.writeByte('\n');
                },
                .condbr => |condbr| {
                    try writer.writeAll("  br ");
                    try condbr.cond_ty.format(writer);
                    try writer.writeByte(' ');
                    try names.value(condbr.cond).format(writer);
                    try writer.print(", label %{s}, label %{s}", .{ names.name(condbr.then_target), names.name(condbr.else_target) });
                    if (condbr.metadata) |metadata| try writer.print(", {s}", .{names.text(metadata)});
                    try writer.writeByte('\n');
                },
                .@"switch" => |switch_term| {
                    try writer.writeAll("  switch ");
                    try switch_term.cond_ty.format(writer);
                    try writer.writeByte(' ');
                    try names.value(switch_term.cond).format(writer);
                    try writer.print(", label %{s} [\n", .{names.name(switch_term.default_target)});
                    for (switch_term.cases.items) |case| {
                        try writer.writeAll("    ");
                        try case.value_ty.format(writer);
                        try writer.writeByte(' ');
                        try names.value(case.value).format(writer);
                        try writer.print(", label %{s}\n", .{names.name(case.target)});
                    }
                    try writer.writeAll("  ]");
                    if (switch_term.metadata) |metadata| try writer.print(", {s}", .{names.text(metadata)});
                    try writer.writeByte('\n');
                },
                .indirectbr => |indirectbr| {
                    try writer.writeAll("  indirectbr ");
                    try indirectbr.addr_ty.format(writer);
                    try writer.writeByte(' ');
                    try names.value(indirectbr.addr).format(writer);
                    try writer.writeAll(", [");
                    for (indirectbr.targets.items, 0..) |target, index| {
                        if (index != 0) try writer.writeAll(", ");
                        try writer.print("label %{s}", .{names.name(target)});
                    }
                    try writer.writeByte(']');
                    if (indirectbr.metadata) |metadata| try writer.print(", {s}", .{names.text(metadata)});
                    try writer.writeByte('\n');
                },
                .@"unreachable" => try writer.writeAll("  unreachable\n"),
            };
        }

        try writer.writeAll("}\n");
    }

    if (module.attribute_groups.items.len != 0) {
        if (module.comdats.items.len != 0 or module.globals.items.len != 0 or module.aliases.items.len != 0 or module.declarations.items.len != 0 or module.functions.items.len != 0) try writer.writeByte('\n');
        for (module.attribute_groups.items) |attribute_group| try writer.print("{s}\n", .{module_names.text(attribute_group)});
    }

    if (module.metadata.items.len != 0) {
        if (module.comdats.items.len != 0 or module.globals.items.len != 0 or module.aliases.items.len != 0 or module.declarations.items.len != 0 or module.functions.items.len != 0 or module.attribute_groups.items.len != 0) try writer.writeByte('\n');
        for (module.metadata.items) |metadata| try writer.print("{s}\n", .{module_names.text(metadata)});
    }
}

fn printGlobalInitializer(initializer: core.GlobalInitializer, names: local_names.Names, writer: anytype) !void {
    switch (initializer) {
        .none, .c_string => try initializer.format(writer),
        .scalar => |value| try names.value(value).format(writer),
        .@"opaque" => |raw| try writer.writeAll(names.text(raw)),
        .array => |array| {
            try writer.writeByte('[');
            for (array.values.items, 0..) |value, index| {
                if (index != 0) try writer.writeAll(", ");
                try array.elem_ty.format(writer);
                try writer.writeByte(' ');
                try names.value(value).format(writer);
            }
            try writer.writeByte(']');
        },
    }
}

fn printReturnType(ty: core.Type, attrs: ?[]const u8, writer: anytype) !void {
    if (ty == .ptr) {
        if (attrs) |text| {
            if (startsWithAddressSpaceAttr(text)) {
                try ty.format(writer);
                try writer.print(" {s}", .{text});
                return;
            }
        }
    }
    if (attrs) |text| try writer.print("{s} ", .{text});
    try ty.format(writer);
}

fn printTypeWithAddressSpace(ty: core.Type, addrspace_text: ?[]const u8, writer: anytype) !void {
    try ty.format(writer);
    if (addrspace_text) |text| try writer.print(" {s}", .{text});
}

fn startsWithAddressSpaceAttr(text: []const u8) bool {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (!std.mem.startsWith(u8, trimmed, "addrspace(")) return false;
    const close = std.mem.indexOfScalar(u8, trimmed, ')') orelse return false;
    const payload = trimmed["addrspace(".len..close];
    if (payload.len == 0) return false;
    for (payload) |byte| {
        if (!std.ascii.isDigit(byte)) return false;
    }
    return true;
}

fn printBinaryFlags(flags: core.BinaryFlags, writer: anytype) !void {
    if (flags.nsw) try writer.writeAll("nsw ");
    if (flags.nuw) try writer.writeAll("nuw ");
    if (flags.exact) try writer.writeAll("exact ");
    if (flags.disjoint) try writer.writeAll("disjoint ");
}

fn printCastFlags(flags: core.CastFlags, writer: anytype) !void {
    if (flags.nneg) try writer.writeAll("nneg ");
    if (flags.nsw) try writer.writeAll("nsw ");
    if (flags.nuw) try writer.writeAll("nuw ");
}

fn printShuffleMask(mask: core.Value, writer: anytype) !void {
    switch (mask) {
        .vector => |text| try printShuffleMaskVector(text, writer),
        .int, .fp, .named, .undef, .poison, .null_value, .zero_initializer, .constant_expr => try mask.format(writer),
    }
}

fn printShuffleMaskVector(text: []const u8, writer: anytype) !void {
    var index: usize = 0;
    while (index < text.len) {
        if (std.mem.startsWith(u8, text[index..], "undef") and isTokenBoundary(text, index, "undef".len)) {
            try writer.writeAll("poison");
            index += "undef".len;
            continue;
        }
        try writer.writeByte(text[index]);
        index += 1;
    }
}

fn isTokenBoundary(text: []const u8, start: usize, len: usize) bool {
    if (start != 0 and isIdentifierByte(text[start - 1])) return false;
    const end = start + len;
    return end == text.len or !isIdentifierByte(text[end]);
}

fn isIdentifierByte(byte: u8) bool {
    return std.ascii.isAlphanumeric(byte) or byte == '_' or byte == '-' or byte == '.';
}

fn printFastMathFlags(flags: core.FastMathFlags, writer: anytype) !void {
    if (flags.fast) {
        try writer.writeAll("fast ");
        return;
    }
    if (flags.nnan) try writer.writeAll("nnan ");
    if (flags.ninf) try writer.writeAll("ninf ");
    if (flags.nsz) try writer.writeAll("nsz ");
    if (flags.arcp) try writer.writeAll("arcp ");
    if (flags.contract) try writer.writeAll("contract ");
    if (flags.afn) try writer.writeAll("afn ");
    if (flags.reassoc) try writer.writeAll("reassoc ");
}

fn printMemoryPrefix(attrs: core.MemoryAttrs, writer: anytype) !void {
    if (attrs.is_volatile) try writer.writeAll("volatile ");
    if (attrs.atomic_ordering != null) try writer.writeAll("atomic ");
}

fn printMemorySuffix(attrs: core.MemoryAttrs, writer: anytype) !void {
    if (attrs.syncscope) |syncscope| {
        try writer.print(" {s}", .{syncscope});
        if (attrs.atomic_ordering) |ordering| try writer.print(" {s}", .{ordering});
    } else if (attrs.atomic_ordering) |ordering| {
        try writer.print(" {s}", .{ordering});
    }
    if (attrs.@"align") |alignment| try writer.print(", align {}", .{alignment});
}

fn printInstructionMetadata(metadata: ?[]const u8, writer: anytype) !void {
    if (metadata) |attachment| try writer.print(", {s}", .{attachment});
    try writer.writeByte('\n');
}
