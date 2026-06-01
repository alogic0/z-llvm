threadlocal var tls_counter: i32 = 1;

export fn main() c_int {
    return 0;
}

fn readTls() i32 {
    return tls_counter;
}
