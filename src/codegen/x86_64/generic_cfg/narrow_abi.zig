//! Private 32/64-bit carriers for non-native integer ABI widths and advisory facts.
//! The low bits retain their source width; only the selector's view is widened.
const std = @import("std");
const ir = @import("../../../ir.zig");
const sysv = @import("../sysv_abi.zig");
const helpers = @import("composed_helpers.zig");
const temporary_names = @import("scalar_forms.zig");
const TemporaryNames = temporary_names.TemporaryNames;
const syntax = @import("../../../ir/parser_syntax.zig");

fn carrier(ty: ir.Type) ir.Type {
    return .{ .int = if (ty.int < 32) 32 else 64 };
}

fn narrow(ty: ir.Type) bool {
    return ty == .int and ty.int > 0 and ty.int < 64 and ty.int != 32;
}

// Only these two signed physical carriers have independent ABI proofs.
fn signedExtension(ty: ir.Type, attrs: ?[]const u8) bool {
    if (ty != .int or (ty.int != 8 and ty.int != 16)) return false;
    const text = attrs orelse return false;
    ir.verifyParameterAttrs(ty, text) catch return false;
    var rest = std.mem.trim(u8, text, " \t");
    var signed = false;
    while (rest.len != 0) {
        const end = syntax.findTopLevelTokenEnd(rest) orelse return false;
        if (end == 0) return false;
        const token = rest[0..end];
        rest = std.mem.trim(u8, rest[end..], " \t");
        if (std.mem.eql(u8, token, "signext")) {
            signed = true;
            continue;
        }
        if (std.mem.eql(u8, token, "noundef") or std.mem.startsWith(u8, token, "range(")) continue;
        return false;
    }
    return signed;
}
fn advisory(ty: ir.Type, attrs: ?[]const u8) bool {
    if (signedExtension(ty, attrs)) return true;
    return sysv.callReturnAttrsSupported(.{ .callee = "", .ret_ty = ty, .ret_attrs = attrs, .args = .empty });
}

fn parameter(param: ir.Param) bool {
    return narrow(param.ty) and advisory(param.ty, param.attrs);
}

fn callForm(call: ir.CallInst) bool {
    if (std.mem.startsWith(u8, call.callee, "llvm.") or
        (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and call.args.items.len != 2) or
        call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or
        call.callee_function_ty != null or !helpers.isDefaultOrFastcc(call.calling_conv)) return false;
    if (call.callee_value) |callee| if (callee != .named or callee.named.len == 0 or callee.named[0] == '@') return false;
    var envelope = call;
    if (signedExtension(call.ret_ty, call.ret_attrs)) envelope.ret_attrs = null;
    sysv.rejectUnsupportedCallEnvelope(envelope) catch return false;
    for (call.args.items) |arg| {
        if (signedExtension(arg.ty, arg.attrs)) continue;
        sysv.rejectUnsupportedCallArgAttrs(arg) catch return false;
    }
    return true;
}

fn stackObject(function: ir.Function, value: ir.Value) bool {
    if (value != .named) return false;
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (!inst.removed and inst.kind == .alloca and inst.result != null and ir.identifiers.eql(inst.result.?, value.named)) return true;
    };
    return false;
}

fn callReturn(function: ir.Function, call: ir.CallInst) bool {
    if (!narrow(call.ret_ty) or !advisory(call.ret_ty, call.ret_attrs)) return false;
    if (call.ret_attrs != null) return true;
    if (call.ret_ty.int != 1 or call.callee_value != null) return true;
    // The established typed boolean action owns up to six named scalar or
    // stack-object arguments. Other ordinary calls use the general ABI path,
    // then mask AL before publishing the original boolean SSA value.
    if (call.args.items.len > 6) return true;
    for (call.args.items) |arg| {
        if (arg.value != .named or std.mem.startsWith(u8, arg.value.named, "@")) return true;
        if (arg.ty == .ptr and !stackObject(function, arg.value)) return true;
        // SSE, extended floating and wide arguments use the ordinary ABI
        // dispatcher; the typed boolean action owns native GPR operands.
        if (arg.ty != .ptr and (arg.ty != .int or arg.ty.int > 64)) return true;
    }
    return false;
}

fn needsCall(function: ir.Function, call: ir.CallInst) bool {
    if (!callForm(call)) return false;
    if (callReturn(function, call)) return true;
    for (call.args.items) |arg| if (narrow(arg.ty)) return true;
    return false;
}

fn booleanXor(inst: ir.Instruction) bool {
    return inst.kind == .binary and inst.kind.binary.op == .xor and
        inst.kind.binary.ty.eql(.{ .int = 1 }) and !inst.kind.binary.flags.any();
}

fn temporary(allocator: std.mem.Allocator, function: ir.Function, serial: *TemporaryNames) ![]const u8 {
    return temporary_names.temporary(allocator, function, serial);
}

fn outgoing(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *TemporaryNames, ty: ir.Type, attrs: ?[]const u8, value: ir.Value) !ir.Value {
    if (!signedExtension(ty, attrs)) return widen(allocator, function, block, serial, ty, value);
    if (value == .int) {
        const modulus = @as(i128, 1) << @intCast(ty.int);
        const payload = value.int & (modulus - 1);
        return .{ .int = if (payload & (modulus >> 1) != 0) payload - modulus else payload };
    }
    const name = try temporary(allocator, function, serial);
    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .cast = .{
        .op = .sext,
        .from_ty = ty,
        .value = value,
        .to_ty = carrier(ty),
    } } });
    return .{ .named = name };
}
fn widen(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *TemporaryNames, ty: ir.Type, value: ir.Value) !ir.Value {
    if (value == .int) return .{ .int = value.int & ((@as(i128, 1) << @intCast(ty.int)) - 1) };
    const name = try temporary(allocator, function, serial);
    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .cast = .{
        .op = .zext,
        .from_ty = ty,
        .value = value,
        .to_ty = carrier(ty),
    } } });
    return .{ .named = name };
}

fn receive(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *TemporaryNames, ty: ir.Type, value: ir.Value, name: []const u8) !void {
    const masked = try temporary(allocator, function, serial);
    try block.instructions.append(allocator, .{ .result = masked, .kind = .{ .binary = .{
        .op = .@"and",
        .ty = carrier(ty),
        .lhs = value,
        .rhs = .{ .int = (@as(i128, 1) << @intCast(ty.int)) - 1 },
    } } });
    // A trunc alone is a location alias in the selector. Mask before binding the
    // original narrow name, including booleans consumed directly by a branch.
    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .cast = .{
        .op = .trunc,
        .from_ty = carrier(ty),
        .value = .{ .named = masked },
        .to_ty = ty,
    } } });
}

// The caller owns an arena. Clone every list that changes and borrow immutable
// nested operands. C/fastcc integer register carriers occupy the same ABI homes.
pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    if (!helpers.isDefaultOrFastcc(function.calling_conv) or function.blocks.items.len == 0) return null;
    if (narrow(function.ret_ty) and !advisory(function.ret_ty, function.ret_attrs)) return null;
    const return_value = narrow(function.ret_ty);
    var needed = return_value;
    for (function.params.items) |param| if (parameter(param)) {
        needed = true;
    };
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed) continue;
        if (booleanXor(inst) or (inst.kind == .call and needsCall(function, inst.kind.call))) needed = true;
    };
    if (!needed) return null;
    var result = function;
    result.params = try function.params.clone(allocator);
    result.blocks = .empty;
    // Validated facts describe the original logical payload, not unspecified
    // bits in its ABI register carrier. In particular, a range on i8 cannot be
    // attached to a dirty i32 return before the receive mask. Preserve source
    // attributes and conservatively omit them only on the private widened view.
    if (return_value) {
        result.ret_ty = carrier(function.ret_ty);
        result.ret_attrs = null;
    }
    var serial: TemporaryNames = .{ .prefix = "__zllvm_narrow_" };
    defer serial.deinit(allocator);
    for (result.params.items) |*param| if (parameter(param.*)) {
        param.name = try temporary(allocator, function, &serial);
        param.ty = carrier(param.ty);
        param.attrs = null;
    };
    for (function.blocks.items, 0..) |original, index| {
        var block = original;
        block.instructions = .empty;
        if (index == 0) for (function.params.items, result.params.items) |param, incoming| {
            if (parameter(param)) try receive(allocator, function, &block, &serial, param.ty, .{ .named = incoming.name }, param.name);
        };
        for (original.instructions.items) |inst| {
            var copy = inst;
            if (!inst.removed and booleanXor(inst)) {
                const binary = inst.kind.binary;
                copy.kind.binary.lhs = try widen(allocator, function, &block, &serial, binary.ty, binary.lhs);
                copy.kind.binary.rhs = try widen(allocator, function, &block, &serial, binary.ty, binary.rhs);
                copy.kind.binary.ty = carrier(binary.ty);
                copy.result = try temporary(allocator, function, &serial);
                try block.instructions.append(allocator, copy);
                try block.instructions.append(allocator, .{ .result = inst.result, .kind = .{ .cast = .{
                    .op = .trunc,
                    .from_ty = carrier(binary.ty),
                    .value = .{ .named = copy.result.? },
                    .to_ty = binary.ty,
                } } });
                continue;
            }
            if (!inst.removed and inst.kind == .call and needsCall(function, inst.kind.call)) {
                const call = inst.kind.call;
                copy.kind.call.args = try call.args.clone(allocator);
                for (copy.kind.call.args.items) |*arg| if (narrow(arg.ty)) {
                    arg.value = try outgoing(allocator, function, &block, &serial, arg.ty, arg.attrs, arg.value);
                    arg.ty = carrier(arg.ty);
                    arg.attrs = null;
                };
                if (callReturn(function, call)) {
                    copy.kind.call.ret_ty = carrier(call.ret_ty);
                    copy.kind.call.ret_attrs = null;
                    if (inst.result != null) copy.result = try temporary(allocator, function, &serial);
                }
                try block.instructions.append(allocator, copy);
                if (callReturn(function, call) and inst.result != null)
                    try receive(allocator, function, &block, &serial, call.ret_ty, .{ .named = copy.result.? }, inst.result.?);
                continue;
            }
            try block.instructions.append(allocator, copy);
        }
        if (return_value) if (block.terminator) |*term| if (term.* == .ret) {
            if (term.ret.value) |value| term.ret.value = try outgoing(allocator, function, &block, &serial, function.ret_ty, function.ret_attrs, value);
            term.ret.ty = carrier(function.ret_ty);
        };
        try result.blocks.append(allocator, block);
    }
    return result;
}

// LLVM musttail requires bounded stack growth. Direct recursion on an internal
// scalar function becomes an entry loop; public/indirect ABI frontiers stay put.
// https://releases.llvm.org/22.1.0/docs/LangRef.html#call-instruction
pub fn legalizeSelfTail(a: std.mem.Allocator, function: ir.Function) !?ir.Function {
    return SelfTail.legalize(a, function);
}

const SelfTail = struct {
    fn scalar(ty: ir.Type) bool {
        return ty == .ptr or (ty == .int and switch (ty.int) {
            8, 16, 32, 64 => true,
            else => false,
        });
    }
    fn sameConvention(a: ?[]const u8, b: ?[]const u8) bool {
        if (a == null or b == null) return a == null and b == null;
        return std.mem.eql(u8, a.?, b.?);
    }
    fn targets(term: ir.Terminator, name: []const u8) bool {
        return switch (term) {
            .br => |x| ir.identifiers.eql(x.target, name),
            .condbr => |x| ir.identifiers.eql(x.then_target, name) or ir.identifiers.eql(x.else_target, name),
            .@"switch" => |x| blk: {
                if (ir.identifiers.eql(x.default_target, name)) break :blk true;
                for (x.cases.items) |item| if (ir.identifiers.eql(item.target, name)) break :blk true;
                break :blk false;
            },
            .indirectbr => |x| blk: {
                for (x.targets.items) |target| if (ir.identifiers.eql(target, name)) break :blk true;
                break :blk false;
            },
            else => false,
        };
    }
    fn site(function: ir.Function, block: ir.BasicBlock) ?usize {
        const term = block.terminator orelse return null;
        if (term != .ret or term.ret.ptr_addrspace != null) return null;
        var last = block.instructions.items.len;
        while (last > 0 and block.instructions.items[last - 1].removed) last -= 1;
        if (last == 0) return null;
        const inst = block.instructions.items[last - 1];
        if (inst.kind != .call) return null;
        const call = inst.kind.call;
        if (call.tail_kind == null or !std.mem.eql(u8, call.tail_kind.?, "musttail") or
            !ir.identifiers.eql(call.callee, function.name) or call.callee_value != null or
            call.callee_function_ty != null or call.native_query != null or call.va_arg or
            !sameConvention(call.calling_conv, function.calling_conv) or
            !call.ret_ty.eql(function.ret_ty) or !term.ret.ty.eql(function.ret_ty) or
            call.ret_attrs != null or call.args.items.len != function.params.items.len) return null;
        if (function.ret_ty == .void) {
            if (inst.result != null or term.ret.value != null) return null;
        } else {
            const value = term.ret.value orelse return null;
            if (inst.result == null or value != .named or !ir.identifiers.eql(value.named, inst.result.?)) return null;
        }
        var envelope = call;
        envelope.tail_kind = null;
        sysv.rejectUnsupportedCallEnvelope(envelope) catch return null;
        for (call.args.items, function.params.items) |arg, param| {
            if (!arg.ty.eql(param.ty) or arg.abi_x87_memory or arg.abi_split_integer) return null;
            sysv.rejectUnsupportedCallArgAttrs(arg) catch return null;
        }
        return last - 1;
    }
    fn legalize(a: std.mem.Allocator, function: ir.Function) !?ir.Function {
        if ((function.linkage != .internal and function.linkage != .private) or function.is_varargs or
            !helpers.isDefaultOrFastcc(function.calling_conv) or function.blocks.items.len == 0 or
            function.params.items.len > @import("stack_arguments.zig").max_arguments or
            function.ret_attrs != null or (function.ret_ty != .void and !scalar(function.ret_ty))) return null;
        for (function.params.items) |param| {
            if (!scalar(param.ty) or param.abi_incoming_address != null or param.abi_x87_memory or param.abi_split_integer) return null;
            sysv.rejectUnsupportedCallArgAttrs(.{ .ty = param.ty, .attrs = param.attrs, .value = .{ .named = param.name } }) catch return null;
        }
        const entry_name = function.blocks.items[0].name;
        var sites: std.ArrayList(struct { block: usize, instruction: usize }) = .empty;
        defer sites.deinit(a);
        for (function.blocks.items, 0..) |block, index| {
            if (block.terminator) |term| if (targets(term, entry_name)) return null;
            for (block.instructions.items) |inst| if (!inst.removed) {
                if ((index == 0 and inst.kind == .phi) or (inst.kind == .alloca and !inst.kind.alloca.isSingleObject())) return null;
            };
            if (site(function, block)) |instruction| try sites.append(a, .{ .block = index, .instruction = instruction });
        }
        if (sites.items.len == 0) return null;
        var serial: TemporaryNames = .{ .prefix = "__zllvm_self_tail_" };
        defer serial.deinit(a);
        const prologue_name = try temporary(a, function, &serial);
        var result = function;
        result.params = try function.params.clone(a);
        result.blocks = .empty;
        for (result.params.items) |*param| param.name = try temporary(a, function, &serial);
        var prologue = ir.BasicBlock.init(prologue_name);
        prologue.terminator = .{ .br = .{ .target = entry_name } };
        try result.blocks.append(a, prologue);
        for (function.blocks.items, 0..) |source_block, index| {
            var block = source_block;
            block.instructions = .empty;
            if (index == 0) for (function.params.items, result.params.items, 0..) |param, incoming, position| {
                var edges: std.ArrayList(ir.PhiIncoming) = .empty;
                try edges.append(a, .{ .value = .{ .named = incoming.name }, .block = prologue_name });
                for (sites.items) |tail| {
                    const call = function.blocks.items[tail.block].instructions.items[tail.instruction].kind.call;
                    try edges.append(a, .{ .value = call.args.items[position].value, .block = function.blocks.items[tail.block].name });
                }
                try block.instructions.append(a, .{ .result = param.name, .kind = .{ .phi = .{ .ty = param.ty, .incoming = edges } } });
            };
            const tail_index = site(function, source_block);
            for (source_block.instructions.items, 0..) |inst, instruction| {
                if (tail_index != null and instruction == tail_index.?) continue;
                try block.instructions.append(a, inst);
            }
            if (tail_index != null) block.terminator = .{ .br = .{ .target = entry_name } };
            try result.blocks.append(a, block);
        }
        return result;
    }
};

/// Normalize the proved signed carriers before original-signature retries.
/// Other ABI attributes and widths retain the existing rejection paths.
pub fn legalizeSigned(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var needed = signedExtension(function.ret_ty, function.ret_attrs);
    for (function.params.items) |param| if (signedExtension(param.ty, param.attrs)) {
        needed = true;
    };
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.kind != .call) continue;
        if (signedExtension(inst.kind.call.ret_ty, inst.kind.call.ret_attrs)) needed = true;
        for (inst.kind.call.args.items) |arg| if (signedExtension(arg.ty, arg.attrs)) {
            needed = true;
        };
    };
    if (!needed) return null;
    return legalize(allocator, function);
}

/// A private scalar tail-call envelope. Stack arguments, vectors, ABI payloads,
/// varargs and externally visible callers retain their existing boundaries.
pub fn terminalTail(function: ir.Function, block: ir.BasicBlock) ?usize {
    if ((function.linkage != .internal and function.linkage != .private) or function.is_varargs or
        !helpers.isDefaultOrFastcc(function.calling_conv) or function.params.items.len > 6 or
        (function.ret_ty != .void and !SelfTail.scalar(function.ret_ty)) or !Tail.attrs(function.ret_ty, function.ret_attrs)) return null;
    const term = block.terminator orelse return null;
    if (term != .ret or term.ret.ptr_addrspace != null or !term.ret.ty.eql(function.ret_ty)) return null;
    var last = block.instructions.items.len;
    while (last > 0 and block.instructions.items[last - 1].removed) last -= 1;
    if (last == 0) return null;
    const instruction = block.instructions.items[last - 1];
    if (instruction.kind != .call) return null;
    const call = instruction.kind.call;
    if (call.tail_kind == null or !std.mem.eql(u8, call.tail_kind.?, "musttail") or
        call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or
        call.callee_function_ty != null or call.native_query != null or call.va_arg or call.abi_x87_return or
        std.mem.startsWith(u8, call.callee, "llvm.") or !Tail.sameConvention(function.calling_conv, call.calling_conv) or
        !call.ret_ty.eql(function.ret_ty) or call.args.items.len != function.params.items.len or
        !Tail.attrs(call.ret_ty, call.ret_attrs) or Tail.extension(function.ret_attrs) != Tail.extension(call.ret_attrs)) return null;
    if (function.ret_ty == .void) {
        if (instruction.result != null or term.ret.value != null) return null;
    } else {
        const value = term.ret.value orelse return null;
        if (value != .named or instruction.result == null or !ir.identifiers.eql(value.named, instruction.result.?)) return null;
    }
    var envelope = call;
    envelope.tail_kind = "tail";
    if (!callForm(envelope)) return null;
    for (function.params.items, call.args.items) |param, arg| {
        if (!SelfTail.scalar(param.ty) or !param.ty.eql(arg.ty) or param.abi_incoming_address != null or
            param.abi_x87_memory or param.abi_split_integer or arg.abi_x87_memory or arg.abi_split_integer or
            !Tail.attrs(param.ty, param.attrs) or !Tail.attrs(arg.ty, arg.attrs) or
            Tail.extension(param.attrs) != Tail.extension(arg.attrs)) return null;
    }
    return last - 1;
}

pub fn hasTail(function: ir.Function) bool {
    for (function.blocks.items) |block| if (terminalTail(function, block) != null) return true;
    return false;
}
pub fn hasOrdinaryReturn(function: ir.Function) bool {
    for (function.blocks.items) |block| if (block.terminator) |term| if (term == .ret and terminalTail(function, block) == null) return true;
    return false;
}

const Tail = struct {
    fn sameConvention(a: ?[]const u8, b: ?[]const u8) bool {
        return std.mem.eql(u8, a orelse "ccc", b orelse "ccc");
    }
    fn extension(text: ?[]const u8) u2 {
        var words = std.mem.tokenizeAny(u8, text orelse "", " \t");
        while (words.next()) |word| {
            if (std.mem.eql(u8, word, "signext")) return 1;
            if (std.mem.eql(u8, word, "zeroext")) return 2;
        }
        return 0;
    }
    fn attrs(ty: ir.Type, text: ?[]const u8) bool {
        if (ty == .void) return text == null;
        if (ty == .ptr) return if (text) |value| sysv.pointerCallAttrsAreAdvisory(value) else true;
        return advisory(ty, text);
    }
};

/// Use the established signed/unsigned carrier transformations, then keep only
/// the call's physical return home at the terminal edge. No receive code may
/// run after a required tail transfer. The source and all source lists stay owned
/// by the original module; only this arena-backed view is changed.
pub fn legalizeTail(a: std.mem.Allocator, function: ir.Function) !?ir.Function {
    if (!hasTail(function)) return null;
    var staged = function;
    staged.blocks = try function.blocks.clone(a);
    for (staged.blocks.items, function.blocks.items) |*block, original| if (terminalTail(function, original)) |at| {
        block.instructions = try original.instructions.clone(a);
        block.instructions.items[at].kind.call.tail_kind = "tail";
    };
    const result = (try legalize(a, staged)) orelse return null;
    for (result.blocks.items, function.blocks.items) |*block, original| if (terminalTail(function, original) != null) {
        var at = block.instructions.items.len;
        while (at > 0) {
            at -= 1;
            const inst = block.instructions.items[at];
            if (inst.removed or inst.kind != .call) continue;
            if (inst.kind.call.tail_kind == null or !std.mem.eql(u8, inst.kind.call.tail_kind.?, "tail")) return error.TailCarrierCallMissing;
            block.instructions.items[at].kind.call.tail_kind = "musttail";
            block.instructions.items.len = at + 1;
            block.terminator = .{ .ret = .{ .ty = inst.kind.call.ret_ty, .value = if (inst.result) |name| ir.Value{ .named = name } else null } };
            break;
        } else return error.TailCarrierCallMissing;
    };
    return result;
}
