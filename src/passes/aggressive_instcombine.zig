const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const instcombine = @import("instcombine.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "aggressive-instcombine",
    .category = .canonicalization,
    .target_status = "conservative local InstCombine subset",
    .upstream_owner = "llvm/lib/Transforms/AggressiveInstCombine/",
    .run = run,
};

fn run(module: *ir.Module, context: *pass_manager.Context) !pass_manager.PassResult {
    return instcombine.pass.run(module, context);
}
