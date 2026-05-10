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
    if (printed_module_record and module.functions.items.len != 0) try writer.writeByte('\n');

    for (module.functions.items, 0..) |function, function_index| {
        if (function_index != 0) try writer.writeByte('\n');
        try writer.writeAll("define ");
        try function.linkage.format(writer);
        try function.visibility.format(writer);
        if (function.calling_conv) |calling_conv| try writer.print("{s} ", .{calling_conv});
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
                        try writer.writeByte('\n');
                    },
                    .cast => |cast| {
                        try writer.print("{s} ", .{cast.op.name()});
                        try cast.from_ty.format(writer);
                        try writer.writeByte(' ');
                        try cast.value.format(writer);
                        try writer.writeAll(" to ");
                        try cast.to_ty.format(writer);
                        try writer.writeByte('\n');
                    },
                    .freeze => |freeze| {
                        try writer.writeAll("freeze ");
                        try freeze.ty.format(writer);
                        try writer.writeByte(' ');
                        try freeze.value.format(writer);
                        try writer.writeByte('\n');
                    },
                    .icmp => |icmp| {
                        try writer.print("icmp {s} ", .{icmp.predicate.name()});
                        try icmp.operand_ty.format(writer);
                        try writer.writeByte(' ');
                        try icmp.lhs.format(writer);
                        try writer.writeAll(", ");
                        try icmp.rhs.format(writer);
                        try writer.writeByte('\n');
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
                        try writer.writeByte('\n');
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
                        try writer.writeByte('\n');
                    },
                    .alloca => |alloca| {
                        try writer.writeAll("alloca ");
                        try alloca.allocated_ty.format(writer);
                        try writer.writeByte('\n');
                    },
                    .load => |load| {
                        try writer.writeAll("load ");
                        try printMemoryPrefix(load.attrs, writer);
                        try load.ty.format(writer);
                        try writer.writeAll(", ptr ");
                        try load.ptr.format(writer);
                        try printMemorySuffix(load.attrs, writer);
                        try writer.writeByte('\n');
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
                        try writer.writeByte('\n');
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
                        try writer.writeByte('\n');
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
                .br => |br| try writer.print("  br label %{s}\n", .{br.target}),
                .condbr => |condbr| {
                    try writer.writeAll("  br ");
                    try condbr.cond_ty.format(writer);
                    try writer.writeByte(' ');
                    try condbr.cond.format(writer);
                    try writer.print(", label %{s}, label %{s}\n", .{ condbr.then_target, condbr.else_target });
                },
                .@"unreachable" => try writer.writeAll("  unreachable\n"),
            };
        }

        try writer.writeAll("}\n");
    }
}

fn printBinaryFlags(flags: core.BinaryFlags, writer: anytype) !void {
    if (flags.nsw) try writer.writeAll("nsw ");
    if (flags.nuw) try writer.writeAll("nuw ");
    if (flags.exact) try writer.writeAll("exact ");
}

fn printMemoryPrefix(attrs: core.MemoryAttrs, writer: anytype) !void {
    if (attrs.is_volatile) try writer.writeAll("volatile ");
    if (attrs.atomic_ordering != null) try writer.writeAll("atomic ");
}

fn printMemorySuffix(attrs: core.MemoryAttrs, writer: anytype) !void {
    if (attrs.atomic_ordering) |ordering| try writer.print(", {s}", .{ordering});
    if (attrs.@"align") |alignment| try writer.print(", align {}", .{alignment});
}
