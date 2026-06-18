const Pair = extern struct {
    a: i32,
    b: i32,
};

var scale_global: i32 = 13;
threadlocal var scale_tls: i32 = 5;

fn addFour(value: i32) i32 {
    return value + 4;
}

fn subFour(value: i32) i32 {
    return value - 4;
}

export fn scale_pair_update(flag: i32, pair: *Pair) i32 {
    if (flag != 0) {
        pair.a += 2;
    } else {
        pair.a += 4;
    }
    return pair.a;
}

export fn scale_pair_read_b(pair: *const Pair) i32 {
    return pair.b;
}

export fn scale_branch_call(flag: i32, value: i32) i32 {
    const result = if (flag != 0) addFour(value) else subFour(value);
    return result;
}

export fn scale_global_update(delta: i32) i32 {
    scale_global += delta;
    return scale_global;
}

export fn scale_tls_bump(delta: i32) i32 {
    scale_tls += delta;
    return scale_tls;
}
