extern int z_frontier_helper_chain(int, int) __asm__("frontier_helper_graph.frontier_helper_chain");
extern int z_frontier_helper_branch(int, int) __asm__("frontier_helper_graph.frontier_helper_branch");
int main(void) {
    if (z_frontier_helper_chain(9, 99) != 10) return 1;
    if (z_frontier_helper_branch(1, 10) != 14) return 2;
    if (z_frontier_helper_branch(0, 10) != 23) return 3;
    return 0;
}

