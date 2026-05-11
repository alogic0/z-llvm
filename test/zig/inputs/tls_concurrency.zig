threadlocal var tls_counter: i32 = 1;

export fn read_tls() i32 {
    return tls_counter;
}

export fn bump_tls(value: i32) i32 {
    tls_counter += value;
    return tls_counter;
}
