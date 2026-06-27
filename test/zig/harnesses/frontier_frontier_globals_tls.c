extern int z_frontier_global_branch(int, int) __asm__("frontier_globals_tls.frontier_global_branch");
extern int z_frontier_tls_branch(int, int) __asm__("frontier_globals_tls.frontier_tls_branch");
int main(void) {
    if (z_frontier_global_branch(1, 5) != 26) return 1;
    if (z_frontier_global_branch(0, 3) != 23) return 2;
    if (z_frontier_tls_branch(1, 2) != 6) return 3;
    if (z_frontier_tls_branch(0, 5) != 1) return 4;
    return 0;
}

