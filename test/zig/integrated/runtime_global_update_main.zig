comptime {
    var counter: i32 = 3;
    counter += 1;
    if (counter != 4) @compileError("global update check failed");
}

export fn main() c_int {
    return 0;
}

var global_counter: i32 = 3;

fn updateGlobal(value: i32) i32 {
    global_counter += value;
    return global_counter;
}
