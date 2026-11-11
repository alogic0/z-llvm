//! Exact extended80 payloads and incoming memory ABI; numerical/return contracts stay separate.
const std = @import("std");
const ir = @import("../../../ir.zig");
const target = @import("../../../target.zig");
const machine = @import("../machine.zig");
const addresses = @import("../symbol_address.zig");
const helpers = @import("composed_helpers.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const forms = @import("scalar_forms.zig");
const sysv = @import("../sysv_abi.zig");
const carrier: ir.Type = .{ .int = 80 };
const home: ir.Type = .{ .int = 128 };

const Builder = struct {
    allocator: std.mem.Allocator,
    function: ir.Function,
    block: *ir.BasicBlock,
    serial: *forms.TemporaryNames,

    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(b.allocator, b.function, b.serial);
        try b.block.instructions.append(b.allocator, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }
    fn returnValue(b: Builder, original: ir.Value) !ir.Value {
        const mapped = try value(original);
        if (mapped == .named) return mapped;
        const raw: u80 = if (mapped == .int) @truncate(@as(u128, @bitCast(mapped.int))) else 0;
        var words: [2]ir.Value = undefined;
        for (&words, 0..) |*part, index| {
            const bits: u64 = @truncate(@as(u128, raw) >> @as(u7, @intCast(index * 64)));
            const scalar = try b.emit(.{ .binary = .{ .op = .add, .ty = .{ .int = 64 }, .lhs = .{ .int = bits }, .rhs = .{ .int = 0 } } });
            part.* = try b.emit(.{ .cast = .{ .op = .zext, .from_ty = .{ .int = 64 }, .value = scalar, .to_ty = carrier } });
        }
        const high = try b.emit(.{ .binary = .{ .op = .shl, .ty = carrier, .lhs = words[1], .rhs = .{ .int = 64 } } });
        return b.emit(.{ .binary = .{ .op = .@"or", .ty = carrier, .lhs = words[0], .rhs = high } });
    }
};

fn value(source: ir.Value) !ir.Value {
    return switch (source) {
        .named, .undef, .poison => source,
        .zero_initializer => .{ .int = 0 },
        .fp => |text| .{ .int = if (std.mem.startsWith(u8, text, "0xK")) blk: {
            if (text.len != 23) return error.UnsupportedExtended80Payload;
            break :blk std.fmt.parseUnsigned(u80, text[3..], 16) catch return error.UnsupportedExtended80Payload;
        } else @as(u80, @bitCast(std.fmt.parseFloat(f80, text) catch return error.UnsupportedExtended80Payload)) },
        else => error.UnsupportedExtended80Payload,
    };
}

fn ordinary(access: anytype) bool {
    return !access.attrs.isBarrier() and access.attrs.syncscope == null and access.ty_addrspace == null and access.ptr_addrspace == null;
}

fn advisory(attrs: ?[]const u8) bool {
    return attrs == null or std.mem.eql(u8, std.mem.trim(u8, attrs.?, " \t"), "noundef");
}

fn callForm(call: ir.CallInst) bool {
    if (!helpers.isDefaultOrFastcc(call.calling_conv) or call.callee_value != null or
        call.callee_function_ty != null or call.inline_asm != null or call.raw_args != null or
        call.operand_bundle != null or std.mem.startsWith(u8, call.callee, "llvm.")) return false;
    // Only the existing direct integer/pointer stack layout participates.
    if (call.ret_ty != .x86_fp80 and call.ret_ty != .void and call.ret_ty != .ptr and call.ret_ty != .int) return false;
    if (call.ret_ty == .x86_fp80 and !advisory(call.ret_attrs)) return false;
    var envelope = call;
    if (call.ret_ty == .x86_fp80) envelope.ret_attrs = null;
    sysv.rejectUnsupportedCallEnvelope(envelope) catch return false;
    sysv.rejectUnsupportedCallSignature(call) catch return false;
    for (call.args.items) |arg| {
        if (arg.ty == .x86_fp80) {
            if (!advisory(arg.attrs)) return false;
            _ = value(arg.value) catch return false;
        } else {
            if (arg.ty != .ptr and arg.ty != .int) return false;
            sysv.rejectUnsupportedCallArgAttrs(arg) catch return false;
        }
    }
    return true;
}

const Use = struct {
    pub const Error = error{};
    found: *bool,
    pub fn visit(self: Use, _: *const ir.Value, ty: ir.Type) Error!void {
        if (ty == .x86_fp80) self.found.* = true;
    }
};

fn touches(inst: ir.Instruction) bool {
    var found = if (inst.resultType()) |ty| ty == .x86_fp80 else false;
    _ = ir.operands.instruction(&inst, Use{ .found = &found }) catch unreachable;
    return found;
}

fn eligible(function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) bool {
    if (!helpers.isDefaultOrFastcc(function.calling_conv)) return false;
    var found = function.ret_ty == .x86_fp80;
    if (found) if (function.ret_attrs) |attrs| if (!std.mem.eql(u8, std.mem.trim(u8, attrs, " \t"), "noundef")) return false;
    for (function.params.items) |param| if (param.ty == .x86_fp80) {
        if (param.attrs) |attrs| if (!std.mem.eql(u8, std.mem.trim(u8, attrs, " \t"), "noundef")) return false;
        found = true;
    };
    const text = if (context) |ctx| ctx.target_datalayout else null;
    if (!addresses.supportsLayout(text)) return false;
    var specs = std.mem.splitScalar(u8, text orelse "", '-');
    while (specs.next()) |spec| if (std.mem.startsWith(u8, spec, "f80:")) {
        var fields = std.mem.splitScalar(u8, spec, ':');
        _ = fields.next();
        if (!std.mem.eql(u8, fields.next() orelse return false, "128")) return false;
    };
    const layout = target.DataLayout.parse(text orelse "") catch return false;
    if ((layout.typeStoreSizeBytes(.x86_fp80) catch return false) != 10 or
        (layout.typeStoreSizeBytes(carrier) catch return false) != 10 or
        (layout.typeAllocSizeBytes(.x86_fp80) catch return false) != (layout.typeAllocSizeBytes(carrier) catch return false) or
        (layout.typeAllocSizeBytes(.x86_fp80) catch return false) != (layout.typeAllocSizeBytes(home) catch return false) or
        (layout.typeAbiAlignmentBits(.x86_fp80) catch return false) != (layout.typeAbiAlignmentBits(home) catch return false)) return false;
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed) continue;
        switch (inst.kind) {
            .alloca => |a| {
                if (a.allocated_ty == .x86_fp80) found = true;
            },
            .gep => |g| {
                if (g.source_ty == .x86_fp80) found = true;
            },
            .load => |l| if (l.ty == .x86_fp80) {
                if (!ordinary(l)) return false;
                found = true;
            },
            .store => |s| if (s.ty == .x86_fp80) {
                if (!ordinary(s)) return false;
                _ = value(s.value) catch return false;
                found = true;
            },
            .cast => |c| if (c.from_ty == .x86_fp80 or c.to_ty == .x86_fp80) {
                if (c.op != .bitcast or !(c.from_ty.eql(carrier) or c.to_ty.eql(carrier))) return false;
                if (c.from_ty == .x86_fp80) _ = value(c.value) catch return false;
                found = true;
            },
            .freeze => |f| if (f.ty == .x86_fp80) {
                _ = value(f.value) catch return false;
                found = true;
            },
            .select => |s| if (s.ty == .x86_fp80) {
                _ = value(s.true_value) catch return false;
                _ = value(s.false_value) catch return false;
                found = true;
            },
            .phi => |p| if (p.ty == .x86_fp80) {
                for (p.incoming.items) |incoming| _ = value(incoming.value) catch return false;
                found = true;
            },
            .call => |call| if (touches(inst)) {
                if (!callForm(call)) return false;
                found = true;
            },
            else => if (touches(inst)) return false,
        }
    };
    if (function.ret_ty == .x86_fp80) for (function.blocks.items) |block| if (block.terminator) |term| if (term == .ret) {
        _ = value(term.ret.value orelse return false) catch return false;
    };
    return found;
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if (!eligible(function, context)) return null;
    var candidate = Candidate.init(allocator, function);
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    if (function.ret_ty == .x86_fp80) {
        candidate.result.ret_ty = carrier;
        candidate.started = true;
    }
    for (function.params.items) |param| if (param.ty == .x86_fp80) {
        candidate.result.params = try function.params.clone(allocator);
        for (candidate.result.params.items) |*mapped| if (mapped.ty == .x86_fp80) {
            mapped.ty = carrier;
            mapped.abi_x87_memory = true;
        };
        candidate.started = true;
        break;
    };
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items, 0..) |inst, instruction_index| {
            var copy = inst;
            var changed = false;
            if (!inst.removed) switch (inst.kind) {
                .alloca => |a| if (a.allocated_ty == .x86_fp80) {
                    copy.kind.alloca.allocated_ty = home;
                    changed = true;
                },
                .gep => |g| if (g.source_ty == .x86_fp80) {
                    copy.kind.gep.source_ty = carrier;
                    changed = true;
                },
                .load => |l| if (l.ty == .x86_fp80) {
                    copy.kind.load.ty = carrier;
                    changed = true;
                },
                .store => |s| if (s.ty == .x86_fp80) {
                    copy.kind.store.ty = carrier;
                    copy.kind.store.value = try value(s.value);
                    changed = true;
                },
                .cast => |c| if (c.from_ty == .x86_fp80 or c.to_ty == .x86_fp80) {
                    copy.kind = .{ .binary = .{ .op = .add, .ty = carrier, .lhs = if (c.from_ty == .x86_fp80) try value(c.value) else c.value, .rhs = .{ .int = 0 } } };
                    changed = true;
                },
                .freeze => |f| if (f.ty == .x86_fp80) {
                    copy.kind.freeze.ty = carrier;
                    copy.kind.freeze.value = try value(f.value);
                    changed = true;
                },
                .select => |s| if (s.ty == .x86_fp80) {
                    copy.kind.select.ty = carrier;
                    copy.kind.select.true_value = try value(s.true_value);
                    copy.kind.select.false_value = try value(s.false_value);
                    changed = true;
                },
                .phi => |p| if (p.ty == .x86_fp80) {
                    copy.kind.phi.ty = carrier;
                    copy.kind.phi.incoming = try p.incoming.clone(allocator);
                    for (copy.kind.phi.incoming.items) |*incoming| incoming.value = try value(incoming.value);
                    changed = true;
                },
                .call => |call| if (touches(inst)) {
                    copy.kind.call.args = try call.args.clone(allocator);
                    for (copy.kind.call.args.items) |*arg| if (arg.ty == .x86_fp80) {
                        arg.ty = carrier;
                        arg.value = try value(arg.value);
                        arg.abi_x87_memory = true;
                    };
                    if (call.ret_ty == .x86_fp80) {
                        copy.kind.call.ret_ty = carrier;
                        copy.kind.call.ret_attrs = null;
                        copy.kind.call.abi_x87_return = true;
                    }
                    changed = true;
                },
                else => {},
            };
            if (changed) {
                try candidate.begin(&block, block_index, instruction_index);
                copy.metadata = null;
                try block.instructions.append(allocator, copy);
            } else try candidate.keep(&block, inst);
        }
        if (block.terminator) |*term| if (term.* == .ret and term.ret.ty == .x86_fp80) {
            term.ret.ty = carrier;
            const b: Builder = .{ .allocator = allocator, .function = function, .block = &block, .serial = &serial };
            term.ret.value = try b.returnValue(term.ret.value.?);
        };
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
