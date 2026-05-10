const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "verify",
    .category = .mandatory,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/IR/Verifier.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    try module.verify();
    return .unchanged;
}
