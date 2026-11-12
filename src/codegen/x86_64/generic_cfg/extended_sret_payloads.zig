//! Extended floating sret pointees keep exact storage/physical pointer ABI.
//! A private pointer return also retains the required SysV RAX result.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const syntax = @import("../../../ir/parser_syntax.zig");
const parser = @import("../../../ir/parser_types_values.zig");
const Fields = @import("../../../ir/structure.zig").Fields;
const storage = @import("storage_layout.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;

fn extended(ty: ir.Type, context: ?*const machine.ReadOnlyModuleContext, depth: usize) bool {
    if (depth >= 32) return false;
    if (ty == .x86_fp80 or ty == .fp128) return true;
    if (ty != .aggregate) return false;
    const text = std.mem.trim(u8, ty.aggregate, " \t");
    if (std.mem.startsWith(u8, text, "%")) {
        const ctx = context orelse return false;
        for (ctx.named_types) |named| if (ir.identifiers.eql(named.name, text[1..]))
            return extended(parser.parseType(named.body) catch return false, context, depth + 1);
        return false;
    }
    if (text.len > 1 and text[0] == '[' and text[text.len - 1] == ']') {
        const inside = std.mem.trim(u8, text[1 .. text.len - 1], " \t");
        const x = std.mem.indexOf(u8, inside, " x ") orelse return false;
        return extended(parser.parseType(inside[x + 3 ..]) catch return false, context, depth + 1);
    }
    var fields = Fields.init(text) orelse return false;
    while (fields.next()) |field| if (extended(parser.parseType(field) catch return false, context, depth + 1)) return true;
    return false;
}

fn mappedAttrs(a: std.mem.Allocator, attrs: ?[]const u8, context: ?*const machine.ReadOnlyModuleContext) !?[]const u8 {
    const text = attrs orelse return null;
    var rest = std.mem.trim(u8, text, " \t");
    while (rest.len != 0) {
        const end = syntax.findTopLevelTokenEnd(rest) orelse return null;
        if (end == 0) return null;
        const token = rest[0..end];
        if (std.mem.startsWith(u8, token, "sret(") and std.mem.endsWith(u8, token, ")")) {
            const ty = parser.parseType(token[5 .. token.len - 1]) catch return null;
            if (!extended(ty, context, 0)) return null;
            ir.verifyParameterAttrs(.ptr, attrs) catch return null;
            const original = storage.query(context, ty) orelse return null;
            if (original.bytes == 0 or original.bytes > 65536 or original.alignment > 16 or original.bytes % original.alignment != 0) return null;
            const backing = try std.fmt.allocPrint(a, "[{d} x i{d}]", .{ original.bytes / original.alignment, original.alignment * 8 });
            defer a.free(backing);
            const mapped = storage.query(context, parser.parseType(backing) catch return null) orelse return null;
            if (mapped.bytes != original.bytes or mapped.alignment != original.alignment) return null;
            // The private signature explicitly returns the output pointer,
            // with the same RDI input and RAX output as the source sret ABI.
            // Drop capture promises on that synthetic returned pointer.
            var output: std.Io.Writer.Allocating = .init(a);
            errdefer output.deinit();
            var tokens = std.mem.trim(u8, text, " \t");
            var written = false;
            while (tokens.len != 0) {
                const token_end = syntax.findTopLevelTokenEnd(tokens) orelse return null;
                const attribute = tokens[0..token_end];
                tokens = std.mem.trimStart(u8, tokens[token_end..], " \t");
                if (std.mem.startsWith(u8, attribute, "sret(") or std.mem.startsWith(u8, attribute, "captures(")) continue;
                if (written) try output.writer.writeByte(' ');
                try output.writer.writeAll(attribute);
                written = true;
            }
            return try output.toOwnedSlice();
        }
        rest = std.mem.trimStart(u8, rest[end..], " \t");
    }
    return null;
}

pub fn legalize(a: std.mem.Allocator, source: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if (!@import("composed_helpers.zig").isDefaultOrFastcc(source.calling_conv)) return null;
    var candidate = Candidate.init(a, source);
    var returned_pointer: ?[]const u8 = null;
    if (source.ret_ty == .void and source.params.items.len != 0 and source.params.items[0].ty == .ptr and !source.is_varargs) {
        if (try mappedAttrs(a, source.params.items[0].attrs, context)) |attrs| {
            candidate.result.params = try source.params.clone(a);
            candidate.result.params.items[0].attrs = if (attrs.len == 0) null else attrs;
            candidate.result.ret_ty = .ptr;
            returned_pointer = source.params.items[0].name;
            candidate.started = true;
        }
    }
    for (source.blocks.items, 0..) |original, bi| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items, 0..) |inst, ii| {
            if (!inst.removed and inst.kind == .call) {
                const call = inst.kind.call;
                const no_tail = if (call.tail_kind) |tail| !std.mem.eql(u8, tail, "musttail") else true;
                if (call.ret_ty == .void and call.args.items.len != 0 and call.args.items[0].ty == .ptr and
                    call.inline_asm == null and call.callee_function_ty == null and call.raw_args == null and call.operand_bundle == null and no_tail)
                {
                    if (try mappedAttrs(a, call.args.items[0].attrs, context)) |attrs| {
                        try candidate.begin(&block, bi, ii);
                        var copy = inst;
                        copy.kind.call.args = try call.args.clone(a);
                        copy.kind.call.args.items[0].attrs = if (attrs.len == 0) null else attrs;
                        try block.instructions.append(a, copy);
                        continue;
                    }
                }
            }
            try candidate.keep(&block, inst);
        }
        if (returned_pointer) |name| if (block.terminator) |*term| if (term.* == .ret) {
            term.ret.ty = .ptr;
            term.ret.value = .{ .named = name };
        };
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
