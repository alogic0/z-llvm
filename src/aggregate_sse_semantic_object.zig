const std = @import("std");
const ir = @import("ir.zig");
const x86_64 = @import("codegen/x86_64.zig");
const elf = @import("mc/elf.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.skip();
    const output_path = args.next() orelse return error.MissingOutputPath;
    if (args.next() != null) return error.UnexpectedArgument;

    const source =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\
        \\define { double, double } @zllvm_return_f64_pair(double %a, double %b) {
        \\entry:
        \\  %first = insertvalue { double, double } poison, double %a, 0
        \\  %pair = insertvalue { double, double } %first, double %b, 1
        \\  ret { double, double } %pair
        \\}
        \\
        \\define { <2 x float> } @zllvm_return_f32x2(float %a, float %b) {
        \\entry:
        \\  %lane0 = insertelement <2 x float> poison, float %a, i64 0
        \\  %lanes = insertelement <2 x float> %lane0, float %b, i64 1
        \\  %pair = insertvalue { <2 x float> } poison, <2 x float> %lanes, 0
        \\  ret { <2 x float> } %pair
        \\}
        \\
    ;
    var module = try ir.Module.parse(allocator, source);
    defer module.deinit();
    try module.verify();

    var functions: std.ArrayList(x86_64.MachineFunction) = .empty;
    defer {
        for (functions.items) |*function| function.deinit(allocator);
        functions.deinit(allocator);
    }
    for (module.functions.items) |function| {
        var diagnostic_tag: ?[]const u8 = null;
        var diagnostic_detail: ?[]const u8 = null;
        var lowered = x86_64.lowerFunctionWithOptions(allocator, module.target_triple.?, function, .{
            .generic_cfg_selector = true,
            .generic_cfg_selector_diagnostic_tag = &diagnostic_tag,
            .generic_cfg_selector_diagnostic_detail = &diagnostic_detail,
        }) catch |err| {
            std.debug.print("aggregate SSE selector failed function={s} tag={s} detail={s}\n", .{
                function.name,
                diagnostic_tag orelse "-",
                diagnostic_detail orelse "-",
            });
            return err;
        };
        errdefer lowered.deinit(allocator);
        if (lowered.codegen_path != .generic_cfg) return error.UnexpectedCodegenPath;
        try functions.append(allocator, lowered);
    }

    const object = try elf.buildObject(allocator, functions.items);
    defer allocator.free(object);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = output_path, .data = object });
}
