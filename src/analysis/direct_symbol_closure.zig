//! A separate, closed proof for changing private direct-call signatures.
//! Enumerate complete LLVM global-identifier tokens in a print of the LIVE
//! module, including every opaque initializer, metadata record and bundle.
//! Strings are literals, not global operands. Assembly and attributes require
//! their separate complete grammars because they can name symbols as strings.
//! Any unsupported spelling/envelope closes this transformation. Existing
//! module_references unknown/coverage semantics are intentionally unchanged.
const std = @import("std");
const ir = @import("../ir.zig");
const Cursor = @import("reference_syntax.zig").Cursor;
const attributes = @import("reference_attributes.zig");
const Counts = std.HashMap([]const u8, usize, ir.identifiers.Context, 80);
fn add(counts: *Counts, name: []const u8) !void {
    const found = try counts.getOrPut(name);
    if (!found.found_existing) found.value_ptr.* = 0;
    found.value_ptr.* += 1;
}
fn literal(text: []const u8, index: *usize) !void {
    index.* += 1;
    while (index.* < text.len) {
        const ch = text[index.*];
        index.* += 1;
        if (ch == '"') return;
        if (ch == 0 or ch == '\n' or ch == '\r') return error.UnknownSymbolRegion;
        if (ch == '\\') {
            if (index.* == text.len) return error.UnknownSymbolRegion;
            if (text.len - index.* >= 2 and std.ascii.isHex(text[index.*]) and std.ascii.isHex(text[index.* + 1])) index.* += 2 else if (text[index.*] == '\\' or text[index.*] == '"') index.* += 1 else return error.UnknownSymbolRegion;
        }
    }
    return error.UnknownSymbolRegion;
}
fn countTokens(counts: *Counts, text: []const u8) !void {
    var index: usize = 0;
    while (index < text.len) switch (text[index]) {
        ';' => {
            while (index < text.len and text[index] != '\n') : (index += 1) {}
        },
        '"' => try literal(text, &index),
        '@' => {
            index += 1;
            if (index == text.len or std.ascii.isWhitespace(text[index])) return error.UnknownSymbolRegion;
            var cursor: Cursor = .{ .text = text, .index = index };
            const name = cursor.identifier() orelse return error.UnknownSymbolRegion;
            index = cursor.index;
            if (index < text.len and !std.ascii.isWhitespace(text[index]) and std.mem.indexOfScalar(u8, "(){}[]<>,=:;*", text[index]) == null) return error.UnknownSymbolRegion;
            try add(counts, name);
        },
        0, '\\' => return error.UnknownSymbolRegion,
        else => index += 1,
    };
}
fn attrText(text: ?[]const u8, groups: *const attributes.Groups, counts: *Counts) !bool {
    var cursor: Cursor = .{ .text = text orelse return true };
    while (!cursor.done()) {
        const saved = cursor.index;
        if (attributes.takeOne(&cursor, groups)) {
            _ = cursor.take(',');
            continue;
        }
        cursor.index = saved;
        if (cursor.peek() == '"') {
            const key = cursor.string() orelse return false;
            if (!cursor.take('=')) return false;
            const value = cursor.string() orelse return false;
            if (ir.identifiers.eql(key, "probe-stack")) {
                // The value is an LLVM string containing a literal symbol name.
                if (!ir.identifiers.isValid(value)) return false;
                try add(counts, value);
            } else if (ir.identifiers.eql(key, "stack-protector-buffer-size")) {
                _ = std.fmt.parseUnsigned(u32, value[1 .. value.len - 1], 10) catch return false;
            } else return false;
        } else if (cursor.take('!')) {
            _ = cursor.identifier() orelse return false;
            if (!cursor.take('!')) return false;
            _ = cursor.number(u32) orelse return false;
        } else if (cursor.keyword("sspstrong") or cursor.keyword("ssp") or cursor.keyword("sspreq") or cursor.keyword("null_pointer_is_valid")) {
            // These enumerate stack-protector policy, not symbol spellings.
        } else if (cursor.keyword("section")) {
            _ = cursor.string() orelse return false;
        } else if (cursor.keyword("thread_local")) {
            if (cursor.take('(')) {
                const model = cursor.word() orelse return false;
                if (!std.mem.eql(u8, model, "localexec") and !std.mem.eql(u8, model, "initialexec") and !std.mem.eql(u8, model, "localdynamic") and !std.mem.eql(u8, model, "generaldynamic")) return false;
                if (!cursor.take(')')) return false;
            }
        } else if (cursor.keyword("range")) {
            if (!cursor.take('(')) return false;
            const ty = cursor.word() orelse return false;
            if (ty.len < 2 or ty[0] != 'i') return false;
            const bits = std.fmt.parseUnsigned(u16, ty[1..], 10) catch return false;
            if (bits == 0) return false;
            _ = cursor.integer() orelse return false;
            if (!cursor.take(',')) return false;
            _ = cursor.integer() orelse return false;
            if (!cursor.take(')')) return false;
        } else return false;
        _ = cursor.take(',');
    }
    return true;
}
fn attributeCoverage(a: std.mem.Allocator, module: ir.Module, counts: *Counts) !bool {
    var groups: attributes.Groups = .{ .allocator = a };
    defer groups.deinit();
    for (module.attribute_groups.items) |record| {
        var cursor: Cursor = .{ .text = record };
        if (!cursor.keyword("attributes") or !cursor.take('#')) return false;
        const id = cursor.number(u32) orelse return false;
        if (!cursor.take('=') or !cursor.take('{')) return false;
        const rest = std.mem.trim(u8, record[cursor.index..], " \t\r\n");
        if (rest.len == 0 or rest[rest.len - 1] != '}') return false;
        if (!try attrText(rest[0 .. rest.len - 1], &groups, counts)) return false;
        const entry = try groups.known.getOrPut(a, id);
        if (entry.found_existing) return false;
        entry.value_ptr.* = true;
    }
    for (module.globals.items) |global| if (!try attrText(global.attrs, &groups, counts) or !try attrText(global.address_attrs, &groups, counts)) return false;
    for (module.declarations.items) |decl| {
        if (!try attrText(decl.attrs, &groups, counts) or !try attrText(decl.ret_attrs, &groups, counts)) return false;
        for (decl.params.items) |param| if (!try attrText(param.attrs, &groups, counts)) return false;
    }
    for (module.functions.items) |function| {
        if (!try attrText(function.attrs, &groups, counts) or !try attrText(function.ret_attrs, &groups, counts)) return false;
        for (function.params.items) |param| if (!try attrText(param.attrs, &groups, counts)) return false;
        for (function.blocks.items) |block| for (block.instructions.items) |inst| {
            if (inst.removed or inst.kind != .call) continue;
            const call = inst.kind.call;
            if (!try attrText(call.attrs, &groups, counts) or !try attrText(call.ret_attrs, &groups, counts)) return false;
            for (call.args.items) |arg| if (!try attrText(arg.attrs, &groups, counts)) return false;
        };
    }
    return true;
}
fn safeAssembly(module: ir.Module) bool {
    for (module.functions.items) |function| for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.kind != .call or inst.kind.call.inline_asm == null) continue;
        if (inst.kind.call.inline_asm.?.template.len == 0) continue;
        if (@import("../codegen/x86_64/inline_asm.zig").classify(inst.kind.call) != null) continue;
        if (@import("../codegen/x86_64/generic_cfg/bounded_inline_asm.zig").classify(inst) != null) continue;
        return false;
    };
    return true;
}
pub fn prove(a: std.mem.Allocator, module: ir.Module, names: []const []const u8) ![]bool {
    const result = try a.alloc(bool, names.len);
    @memset(result, false);
    if (names.len == 0 or !safeAssembly(module)) return result;
    var counts = Counts.init(a);
    defer counts.deinit();
    if (!try attributeCoverage(a, module, &counts)) return result;
    var printed: std.Io.Writer.Allocating = .init(a);
    defer printed.deinit();
    try module.print(&printed.writer);
    countTokens(&counts, printed.written()) catch |err| switch (err) {
        error.OutOfMemory => return err,
        else => return result,
    };
    var assembly = @import("../codegen/x86_64/module_asm_aliases.zig").parse(a, module) catch |err| switch (err) {
        error.OutOfMemory => return err,
        else => return result,
    };
    defer if (assembly) |*owned| owned.deinit(a);
    for (names, 0..) |name, index| {
        if (!ir.identifiers.isValid(name) or reservedProvider(name)) continue;
        var calls: usize = 0;
        var valid = true;
        var definition: ?ir.Function = null;
        for (module.functions.items) |function| if (ir.identifiers.eql(name, function.name)) {
            if (definition != null) {
                valid = false;
                break;
            }
            definition = function;
        };
        const target = definition orelse continue;
        if ((target.linkage != .internal and target.linkage != .private) or target.is_varargs) continue;
        if (assembly) |aliases| for (aliases.aliases.items) |alias| if (ir.identifiers.eql(alias.target, name) or ir.identifiers.eql(alias.name, name)) {
            valid = false;
            break;
        };
        for (module.functions.items) |owner| for (owner.blocks.items) |block| for (block.instructions.items) |inst| {
            if (inst.removed or inst.kind != .call or !ir.identifiers.eql(inst.kind.call.callee, name)) continue;
            const call = inst.kind.call;
            calls += 1;
            const optional_tail = if (call.tail_kind) |tail| std.mem.eql(u8, tail, "tail") or std.mem.eql(u8, tail, "notail") else true;
            if (call.callee_value != null or call.callee_function_ty != null or call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or !optional_tail or !call.ret_ty.eql(target.ret_ty) or call.args.items.len != target.params.items.len or !optionalEql(call.calling_conv, target.calling_conv)) {
                valid = false;
                continue;
            }
            for (call.args.items, target.params.items) |arg, param| if (!arg.ty.eql(param.ty) or arg.abi_x87_memory or arg.abi_split_integer or param.abi_x87_memory or param.abi_split_integer or param.abi_incoming_address != null) {
                valid = false;
                break;
            };
        };
        result[index] = valid and calls != 0 and (counts.get(name) orelse 0) == calls + 1;
    }
    return result;
}
// Implicit runtime/provider calls do not need a textual LLVM operand. They
// cannot enter a changed signature. Keep the compiler's reserved namespaces
// and the current memory/libm provider contracts outside this transformation.
fn reservedProvider(name: []const u8) bool {
    if (std.mem.startsWith(u8, name, "__") or std.mem.startsWith(u8, name, "llvm.") or std.mem.startsWith(u8, name, "zig.")) return true;
    for ([_][]const u8{ "memcpy", "memmove", "memset", "memcmp", "bcmp", "bzero", "strlen", "strcmp", "abort", "raise", "setjmp", "longjmp", "fmod", "fmodf", "fmodl", "fmodf128", "sincos", "sincosf", "sincosl", "sincosf128", "fmaxl", "fmaxf128" }) |reserved| if (ir.identifiers.eql(name, reserved)) return true;
    for (@import("../codegen/x86_64/generic_cfg/extended_math_intrinsics.zig").operations) |operation| for ([_][]const u8{ "", "f", "l", "f128" }) |suffix| {
        if (name.len == operation.len + suffix.len and std.mem.startsWith(u8, name, operation) and std.mem.endsWith(u8, name, suffix)) return true;
    };
    return false;
}
fn optionalEql(left: ?[]const u8, right: ?[]const u8) bool {
    if (left) |l| return if (right) |r| std.mem.eql(u8, l, r) else false;
    return right == null;
}
