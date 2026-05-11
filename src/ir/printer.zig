const core = @import("core.zig");

pub fn print(module: core.Module, writer: anytype) !void {
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
    if (printed_module_record and (module.comdats.items.len != 0 or module.globals.items.len != 0 or module.aliases.items.len != 0 or module.declarations.items.len != 0 or module.functions.items.len != 0 or module.attribute_groups.items.len != 0 or module.metadata.items.len != 0)) try writer.writeByte('\n');

    for (module.comdats.items) |comdat| try writer.print("{s}\n", .{comdat});
    if (module.comdats.items.len != 0 and (module.globals.items.len != 0 or module.aliases.items.len != 0 or module.declarations.items.len != 0 or module.functions.items.len != 0)) try writer.writeByte('\n');

    for (module.globals.items) |global| {
        try writer.print("@{s} = ", .{global.name});
        try global.linkage.format(writer);
        if (global.address_attrs) |address_attrs| try writer.print("{s} ", .{address_attrs});
        try writer.print("{s} ", .{global.kind.name()});
        try global.ty.format(writer);
        try writer.writeByte(' ');
        try global.initializer.format(writer);
        if (global.attrs) |attrs| try writer.print(", {s}", .{attrs});
        try writer.writeByte('\n');
    }
    if (module.globals.items.len != 0 and (module.aliases.items.len != 0 or module.declarations.items.len != 0 or module.functions.items.len != 0)) try writer.writeByte('\n');

    for (module.aliases.items) |alias| {
        try writer.print("@{s} = ", .{alias.name});
        try alias.linkage.format(writer);
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
        if (decl.ret_attrs) |ret_attrs| try writer.print("{s} ", .{ret_attrs});
        try decl.ret_ty.format(writer);
        try writer.print(" @{s}(", .{decl.name});
        for (decl.params.items, 0..) |param, index| {
            if (index != 0) try writer.writeAll(", ");
            try param.ty.format(writer);
            if (param.attrs) |attrs| try writer.print(" {s}", .{attrs});
        }
        try writer.writeByte(')');
        if (decl.attrs) |attrs| try writer.print(" {s}", .{attrs});
        try writer.writeByte('\n');
    }
    if (module.declarations.items.len != 0 and module.functions.items.len != 0) try writer.writeByte('\n');

    for (module.functions.items, 0..) |function, function_index| {
        if (function_index != 0) try writer.writeByte('\n');
        try writer.writeAll("define ");
        try function.linkage.format(writer);
        try function.visibility.format(writer);
        if (function.calling_conv) |calling_conv| try writer.print("{s} ", .{calling_conv});
        if (function.ret_attrs) |ret_attrs| try writer.print("{s} ", .{ret_attrs});
        try function.ret_ty.format(writer);
        try writer.print(" @{s}(", .{function.name});
        for (function.params.items, 0..) |param, index| {
            if (index != 0) try writer.writeAll(", ");
            try param.ty.format(writer);
            if (param.attrs) |attrs| try writer.print(" {s}", .{attrs});
            try writer.print(" %{s}", .{param.name});
        }
        try writer.writeByte(')');
        if (function.attrs) |attrs| try writer.print(" {s}", .{attrs});
        try writer.writeAll(" {\n");

        for (function.blocks.items) |block| {
            try writer.print("{s}:\n", .{block.name});
            for (block.instructions.items) |instruction| {
                if (instruction.removed) continue;
                if (instruction.result) |result| {
                    try writer.print("  %{s} = ", .{result});
                } else {
                    try writer.writeAll("  ");
                }
                switch (instruction.kind) {
                    .binary => |binary| {
                        try writer.print("{s} ", .{binary.op.name()});
                        try printBinaryFlags(binary.flags, writer);
                        try binary.ty.format(writer);
                        try writer.writeByte(' ');
                        try binary.lhs.format(writer);
                        try writer.writeAll(", ");
                        try binary.rhs.format(writer);
                        try printInstructionMetadata(instruction.metadata, writer);
                    },
                    .cast => |cast| {
                        try writer.print("{s} ", .{cast.op.name()});
                        try cast.from_ty.format(writer);
                        try writer.writeByte(' ');
                        try cast.value.format(writer);
                        try writer.writeAll(" to ");
                        try cast.to_ty.format(writer);
                        try printInstructionMetadata(instruction.metadata, writer);
                    },
                    .freeze => |freeze| {
                        try writer.writeAll("freeze ");
                        try freeze.ty.format(writer);
                        try writer.writeByte(' ');
                        try freeze.value.format(writer);
                        try printInstructionMetadata(instruction.metadata, writer);
                    },
                    .icmp => |icmp| {
                        try writer.print("icmp {s} ", .{icmp.predicate.name()});
                        try icmp.operand_ty.format(writer);
                        try writer.writeByte(' ');
                        try icmp.lhs.format(writer);
                        try writer.writeAll(", ");
                        try icmp.rhs.format(writer);
                        try printInstructionMetadata(instruction.metadata, writer);
                    },
                    .select => |select| {
                        try writer.writeAll("select ");
                        try select.cond_ty.format(writer);
                        try writer.writeByte(' ');
                        try select.cond.format(writer);
                        try writer.writeAll(", ");
                        try select.ty.format(writer);
                        try writer.writeByte(' ');
                        try select.true_value.format(writer);
                        try writer.writeAll(", ");
                        try select.ty.format(writer);
                        try writer.writeByte(' ');
                        try select.false_value.format(writer);
                        try printInstructionMetadata(instruction.metadata, writer);
                    },
                    .phi => |phi| {
                        try writer.writeAll("phi ");
                        try phi.ty.format(writer);
                        try writer.writeByte(' ');
                        for (phi.incoming.items, 0..) |incoming, index| {
                            if (index != 0) try writer.writeAll(", ");
                            try writer.writeAll("[ ");
                            try incoming.value.format(writer);
                            try writer.print(", %{s} ]", .{incoming.block});
                        }
                        try printInstructionMetadata(instruction.metadata, writer);
                    },
                    .alloca => |alloca| {
                        try writer.writeAll("alloca ");
                        try alloca.allocated_ty.format(writer);
                        try printInstructionMetadata(instruction.metadata, writer);
                    },
                    .load => |load| {
                        try writer.writeAll("load ");
                        try printMemoryPrefix(load.attrs, writer);
                        try load.ty.format(writer);
                        try writer.writeAll(", ptr ");
                        try load.ptr.format(writer);
                        try printMemorySuffix(load.attrs, writer);
                        try printInstructionMetadata(instruction.metadata, writer);
                    },
                    .store => |store| {
                        try writer.writeAll("store ");
                        try printMemoryPrefix(store.attrs, writer);
                        try store.ty.format(writer);
                        try writer.writeByte(' ');
                        try store.value.format(writer);
                        try writer.writeAll(", ptr ");
                        try store.ptr.format(writer);
                        try printMemorySuffix(store.attrs, writer);
                        try printInstructionMetadata(instruction.metadata, writer);
                    },
                    .gep => |gep| {
                        try writer.writeAll("getelementptr ");
                        try gep.source_ty.format(writer);
                        try writer.writeAll(", ptr ");
                        try gep.ptr.format(writer);
                        for (gep.indices.items) |index| {
                            try writer.writeAll(", ");
                            try index.ty.format(writer);
                            try writer.writeByte(' ');
                            try index.value.format(writer);
                        }
                        try printInstructionMetadata(instruction.metadata, writer);
                    },
                    .call => |call| {
                        if (call.tail_kind) |tail_kind| try writer.print("{s} ", .{tail_kind});
                        try writer.writeAll("call ");
                        if (call.calling_conv) |calling_conv| try writer.print("{s} ", .{calling_conv});
                        try call.ret_ty.format(writer);
                        try writer.print(" @{s}(", .{call.callee});
                        for (call.args.items, 0..) |arg, index| {
                            if (index != 0) try writer.writeAll(", ");
                            try arg.ty.format(writer);
                            try writer.writeByte(' ');
                            try arg.value.format(writer);
                        }
                        try writer.writeByte(')');
                        try printInstructionMetadata(instruction.metadata, writer);
                    },
                }
            }
            if (block.terminator) |terminator| switch (terminator) {
                .ret => |ret| {
                    try writer.writeAll("  ret ");
                    try ret.ty.format(writer);
                    if (ret.value) |value| {
                        try writer.writeByte(' ');
                        try value.format(writer);
                    }
                    try writer.writeByte('\n');
                },
                .br => |br| {
                    try writer.print("  br label %{s}", .{br.target});
                    if (br.metadata) |metadata| try writer.print(", {s}", .{metadata});
                    try writer.writeByte('\n');
                },
                .condbr => |condbr| {
                    try writer.writeAll("  br ");
                    try condbr.cond_ty.format(writer);
                    try writer.writeByte(' ');
                    try condbr.cond.format(writer);
                    try writer.print(", label %{s}, label %{s}", .{ condbr.then_target, condbr.else_target });
                    if (condbr.metadata) |metadata| try writer.print(", {s}", .{metadata});
                    try writer.writeByte('\n');
                },
                .@"unreachable" => try writer.writeAll("  unreachable\n"),
            };
        }

        try writer.writeAll("}\n");
    }

    if (module.attribute_groups.items.len != 0) {
        if (module.comdats.items.len != 0 or module.globals.items.len != 0 or module.aliases.items.len != 0 or module.declarations.items.len != 0 or module.functions.items.len != 0) try writer.writeByte('\n');
        for (module.attribute_groups.items) |attribute_group| try writer.print("{s}\n", .{attribute_group});
    }

    if (module.metadata.items.len != 0) {
        if (module.comdats.items.len != 0 or module.globals.items.len != 0 or module.aliases.items.len != 0 or module.declarations.items.len != 0 or module.functions.items.len != 0 or module.attribute_groups.items.len != 0) try writer.writeByte('\n');
        for (module.metadata.items) |metadata| try writer.print("{s}\n", .{metadata});
    }
}

fn printBinaryFlags(flags: core.BinaryFlags, writer: anytype) !void {
    if (flags.nsw) try writer.writeAll("nsw ");
    if (flags.nuw) try writer.writeAll("nuw ");
    if (flags.exact) try writer.writeAll("exact ");
    if (flags.disjoint) try writer.writeAll("disjoint ");
}

fn printMemoryPrefix(attrs: core.MemoryAttrs, writer: anytype) !void {
    if (attrs.is_volatile) try writer.writeAll("volatile ");
    if (attrs.atomic_ordering != null) try writer.writeAll("atomic ");
}

fn printMemorySuffix(attrs: core.MemoryAttrs, writer: anytype) !void {
    if (attrs.atomic_ordering) |ordering| try writer.print(", {s}", .{ordering});
    if (attrs.@"align") |alignment| try writer.print(", align {}", .{alignment});
}

fn printInstructionMetadata(metadata: ?[]const u8, writer: anytype) !void {
    if (metadata) |attachment| try writer.print(", {s}", .{attachment});
    try writer.writeByte('\n');
}
