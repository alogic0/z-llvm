extern int z_frontier_branch_store_reload(int, int *, int, int) __asm__("frontier_branch_memory.frontier_branch_store_reload");
extern int z_frontier_branch_local_mix(int, int *, int) __asm__("frontier_branch_memory.frontier_branch_local_mix");
int main(void) {
    int out = 0;
    if (z_frontier_branch_store_reload(1, &out, 20, 40) != 29 || out != 29) return 1;
    if (z_frontier_branch_store_reload(0, &out, 20, 40) != 31 || out != 31) return 2;
    if (z_frontier_branch_local_mix(1, &out, 30) != 36 || out != 36) return 3;
    if (z_frontier_branch_local_mix(0, &out, 30) != 24 || out != 24) return 4;
    return 0;
}

