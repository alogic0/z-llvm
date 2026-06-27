extern int z_frontier_optional_merge(int, int) __asm__("frontier_optionals_errors.frontier_optional_merge");
extern int z_frontier_error_payload(int, int) __asm__("frontier_optionals_errors.frontier_error_payload");
int main(void) {
    if (z_frontier_optional_merge(1, 30) != 30) return 1;
    if (z_frontier_optional_merge(0, 30) != -17) return 2;
    if (z_frontier_error_payload(0, 40) != 42) return 3;
    return 0;
}

