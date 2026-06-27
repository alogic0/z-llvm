extern int z_frontier_optional_merge(int, int) __asm__("frontier_optionals_errors.frontier_optional_merge");
extern int z_frontier_error_payload(int, int) __asm__("frontier_optionals_errors.frontier_error_payload");
extern int z_frontier_error_union_match(int) __asm__("frontier_optionals_errors.frontier_error_union_match");
int main(void) {
    if (z_frontier_optional_merge(1, 30) != 30) return 1;
    if (z_frontier_optional_merge(0, 30) != -17) return 2;
    if (z_frontier_error_payload(0, 40) != 42) return 3;
    if (z_frontier_error_union_match(0) != 14) return 4;
    if (z_frontier_error_union_match(1) != -22) return 5;
    return 0;
}
