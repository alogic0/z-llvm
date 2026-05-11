export fn load_store(p: *i32, q: *i32) i32 {
    const value = p.*;
    q.* = value + 1;
    return q.*;
}

export fn volatile_roundtrip(p: *volatile i32, value: i32) i32 {
    p.* = value;
    return p.*;
}
