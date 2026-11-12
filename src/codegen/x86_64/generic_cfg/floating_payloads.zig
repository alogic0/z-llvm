//! Exact binary128 payloads through the existing native 128-bit XMM/vector
//! boundary. Arithmetic and numerical conversions retain separate contracts.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const addresses = @import("../symbol_address.zig");
const helpers = @import("composed_helpers.zig");
const forms = @import("scalar_forms.zig");

const carrier: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .double } };

fn mapped(ty: ir.Type, changed: *bool) ir.Type {
    if (ty != .fp128) return ty;
    changed.* = true;
    return carrier;
}

fn advisory(attrs: ?[]const u8) bool {
    return attrs == null or std.mem.eql(u8, std.mem.trim(u8, attrs.?, " \t"), "noundef");
}

fn needed(function: ir.Function) bool {
    if (function.ret_ty == .fp128) return true;
    for (function.params.items) |param| if (param.ty == .fp128) return true;
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed) continue;
        if (inst.resultType()) |ty| if (ty == .fp128) return true;
        switch (inst.kind) {
            .alloca => |x| if (x.allocated_ty == .fp128) return true,
            .gep => |x| if (x.source_ty == .fp128) return true,
            .store => |x| if (x.ty == .fp128) return true,
            .cast => |x| if (x.from_ty == .fp128) return true,
            .call => |x| for (x.args.items) |arg| {
                if (arg.ty == .fp128) return true;
            },
            else => {},
        }
    };
    return false;
}

fn value(allocator: std.mem.Allocator, source: ir.Value) !ir.Value {
    return switch (source) {
        .named, .undef, .poison, .zero_initializer => source,
        .fp => |text| blk: {
            const raw: u128 = if (std.mem.startsWith(u8, text, "0xL")) hex: {
                if (text.len != 35) return error.UnsupportedFloatingPayload;
                // LLVM's L spelling prints the low 64-bit word first.
                const lo = std.fmt.parseUnsigned(u64, text[3..19], 16) catch return error.UnsupportedFloatingPayload;
                const hi = std.fmt.parseUnsigned(u64, text[19..35], 16) catch return error.UnsupportedFloatingPayload;
                break :hex (@as(u128, hi) << 64) | lo;
            } else @bitCast(std.fmt.parseFloat(f128, text) catch return error.UnsupportedFloatingPayload);
            const lo: u64 = @truncate(raw);
            const hi: u64 = @truncate(raw >> 64);
            break :blk .{ .vector = try std.fmt.allocPrint(allocator, "<double 0x{X:0>16}, double 0x{X:0>16}>", .{ lo, hi }) };
        },
        else => error.UnsupportedFloatingPayload,
    };
}

const QuadUse = struct {
    pub const Error = error{};
    found: *bool,
    pub fn visit(self: QuadUse, _: *const ir.Value, ty: ir.Type) Error!void {
        if (ty == .fp128) self.found.* = true;
    }
};

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

    fn home(b: Builder) !ir.Value {
        return b.emit(.{ .alloca = .{ .allocated_ty = .{ .int = 128 }, .attrs = "align 16" } });
    }

    fn frozenHome(b: Builder, original: ir.Value) !ir.Value {
        const slot = try b.home();
        const input = if (original == .undef or original == .poison) ir.Value.zero_initializer else try value(b.allocator, original);
        try b.block.instructions.append(b.allocator, .{ .result = null, .kind = .{ .store = .{
            .ty = carrier,
            .value = input,
            .ptr = slot,
            .attrs = .{ .@"align" = 16 },
        } } });
        // Freezing both stored words chooses one stable whole payload. Every
        // defined source bit is retained, including all NaN representations.
        for (0..2) |word| {
            const ptr = if (word == 0) slot else ptr: {
                var indices: std.ArrayList(ir.GepIndex) = .empty;
                try indices.append(b.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 8 } });
                break :ptr try b.emit(.{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = slot, .indices = indices } });
            };
            const bits = try b.emit(.{ .load = .{ .ty = .{ .int = 64 }, .ptr = ptr, .attrs = .{ .@"align" = 8 } } });
            const frozen = try b.emit(.{ .freeze = .{ .ty = .{ .int = 64 }, .value = bits } });
            try b.block.instructions.append(b.allocator, .{ .result = null, .kind = .{ .store = .{
                .ty = .{ .int = 64 },
                .value = frozen,
                .ptr = ptr,
                .attrs = .{ .@"align" = 8 },
            } } });
        }
        return slot;
    }
};

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if (try nativeConstantReturns(allocator, function, context)) |candidate| return candidate;
    const quad = expand(allocator, function, context) catch |err| switch (err) {
        error.UnsupportedFloatingPayload => null,
        else => return err,
    };
    if (quad) |candidate| return candidate;
    if (try @import("half_memory.zig").legalize(allocator, function, context)) |candidate| return candidate;
    return @import("extended80_payloads.zig").legalize(allocator, function, context);
}

fn nativeConstantReturns(a: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if ((function.ret_ty != .half and function.ret_ty != .float and function.ret_ty != .double) or !advisory(function.ret_attrs) or
        !helpers.isDefaultOrFastcc(function.calling_conv) or !addresses.supportsLayout(if (context) |ctx| ctx.target_datalayout else null)) return null;
    var needed_return = false;
    for (function.blocks.items) |block| if (block.terminator) |term| if (term == .ret and term.ret.value != null and term.ret.value.? == .fp) {
        _ = @import("../../../analysis/fp_semantics.zig").scalarLiteralBits(term.ret.ty, term.ret.value.?.fp) catch return null;
        needed_return = true;
    };
    if (!needed_return) return null;
    var result = function;
    result.blocks = .empty;
    var names: forms.TemporaryNames = .{};
    defer names.deinit(a);
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = try original.instructions.clone(a);
        if (block.terminator) |*term| if (term.* == .ret and term.ret.value != null and term.ret.value.? == .fp) {
            const raw = try @import("../../../analysis/fp_semantics.zig").scalarLiteralBits(term.ret.ty, term.ret.value.?.fp);
            const wide: ir.Type = .{ .int = if (term.ret.ty == .double) 64 else 32 };
            const logical: ir.Type = .{ .int = if (term.ret.ty == .half) 16 else wide.int };
            const b: Builder = .{ .allocator = a, .function = function, .block = &block, .serial = &names };
            var bits = try b.emit(.{ .binary = .{ .op = .add, .ty = wide, .lhs = .{ .int = @intCast(raw) }, .rhs = .{ .int = 0 } } });
            if (!logical.eql(wide)) bits = try b.emit(.{ .cast = .{ .op = .trunc, .from_ty = wide, .value = bits, .to_ty = logical } });
            term.ret.value = try b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = logical, .value = bits, .to_ty = term.ret.ty } });
        };
        try result.blocks.append(a, block);
    }
    return result;
}

fn expand(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if (!needed(function) or !helpers.isDefaultOrFastcc(function.calling_conv) or
        !addresses.supportsLayout(if (context) |ctx| ctx.target_datalayout else null)) return null;
    if (context) |ctx| if (ctx.target_datalayout) |layout| {
        var parts = std.mem.splitScalar(u8, layout, '-');
        while (parts.next()) |part| if (part.len != 0 and part[0] == 'v') return null;
    };
    var changed = false;
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    var result = function;
    if (function.ret_ty == .fp128 and !advisory(function.ret_attrs)) return null;
    result.ret_ty = mapped(function.ret_ty, &changed);
    result.params = try function.params.clone(allocator);
    for (result.params.items) |*param| {
        if (param.ty == .fp128 and !advisory(param.attrs)) return null;
        param.ty = mapped(param.ty, &changed);
    }
    result.blocks = .empty;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        const b: Builder = .{ .allocator = allocator, .function = function, .block = &block, .serial = &serial };
        for (original.instructions.items) |inst| {
            var copy = inst;
            if (!inst.removed) switch (inst.kind) {
                .alloca => |alloca| copy.kind.alloca.allocated_ty = mapped(alloca.allocated_ty, &changed),
                .gep => |gep| copy.kind.gep.source_ty = mapped(gep.source_ty, &changed),
                .load => |load| if (load.ty == .fp128) {
                    if (load.attrs.isBarrier() or load.attrs.syncscope != null or load.ty_addrspace != null or load.ptr_addrspace != null) return error.UnsupportedFloatingPayload;
                    copy.kind.load.ty = mapped(load.ty, &changed);
                    copy.metadata = null;
                },
                .store => |store| if (store.ty == .fp128) {
                    if (store.attrs.isBarrier() or store.attrs.syncscope != null or store.ty_addrspace != null or store.ptr_addrspace != null) return error.UnsupportedFloatingPayload;
                    copy.kind.store.ty = mapped(store.ty, &changed);
                    copy.kind.store.value = try value(allocator, store.value);
                    copy.metadata = null;
                },
                .cast => |cast| if (cast.from_ty == .fp128 or cast.to_ty == .fp128) {
                    if (cast.op != .bitcast) return error.UnsupportedFloatingPayload;
                    copy.kind.cast.from_ty = mapped(cast.from_ty, &changed);
                    copy.kind.cast.to_ty = mapped(cast.to_ty, &changed);
                    if (cast.from_ty == .fp128) copy.kind.cast.value = try value(allocator, cast.value);
                    if (cast.from_ty.eql(.{ .int = 128 }) or cast.to_ty.eql(.{ .int = 128 })) {
                        // Reinterpret through an owned, exact-size home. The
                        // ordinary vector and pair storage contracts preserve
                        // all bits without scalar floating conversions.
                        const slot = try b.home();
                        try block.instructions.append(allocator, .{ .result = null, .kind = .{ .store = .{
                            .ty = copy.kind.cast.from_ty,
                            .value = copy.kind.cast.value,
                            .ptr = slot,
                            .attrs = .{ .@"align" = 16 },
                        } } });
                        const target_ty = copy.kind.cast.to_ty;
                        copy.kind = .{ .load = .{ .ty = target_ty, .ptr = slot, .attrs = .{ .@"align" = 16 } } };
                    }
                    copy.metadata = null;
                },
                .freeze => |freeze| if (freeze.ty == .fp128) {
                    const target_ty = mapped(freeze.ty, &changed);
                    const slot = try b.frozenHome(freeze.value);
                    copy.kind = .{ .load = .{ .ty = target_ty, .ptr = slot, .attrs = .{ .@"align" = 16 } } };
                    copy.metadata = null;
                },
                .select => |select| if (select.ty == .fp128) {
                    copy.kind.select.ty = mapped(select.ty, &changed);
                    copy.kind.select.true_value = try value(allocator, select.true_value);
                    copy.kind.select.false_value = try value(allocator, select.false_value);
                    copy.metadata = null;
                },
                .phi => |phi| if (phi.ty == .fp128) {
                    copy.kind.phi.ty = mapped(phi.ty, &changed);
                    copy.kind.phi.incoming = try phi.incoming.clone(allocator);
                    for (copy.kind.phi.incoming.items) |*incoming| incoming.value = try value(allocator, incoming.value);
                    copy.metadata = null;
                },
                .call => |call| {
                    var has_quad = call.ret_ty == .fp128;
                    for (call.args.items) |arg| has_quad = has_quad or arg.ty == .fp128;
                    if (has_quad) {
                        if (!helpers.isDefaultOrFastcc(call.calling_conv) or call.callee_value != null or call.inline_asm != null or
                            call.raw_args != null or call.operand_bundle != null or call.callee_function_ty != null or
                            std.mem.startsWith(u8, call.callee, "llvm.")) return error.UnsupportedFloatingPayload;
                        if (call.tail_kind) |tail| {
                            if (std.mem.eql(u8, tail, "musttail")) return error.UnsupportedFloatingPayload;
                            // A tail hint does not require a tail call. The
                            // immutable source retains its original spelling.
                            copy.kind.call.tail_kind = null;
                        }
                        if (call.ret_ty == .fp128 and !advisory(call.ret_attrs)) return error.UnsupportedFloatingPayload;
                        copy.kind.call.ret_ty = mapped(call.ret_ty, &changed);
                        copy.kind.call.args = try call.args.clone(allocator);
                        for (copy.kind.call.args.items) |*arg| if (arg.ty == .fp128) {
                            if (!advisory(arg.attrs)) return error.UnsupportedFloatingPayload;
                            arg.ty = mapped(arg.ty, &changed);
                            arg.value = try value(allocator, arg.value);
                        };
                        copy.metadata = null;
                    }
                },
                else => {
                    var touches = if (inst.resultType()) |ty| ty == .fp128 else false;
                    _ = ir.operands.instruction(&inst, QuadUse{ .found = &touches }) catch unreachable;
                    if (touches) return error.UnsupportedFloatingPayload;
                },
            };
            try block.instructions.append(allocator, copy);
        }
        if (block.terminator) |*term| if (term.* == .ret and term.ret.ty == .fp128) {
            term.ret.ty = mapped(term.ret.ty, &changed);
            if (term.ret.value) |source| term.ret.value = try value(allocator, source);
        };
        try result.blocks.append(allocator, block);
    }
    return if (changed) result else null;
}
