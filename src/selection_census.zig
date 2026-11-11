//! Diagnostic-only complete selection census with final composed rejection context.
//! Usage: zig run -O ReleaseFast src/selection_census.zig -- INPUT OUTPUT [FUNCTION|@JSON_NAMES]
const std = @import("std");
const ir = @import("ir.zig");
const compilation = @import("compilation.zig");
const x86 = @import("codegen/x86_64.zig");
const observations = @import("codegen/x86_64/generic_cfg/rejection_observer.zig");

const Capture = struct {
    arena: std.heap.ArenaAllocator,
    payload: ?[]const u8 = null,
    tag: ?[]const u8 = null,
    detail: ?[]const u8 = null,

    fn reset(context: *anyopaque) void {
        const capture: *Capture = @ptrCast(@alignCast(context));
        _ = capture.arena.reset(.retain_capacity);
        capture.payload = null;
        capture.tag = null;
        capture.detail = null;
    }

    fn origin(function: ir.Function, value: ir.Value) []const u8 {
        if (value != .named) return @tagName(value);
        if (std.mem.startsWith(u8, value.named, "@")) return "global-symbol";
        for (function.params.items) |param| if (ir.identifiers.eql(param.name, value.named)) return "parameter";
        for (function.blocks.items) |block| for (block.instructions.items) |inst| {
            if (!inst.removed and inst.result != null and ir.identifiers.eql(inst.result.?, value.named)) return @tagName(inst.kind);
        };
        return "unresolved-name";
    }

    fn reject(context: *anyopaque, rejection: observations.Rejection) !void {
        const capture: *Capture = @ptrCast(@alignCast(context));
        reset(context);
        const a = capture.arena.allocator();
        const Operand = struct { type: []const u8, attrs: ?[]const u8, value: []const u8, location: ?[]const u8, origin: []const u8 };
        const operands = try a.alloc(Operand, rejection.operands.len);
        for (rejection.operands, operands) |operand, *out| out.* = .{
            .type = try std.fmt.allocPrint(a, "{f}", .{operand.argument.ty}),
            .attrs = operand.argument.attrs,
            .value = try std.fmt.allocPrint(a, "{f}", .{operand.argument.value}),
            .location = operand.location,
            .origin = origin(rejection.function, operand.argument.value),
        };
        capture.payload = try std.json.Stringify.valueAlloc(a, .{
            .operand_traces = trace: {
                const traces = try a.alloc([]const u8, rejection.operands.len);
                for (rejection.operands, traces) |operand, *out| out.* = try indexTrace(a, rejection.function, operand.argument.value, 0);
                break :trace traces;
            },
            .position = rejection.position,
            .pressure = rejection.pressure,
            .selector_tag = rejection.tag,
            .selector_detail = rejection.detail,
            .function_return_type = try std.fmt.allocPrint(a, "{f}", .{rejection.function.ret_ty}),
            .function_return_attrs = rejection.function.ret_attrs,
            .function_calling_convention = rejection.function.calling_conv,
            .parameter = if (rejection.parameter) |param| .{ .name = param.name, .type = try std.fmt.allocPrint(a, "{f}", .{param.ty}), .attrs = param.attrs } else null,
            .definition = if (rejection.definition) |definition| .{
                .kind = @tagName(definition.kind),
                .result = definition.result,
                .type = if (definition.resultType()) |ty| try std.fmt.allocPrint(a, "{f}", .{ty}) else null,
                .callee = if (definition.kind == .call) definition.kind.call.callee else null,
                .allocated_type = if (definition.kind == .alloca) try std.fmt.allocPrint(a, "{f}", .{definition.kind.alloca.allocated_ty}) else null,
                .allocation_attrs = if (definition.kind == .alloca) definition.kind.alloca.attrs else null,
                .operation = switch (definition.kind) {
                    .binary => |binary| @tagName(binary.op),
                    .cast => |cast| @tagName(cast.op),
                    else => null,
                },
                .operands = operands,
            } else null,
            .comparison = if (rejection.comparison) |comparison| .{
                .predicate = @tagName(comparison.predicate),
                .samesign = comparison.samesign,
                .type = try std.fmt.allocPrint(a, "{f}", .{comparison.operand_ty}),
                .result = rejection.result,
                .operands = operands,
            } else null,
            .freeze = if (rejection.definition != null and rejection.definition.?.kind == .freeze) .{
                .type = try std.fmt.allocPrint(a, "{f}", .{rejection.definition.?.kind.freeze.ty}),
                .result = rejection.result,
                .operand = if (operands.len == 1) operands[0] else null,
            } else null,
            .global_address = if (rejection.global_address) |address| .{
                .symbol = address.symbol,
                .addend = address.addend,
                .resolved_global = address.global.name,
                .linkage = @tagName(address.global.linkage),
                .kind = @tagName(address.global.kind),
                .type = try std.fmt.allocPrint(a, "{f}", .{address.global.ty}),
                .address_attrs = address.global.address_attrs,
                .attrs = address.global.attrs,
                .property_failure = address.property_failure,
            } else null,
            .readonly_table = if (rejection.readonly_table) |table| .{
                .index_trace = if (table.gep.indices.items.len == 1) try indexTrace(a, rejection.function, table.gep.indices.items[0].value, 0) else "multiple indices",
                .result = rejection.result,
                .source_type = try std.fmt.allocPrint(a, "{f}", .{table.gep.source_ty}),
                .pointer = try std.fmt.allocPrint(a, "{f}", .{table.gep.ptr}),
                .pointer_addrspace = table.gep.ptr_addrspace,
                .indices = operands,
                .decode_error = table.decode_error,
                .global = if (table.global) |global| .{
                    .name = global.name,
                    .type = try std.fmt.allocPrint(a, "{f}", .{global.ty}),
                    .kind = @tagName(global.kind),
                    .linkage = @tagName(global.linkage),
                    .address_attrs = global.address_attrs,
                    .attrs = global.attrs,
                    .initializer = @tagName(global.initializer),
                } else null,
            } else null,
            .call = if (rejection.call) |call| .{
                .callee = call.callee,
                .indirect = call.callee_value != null,
                .return_type = try std.fmt.allocPrint(a, "{f}", .{call.ret_ty}),
                .return_attrs = call.ret_attrs,
                .calling_convention = call.calling_conv,
                .tail_kind = call.tail_kind,
                .callee_function_type = call.callee_function_ty,
                .inline_asm = call.inline_asm,
                .attributes = call.attrs,
                .operand_bundle = call.operand_bundle,
                .result = rejection.result,
                .arguments = operands,
            } else null,
        }, .{});
        capture.tag = rejection.tag;
        capture.detail = rejection.detail;
    }

    fn indexTrace(a: std.mem.Allocator, function: ir.Function, value: ir.Value, depth: u8) anyerror![]const u8 {
        if (value == .int) return std.fmt.allocPrint(a, "{d}", .{value.int});
        if (value != .named) return @tagName(value);
        const name = value.named[0..@min(value.named.len, 160)];
        if (depth >= 8) return name;
        for (function.blocks.items) |block| for (block.instructions.items) |inst| {
            if (inst.removed or inst.result == null or !ir.identifiers.eql(inst.result.?, value.named)) continue;
            return switch (inst.kind) {
                .cast => |cast| std.fmt.allocPrint(a, "{s}={s}({s})", .{ name, @tagName(cast.op), try indexTrace(a, function, cast.value, depth + 1) }),
                .binary => |binary| std.fmt.allocPrint(a, "{s}={s}({s},{s})", .{ name, @tagName(binary.op), try indexTrace(a, function, binary.lhs, depth + 1), try indexTrace(a, function, binary.rhs, depth + 1) }),
                else => std.fmt.allocPrint(a, "{s}={s}", .{ name, @tagName(inst.kind) }),
            };
        };
        return name;
    }

    fn matches(capture: Capture, tag: ?[]const u8, detail: ?[]const u8) bool {
        return capture.payload != null and tag != null and detail != null and
            std.mem.eql(u8, capture.tag.?, tag.?) and std.mem.eql(u8, capture.detail.?, detail.?);
    }
};

pub fn main(init: std.process.Init) !void {
    const a = init.gpa;
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 3 or args.len > 4) return error.ExpectedInputOutputAndOptionalFunction;
    const names: ?[]const []const u8 = if (args.len == 4 and std.mem.startsWith(u8, args[3], "@")) blk: {
        const arena = init.arena.allocator();
        const bytes = try std.Io.Dir.cwd().readFileAlloc(init.io, args[3][1..], arena, .limited(16 * 1024 * 1024));
        const parsed = try std.json.parseFromSliceLeaky([]const []const u8, arena, bytes, .{});
        if (parsed.len == 0) return error.EmptySelectionFilter;
        for (parsed, 0..) |name, index| {
            if (!ir.identifiers.isValid(name)) return error.InvalidSelectionFilter;
            for (parsed[0..index]) |previous| if (ir.identifiers.eql(name, previous)) return error.DuplicateSelectionFilter;
        }
        break :blk parsed;
    } else null;
    const input = try std.Io.Dir.cwd().readFileAlloc(init.io, args[1], a, .limited(2 * 1024 * 1024 * 1024));
    defer a.free(input);
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(input, &digest, .{});
    var module = try ir.Module.parse(a, input);
    defer module.deinit();
    try module.verify();
    const file = try std.Io.Dir.cwd().createFile(init.io, args[2], .{ .exclusive = true });
    defer file.close(init.io);
    var buffer: [65536]u8 = undefined;
    var output = file.writerStreaming(init.io, &buffer);
    const writer = &output.interface;
    try std.json.Stringify.value(.{ .event = "begin", .schema = "selection-rejection-census-v1", .input_sha256 = std.fmt.bytesToHex(digest, .lower), .definitions = module.functions.items.len, .filter = if (args.len == 4) args[3] else null, .filter_functions = names, .scope = "function selection and final composed rejection context; no complete object or execution credit" }, .{}, writer);
    try writer.writeByte('\n');
    try writer.flush();
    const context: x86.ReadOnlyModuleContext = .{
        .globals = module.globals.items,
        .aliases = module.aliases.items,
        .named_types = module.named_types.items,
        .target_datalayout = module.target_datalayout,
        .functions = module.functions.items,
        .declarations = module.declarations.items,
        .emit_all_globals = true,
        .require_resolved_aliases = true,
    };
    var capture: Capture = .{ .arena = std.heap.ArenaAllocator.init(a) };
    defer capture.arena.deinit();
    var observer: observations.Observer = .{ .context = &capture, .reset_fn = Capture.reset, .reject_fn = Capture.reject };
    var selected: usize = 0;
    var failed: usize = 0;
    for (module.functions.items) |function| {
        if (names) |filters| {
            const matches = for (filters) |name| {
                if (ir.identifiers.eql(function.name, name)) break true;
            } else false;
            if (!matches) continue;
        } else if (args.len == 4 and !ir.identifiers.eql(function.name, args[3])) continue;
        Capture.reset(&capture);
        var tag: ?[]const u8 = null;
        var detail: ?[]const u8 = null;
        var machine = compilation.select(a, "x86_64-unknown-linux-gnu", function, .{
            .generic_cfg_selector = true,
            .module_context = &context,
            .generic_cfg_selector_diagnostic_tag = &tag,
            .generic_cfg_selector_diagnostic_detail = &detail,
            .rejection_observer = &observer,
        }) catch |err| {
            if (err == error.OutOfMemory) return err;
            failed += 1;
            try writer.writeAll("{\"event\":\"function\",\"selected\":false,\"function\":");
            try std.json.Stringify.value(function.name, .{}, writer);
            try writer.writeAll(",\"diagnostic\":");
            try std.json.Stringify.value(@errorName(err), .{}, writer);
            try writer.writeAll(",\"selector_tag\":");
            try std.json.Stringify.value(tag, .{}, writer);
            try writer.writeAll(",\"selector_detail\":");
            try std.json.Stringify.value(detail, .{}, writer);
            try writer.writeAll(",\"rejection\":");
            try writer.writeAll(if (capture.matches(tag, detail)) capture.payload.? else "null");
            try writer.writeAll("}\n");
            try writer.flush();
            continue;
        };
        defer machine.deinit(a);
        selected += 1;
        try std.json.Stringify.value(.{ .event = "function", .function = function.name, .selected = true, .owner = @tagName(machine.selection_owner) }, .{}, writer);
        try writer.writeByte('\n');
        try writer.flush();
    }
    if (selected + failed == 0) return error.EmptySelection;
    if (names) |filters| if (selected + failed != filters.len) return error.SelectionFilterNotFound;
    try std.json.Stringify.value(.{ .event = "complete", .examined = selected + failed, .selected = selected, .failed = failed }, .{}, writer);
    try writer.writeByte('\n');
    try writer.flush();
}

test "selection census retains rejected freeze type location and value after rollback" {
    const text =
        \\define float @observed(float %input) {
        \\entry:
        \\ %frozen = freeze float %input
        \\ ret float %frozen
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var capture: Capture = .{ .arena = std.heap.ArenaAllocator.init(std.testing.allocator) };
    defer capture.arena.deinit();
    var observer: observations.Observer = .{ .context = &capture, .reset_fn = Capture.reset, .reject_fn = Capture.reject };
    var output = x86.MachineFunction.init("observed", .float);
    defer output.deinit(std.testing.allocator);
    var dependencies: @import("codegen/x86_64/generic_cfg/composed_selector_address_dependencies.zig").AddressDependencyDomain = .{};
    const result = try @import("codegen/x86_64/generic_cfg/composed_selector.zig").tryLowerComposedCfgObserved(std.testing.allocator, &output, module.functions.items[0], null, &dependencies, &observer);
    try std.testing.expect(result == .unsupported);
    try std.testing.expectEqualStrings("composed-block-freeze-type", result.unsupported.detail());
    try std.testing.expect(capture.matches(result.unsupported.tagName(), result.unsupported.detail()));
    const payload = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, capture.payload.?, .{});
    defer payload.deinit();
    const freeze = payload.value.object.get("freeze").?.object;
    try std.testing.expectEqualStrings("float", freeze.get("type").?.string);
    try std.testing.expectEqualStrings("frozen", freeze.get("result").?.string);
    const operand = freeze.get("operand").?.object;
    try std.testing.expectEqualStrings("%input", operand.get("value").?.string);
    try std.testing.expectEqualStrings("xmm", operand.get("location").?.string);
    try std.testing.expectEqualStrings("parameter", operand.get("origin").?.string);
    try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
    observations.Observer.reset(&observer);
    try std.testing.expect(capture.payload == null);
}

test "selection census retains final private call context and clears stale attempts" {
    const text =
        \\declare i32 @llvm.census.unsupported.i32(i32, i32)
        \\define i32 @observed(i1 %flag, i32 %word) {
        \\entry:
        \\  %flip = xor i1 %flag, 1
        \\  %wide = zext i1 %flip to i32
        \\  %result = call i32 @llvm.census.unsupported.i32(i32 %word, i32 %wide)
        \\  ret i32 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var capture: Capture = .{ .arena = std.heap.ArenaAllocator.init(std.testing.allocator), .payload = "stale" };
    defer capture.arena.deinit();
    var observer: observations.Observer = .{ .context = &capture, .reset_fn = Capture.reset, .reject_fn = Capture.reject };
    var output = x86.MachineFunction.init("observed", .{ .int = 32 });
    defer output.deinit(std.testing.allocator);
    const selector = @import("codegen/x86_64/generic_cfg_selector.zig");
    const result = try selector.tryLowerObserved(std.testing.allocator, &output, module.functions.items[0], null, null, &observer);
    try std.testing.expect(result == .unsupported);
    try std.testing.expect(capture.matches(result.unsupported.tagName(), result.unsupported.detail()));
    try std.testing.expectEqualStrings("composed-block-llvm-intrinsic", result.unsupported.detail());
    try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
    const payload = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, capture.payload.?, .{});
    defer payload.deinit();
    const call = payload.value.object.get("call").?.object;
    try std.testing.expectEqualStrings("llvm.census.unsupported.i32", call.get("callee").?.string);
    try std.testing.expectEqualStrings("i32", call.get("return_type").?.string);
    try std.testing.expectEqualStrings("arg32", call.get("arguments").?.array.items[0].object.get("location").?.string);
    try std.testing.expect(payload.value.object.get("position").?.integer > 3);
    // Private names and lists have already been freed; the retained JSON owns
    // all of its text. Reset must also prevent a different final tag matching.
    try std.testing.expect(!capture.matches("no_spill_envelope", "stage2-register-pressure"));
    observations.Observer.reset(&observer);
    try std.testing.expect(capture.payload == null);
}

test "selection census owns rejected assembly templates constraints and typed facts" {
    const text =
        \\define i64 @observed(i64 %word) {
        \\entry:
        \\  br label %body
        \\body:
        \\  %result = tail call i64 asm sideeffect "syscall; nop", "={rax},{rax},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 range(i64 0, 1024) %word)
        \\  ret i64 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var capture: Capture = .{ .arena = std.heap.ArenaAllocator.init(std.testing.allocator) };
    defer capture.arena.deinit();
    var observer: observations.Observer = .{ .context = &capture, .reset_fn = Capture.reset, .reject_fn = Capture.reject };
    var output = x86.MachineFunction.init("observed", .{ .int = 64 });
    defer output.deinit(std.testing.allocator);
    var dependencies: @import("codegen/x86_64/generic_cfg/composed_selector_address_dependencies.zig").AddressDependencyDomain = .{};
    const result = try @import("codegen/x86_64/generic_cfg/composed_selector.zig").tryLowerComposedCfgObserved(std.testing.allocator, &output, module.functions.items[0], null, &dependencies, &observer);
    try std.testing.expect(result == .unsupported);
    try std.testing.expect(capture.matches(result.unsupported.tagName(), result.unsupported.detail()));
    const payload = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, capture.payload.?, .{});
    defer payload.deinit();
    const call = payload.value.object.get("call").?.object;
    const assembly = call.get("inline_asm").?.object;
    try std.testing.expectEqualStrings("syscall; nop", assembly.get("template").?.string);
    try std.testing.expectEqualStrings("={rax},{rax},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}", assembly.get("constraints").?.string);
    try std.testing.expect(assembly.get("sideeffect").?.bool);
    try std.testing.expect(assembly.get("has_memory_clobber").?.bool);
    try std.testing.expectEqualStrings("tail", call.get("tail_kind").?.string);
    try std.testing.expectEqualStrings("range(i64 0, 1024)", call.get("arguments").?.array.items[0].object.get("attrs").?.string);
    try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
    observations.Observer.reset(&observer);
    try std.testing.expect(capture.payload == null);
}

test "selection census observer preserves selected machine bytes" {
    const text =
        \\define i32 @selected(i1 %flag) {
        \\entry:
        \\  %flip = xor i1 %flag, 1
        \\  %result = zext i1 %flip to i32
        \\  ret i32 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var capture: Capture = .{ .arena = std.heap.ArenaAllocator.init(std.testing.allocator) };
    defer capture.arena.deinit();
    var observer: observations.Observer = .{ .context = &capture, .reset_fn = Capture.reset, .reject_fn = Capture.reject };
    var observed = try compilation.select(std.testing.allocator, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true, .rejection_observer = &observer });
    defer observed.deinit(std.testing.allocator);
    var plain = try compilation.select(std.testing.allocator, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true });
    defer plain.deinit(std.testing.allocator);
    const encoding = @import("mc/encoding.zig");
    const observed_bytes = try encoding.encodeFunction(std.testing.allocator, observed);
    defer std.testing.allocator.free(observed_bytes);
    const plain_bytes = try encoding.encodeFunction(std.testing.allocator, plain);
    defer std.testing.allocator.free(plain_bytes);
    try std.testing.expectEqualSlices(u8, plain_bytes, observed_bytes);
    try std.testing.expectEqual(plain.selection_owner, observed.selection_owner);
    try std.testing.expect(capture.payload == null);
}

test "selection census retains rejected comparison operands after rollback" {
    const text =
        \\@data = external global i8
        \\define i1 @observed(ptr %p) {
        \\entry:
        \\  br label %body
        \\body:
        \\  %result = icmp eq ptr %p, getelementptr (i8, ptr @data, i64 3)
        \\  ret i1 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var capture: Capture = .{ .arena = std.heap.ArenaAllocator.init(std.testing.allocator) };
    defer capture.arena.deinit();
    var observer: observations.Observer = .{ .context = &capture, .reset_fn = Capture.reset, .reject_fn = Capture.reject };
    var output = x86.MachineFunction.init("observed", .{ .int = 1 });
    defer output.deinit(std.testing.allocator);
    var dependencies: @import("codegen/x86_64/generic_cfg/composed_selector_address_dependencies.zig").AddressDependencyDomain = .{};
    const result = try @import("codegen/x86_64/generic_cfg/composed_selector.zig").tryLowerComposedCfgObserved(std.testing.allocator, &output, module.functions.items[0], null, &dependencies, &observer);
    try std.testing.expect(result == .unsupported);
    try std.testing.expect(capture.matches(result.unsupported.tagName(), result.unsupported.detail()));
    const payload = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, capture.payload.?, .{});
    defer payload.deinit();
    const comparison = payload.value.object.get("comparison").?.object;
    try std.testing.expectEqualStrings("eq", comparison.get("predicate").?.string);
    try std.testing.expectEqualStrings("ptr", comparison.get("type").?.string);
    const operands = comparison.get("operands").?.array.items;
    try std.testing.expectEqual(@as(usize, 2), operands.len);
    try std.testing.expectEqualStrings("parameter", operands[0].object.get("origin").?.string);
    try std.testing.expectEqualStrings("constant_expr", operands[1].object.get("origin").?.string);
    try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
    observations.Observer.reset(&observer);
    try std.testing.expect(capture.payload == null);
}

test "selection census identifies allocation-plan representation failures" {
    const text =
        \\define i32 @observed(ptr %p) {
        \\entry:
        \\  %wide = load x86_fp80, ptr %p, align 16
        \\  ret i32 0
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var capture: Capture = .{ .arena = std.heap.ArenaAllocator.init(std.testing.allocator) };
    defer capture.arena.deinit();
    var observer: observations.Observer = .{ .context = &capture, .reset_fn = Capture.reset, .reject_fn = Capture.reject };
    try std.testing.expectError(error.UnsupportedCodegenValue, @import("codegen/x86_64/generic_cfg/stage2_planning.zig").buildSelectorAllocationPlanObserved(std.testing.allocator, module.functions.items[0], &observer));
    try std.testing.expect(capture.matches("unsupported_value", "stage2-unsupported-value"));
    const payload = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, capture.payload.?, .{});
    defer payload.deinit();
    const definition = payload.value.object.get("definition").?.object;
    try std.testing.expectEqualStrings("load", definition.get("kind").?.string);
    try std.testing.expectEqualStrings("wide", definition.get("result").?.string);
    try std.testing.expectEqualStrings("x86_fp80", definition.get("type").?.string);
    observations.Observer.reset(&observer);
    try std.testing.expect(capture.payload == null);
}

test "selection census copies resolved global properties and original alias identity" {
    const text =
        \\@data = internal thread_local(initialexec) global i64 0, align 8
        \\@alias = internal alias i64, ptr @data
        \\define ptr @observed() {
        \\entry:
        \\  %result = getelementptr i8, ptr @alias, i64 3
        \\  ret ptr %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const context: x86.ReadOnlyModuleContext = .{
        .globals = module.globals.items,
        .aliases = module.aliases.items,
        .named_types = module.named_types.items,
        .target_datalayout = module.target_datalayout,
        .require_resolved_aliases = true,
    };
    var capture: Capture = .{ .arena = std.heap.ArenaAllocator.init(std.testing.allocator) };
    defer capture.arena.deinit();
    var observer: observations.Observer = .{ .context = &capture, .reset_fn = Capture.reset, .reject_fn = Capture.reject };
    var machine = x86.MachineFunction.init("observed", .ptr);
    defer machine.deinit(std.testing.allocator);
    const result = try @import("codegen/x86_64/generic_cfg_selector.zig").tryLowerObserved(std.testing.allocator, &machine, module.functions.items[0], &context, null, &observer);
    try std.testing.expect(result == .unsupported);
    try std.testing.expect(capture.matches(result.unsupported.tagName(), result.unsupported.detail()));
    const payload = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, capture.payload.?, .{});
    defer payload.deinit();
    const address = payload.value.object.get("global_address").?.object;
    try std.testing.expectEqualStrings("alias", address.get("symbol").?.string);
    try std.testing.expectEqualStrings("data", address.get("resolved_global").?.string);
    try std.testing.expectEqualStrings("thread_local(initialexec)", address.get("address_attrs").?.string);
    try std.testing.expectEqualStrings("align 8", address.get("attrs").?.string);
    try std.testing.expectEqualStrings("UnsupportedGlobalAddressAttribute", address.get("property_failure").?.string);
    try std.testing.expectEqual(@as(i64, 3), address.get("addend").?.integer);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    observations.Observer.reset(&observer);
    try std.testing.expect(capture.payload == null);
}

test "selection census retains rejected table representation without changing selection" {
    // Quoted globals now select with a 64-bit layout. Keep the observer's
    // rejection proof on the unsupported 32-bit address-layout boundary.
    const text =
        \\target datalayout = "e-p:32:32-i64:64"
        \\@"table bytes" = internal constant [8 x i8] zeroinitializer, align 8
        \\declare void @witness(ptr)
        \\define ptr @table(i64 %index) {
        \\entry:
        \\ %result = getelementptr i8, ptr @"table bytes", i64 %index
        \\ call void @witness(ptr %result)
        \\ ret ptr %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const context: x86.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    var capture: Capture = .{ .arena = std.heap.ArenaAllocator.init(std.testing.allocator) };
    defer capture.arena.deinit();
    var observer: observations.Observer = .{ .context = &capture, .reset_fn = Capture.reset, .reject_fn = Capture.reject };
    var machine = x86.MachineFunction.init("table", .ptr);
    defer machine.deinit(std.testing.allocator);
    const selector = @import("codegen/x86_64/generic_cfg_selector.zig");
    const observed = try selector.tryLowerObserved(std.testing.allocator, &machine, module.functions.items[0], &context, null, &observer);
    try std.testing.expect(observed == .unsupported);
    try std.testing.expect(capture.matches(observed.unsupported.tagName(), observed.unsupported.detail()));
    try std.testing.expectEqualStrings("composed-block-gep-readonly-table-global", observed.unsupported.detail());
    const plain = try selector.tryLowerWithContext(std.testing.allocator, &machine, module.functions.items[0], &context);
    try std.testing.expect(plain == .unsupported);
    try std.testing.expectEqualStrings(observed.unsupported.detail(), plain.unsupported.detail());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    const payload = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, capture.payload.?, .{});
    defer payload.deinit();
    const table = payload.value.object.get("readonly_table").?.object;
    try std.testing.expectEqualStrings("i8", table.get("source_type").?.string);
    try std.testing.expectEqualStrings("@\"table bytes\"", table.get("pointer").?.string);
    try std.testing.expectEqualStrings("[8 x i8]", table.get("global").?.object.get("type").?.string);
    try std.testing.expectEqualStrings("scalar", table.get("global").?.object.get("initializer").?.string);
    try std.testing.expectEqualStrings("i64", table.get("indices").?.array.items[0].object.get("type").?.string);
    try std.testing.expectEqualStrings("parameter", table.get("indices").?.array.items[0].object.get("origin").?.string);
    observations.Observer.reset(&observer);
    try std.testing.expect(capture.payload == null);
}

test "selection census observes concrete frame rejection and preserves rollback" {
    const text =
        \\define i64 @too_large(i64 %value) {
        \\entry:
        \\  %buffer = alloca [2097152 x i32], align 16
        \\  br label %exit
        \\exit:
        \\  ret i64 %value
        \\}
        \\define i64 @small(i64 %value) {
        \\entry:
        \\  %result = add i64 %value, 1
        \\  ret i64 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var capture: Capture = .{ .arena = std.heap.ArenaAllocator.init(std.testing.allocator), .payload = "stale" };
    defer capture.arena.deinit();
    var observer: observations.Observer = .{ .context = &capture, .reset_fn = Capture.reset, .reject_fn = Capture.reject };
    var machine = x86.MachineFunction.init("too_large", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    const selector = @import("codegen/x86_64/generic_cfg_selector.zig");
    const result = try selector.tryLowerObserved(std.testing.allocator, &machine, module.functions.items[0], null, null, &observer);
    try std.testing.expect(result == .unsupported);
    try std.testing.expectEqualStrings("composed-block-stack-frame-limit", result.unsupported.detail());
    try std.testing.expect(capture.matches(result.unsupported.tagName(), result.unsupported.detail()));
    const payload = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, capture.payload.?, .{});
    defer payload.deinit();
    const pressure = payload.value.object.get("pressure").?.object;
    try std.testing.expectEqual(@as(i64, 2), pressure.get("blocks").?.integer);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(.unassigned, machine.selection_owner);
    // A subsequent successful attempt clears every borrowed failure field.
    try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLowerObserved(std.testing.allocator, &machine, module.functions.items[1], null, null, &observer));
    try std.testing.expect(capture.payload == null);
}
