extern int z_frontier_comptime_mix(int) __asm__("frontier_comptime_constants.frontier_comptime_mix");
extern int z_frontier_static_choice(int) __asm__("frontier_comptime_constants.frontier_static_choice");
int main(void) {
    if (z_frontier_comptime_mix(5) != 26) return 1;
    if (z_frontier_static_choice(0) != 8) return 2;
    return 0;
}

