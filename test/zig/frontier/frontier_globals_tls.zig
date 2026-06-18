var frontier_global: i32 = 21;
threadlocal var frontier_tls: i32 = 4;

export fn frontier_global_branch(flag: i32, delta: i32) i32 {
    _ = flag;
    frontier_global += delta;
    return frontier_global;
}

export fn frontier_tls_branch(flag: i32, delta: i32) i32 {
    _ = flag;
    frontier_tls += delta;
    return frontier_tls;
}
