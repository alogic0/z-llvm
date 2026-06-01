comptime {
    if (floatLiteral() != 1.5) @compileError("float literal check failed");
    if (doubleLiteral() != 2.25) @compileError("double literal check failed");
}

export fn main() c_int {
    return 0;
}

fn floatLiteral() f32 {
    return 1.5;
}

fn doubleLiteral() f64 {
    return 2.25;
}
