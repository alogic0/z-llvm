const std = @import("std");
const ir = @import("../ir.zig");
const references = @import("../analysis/module_references.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "globalopt",
    .category = .ipo,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/IPO/GlobalOpt.cpp",
    .run = run,
};

fn run(module: *ir.Module, context: *pass_manager.Context) !pass_manager.PassResult {
    var reference_context = try references.Context.init(context.allocator, module);
    defer reference_context.deinit();
    var changed = false;
    var index: usize = 0;
    while (index < module.globals.items.len) {
        const global = module.globals.items[index];
        const initializer = eligibleInitializer(global) orelse {
            index += 1;
            continue;
        };
        if (!allUsesAreDirectLoads(&reference_context, global)) {
            index += 1;
            continue;
        }

        const removed_loads = replaceDirectLoads(module, global, initializer);
        if (removed_loads == 0) {
            index += 1;
            continue;
        }

        if (!reference_context.query(global.name).mayReference()) {
            var removed = module.globals.orderedRemove(index);
            removed.deinit(module.allocator);
        } else {
            index += 1;
        }
        changed = true;
    }

    return if (changed) .changed else .unchanged;
}

fn eligibleInitializer(global: ir.Global) ?ir.Value {
    if (!isLocal(global.linkage)) return null;
    if (global.kind != .global) return null;
    if (hasComdat(global.attrs) or isThreadLocal(global)) return null;
    const scalar = switch (global.initializer) {
        .scalar => |value| value,
        .none, .array, .c_string, .@"opaque" => return null,
    };
    if (!isLoadFoldableScalar(scalar)) return null;
    return scalar;
}

const DirectLoadUses = struct {
    pub const Error = error{};
    global: ir.Global,
    loads: *usize,
    blocked: *bool,

    pub fn visit(uses: DirectLoadUses, site: references.Site, event: references.Event) Error!void {
        switch (event) {
            .unknown, .block_address => uses.blocked.* = true,
            .symbol => |name| {
                if (!ir.identifiers.eql(name, uses.global.name)) return;
                if (site == .instruction and site.instruction.kind == .load) {
                    const load = site.instruction.kind.load;
                    if (!load.attrs.isBarrier() and load.ty.eql(uses.global.ty) and references.isDirectValue(load.ptr, name)) {
                        uses.loads.* += 1;
                        return;
                    }
                }
                uses.blocked.* = true;
            },
        }
    }
};

fn allUsesAreDirectLoads(context: *const references.Context, global: ir.Global) bool {
    var loads: usize = 0;
    var blocked = false;
    context.walkModule(DirectLoadUses{ .global = global, .loads = &loads, .blocked = &blocked }) catch unreachable;
    return !blocked and loads != 0;
}

fn replaceDirectLoads(module: *ir.Module, global: ir.Global, initializer: ir.Value) usize {
    var removed_loads: usize = 0;
    for (module.functions.items) |*function| {
        for (function.blocks.items) |*block| {
            for (block.instructions.items) |*instruction| {
                if (instruction.removed) continue;
                const load = switch (instruction.kind) {
                    .load => |load| load,
                    .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => continue,
                };
                if (!references.isDirectValue(load.ptr, global.name)) continue;
                const result = instruction.result orelse continue;
                instruction.removed = true;
                instruction.replacement = initializer;
                // Escape eligibility is decided by the shared reference walk.
                _ = ir.operands.replaceAllUses(function, result, initializer);
                removed_loads += 1;
            }
        }
    }
    return removed_loads;
}

fn isLoadFoldableScalar(value: ir.Value) bool {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer => true,
        .named, .vector, .constant_expr => false,
    };
}

fn isLocal(linkage: ir.FunctionLinkage) bool {
    return linkage == .internal or linkage == .private;
}

fn hasComdat(attrs: ?[]const u8) bool {
    return if (attrs) |text| std.mem.indexOf(u8, text, "comdat") != null else false;
}

fn isThreadLocal(global: ir.Global) bool {
    return if (global.address_attrs) |text| std.mem.indexOf(u8, text, "thread_local") != null else false;
}
