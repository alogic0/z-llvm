//! Controlled ReleaseSafe termination-class case for INBOX-66.

const std = @import("std");

pub const panic = std.debug.no_panic;

export fn abi_diff_controlled_panic() callconv(.c) noreturn {
    @panic("abi-diff-controlled-panic");
}
