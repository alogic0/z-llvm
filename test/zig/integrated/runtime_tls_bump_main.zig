threadlocal var tls_counter: i32 = 1;

export fn main() c_int {
    return bumpTls(1);
}

fn bumpTls(value: i32) i32 {
    tls_counter += value;
    return tls_counter;
}
