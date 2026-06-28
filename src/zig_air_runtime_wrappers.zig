const std = @import("std");

pub const OptionalPointerMain = struct {
    pub const callee = "runtime_optional_pointer_main.optionalPtrValue";
    pub const value_global = "@runtime_optional_pointer_main.value";
};

pub const PointerLoadStoreMain = struct {
    pub const callee = "runtime_pointer_load_store_main.loadStore";
    pub const input_global = "@runtime_pointer_load_store_main.input";
    pub const output_global = "@runtime_pointer_load_store_main.output";
};

test "runtime wrapper symbols are registry-owned" {
    try std.testing.expectEqualStrings("runtime_optional_pointer_main.optionalPtrValue", OptionalPointerMain.callee);
    try std.testing.expectEqualStrings("@runtime_optional_pointer_main.value", OptionalPointerMain.value_global);
    try std.testing.expectEqualStrings("runtime_pointer_load_store_main.loadStore", PointerLoadStoreMain.callee);
    try std.testing.expectEqualStrings("@runtime_pointer_load_store_main.input", PointerLoadStoreMain.input_global);
    try std.testing.expectEqualStrings("@runtime_pointer_load_store_main.output", PointerLoadStoreMain.output_global);
}
