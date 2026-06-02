var hidden: i32 = 0;

export fn main() c_int {
    updateHidden(7);
    return getHidden();
}

fn getHidden() i32 {
    return hidden;
}

fn updateHidden(value: i32) void {
    hidden = value;
}
