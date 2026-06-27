extern int z_frontier_flat_window_sum(int, int) __asm__("frontier_nested_loops.frontier_flat_window_sum");
extern int z_frontier_window_threshold(int, int) __asm__("frontier_nested_loops.frontier_window_threshold");
extern int z_frontier_nested_memory_sum(const int *, unsigned long, int) __asm__("frontier_nested_loops.frontier_nested_memory_sum");
int main(void) {
    const int values[] = { 1, 9, 4, 12, 7 };
    if (z_frontier_flat_window_sum(7, 8) != 15) return 1;
    if (z_frontier_window_threshold(1, 9) != 9) return 2;
    if (z_frontier_window_threshold(0, 9) != 0) return 3;
    if (z_frontier_nested_memory_sum(values, 5, 6) != 28) return 4;
    return 0;
}

