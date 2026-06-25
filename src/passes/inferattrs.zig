const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const function_attrs = @import("function_attrs.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "inferattrs",
    .category = .ipo,
    .target_status = "conservative direct-call FunctionAttrs subset",
    .upstream_owner = "llvm/lib/Transforms/IPO/InferFunctionAttrs.cpp",
    .run = run,
};

fn run(module: *ir.Module, context: *pass_manager.Context) !pass_manager.PassResult {
    return function_attrs.pass.run(module, context);
}
