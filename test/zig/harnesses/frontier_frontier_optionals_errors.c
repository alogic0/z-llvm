extern int z_frontier_optional_merge(int, int) __asm__("frontier_optionals_errors.frontier_optional_merge");
extern int z_frontier_error_payload(int, int) __asm__("frontier_optionals_errors.frontier_error_payload");
extern int z_frontier_error_union_match(int) __asm__("frontier_optionals_errors.frontier_error_union_match");
extern int z_frontier_try_match(int, int) __asm__("frontier_optionals_errors.frontier_try_match");
extern int z_frontier_nested_try_match(int, int, int) __asm__("frontier_optionals_errors.frontier_nested_try_match");
extern int z_frontier_try_branch_match(int, int, int) __asm__("frontier_optionals_errors.frontier_try_branch_match");
int main(void) {
    if (z_frontier_optional_merge(1, 30) != 30) return 1;
    if (z_frontier_optional_merge(0, 30) != -17) return 2;
    if (z_frontier_error_payload(0, 40) != 42) return 3;
    if (z_frontier_error_union_match(0) != 14) return 4;
    if (z_frontier_error_union_match(1) != -22) return 5;
    if (z_frontier_try_match(0, 35) != 42) return 6;
    if (z_frontier_try_match(1, 35) != -31) return 7;
    if (z_frontier_nested_try_match(0, 0, 28) != 42) return 8;
    if (z_frontier_nested_try_match(1, 0, 28) != -37) return 9;
    if (z_frontier_nested_try_match(0, 1, 28) != -37) return 10;
    if (z_frontier_try_branch_match(0, 30, 4) != 34) return 11;
    if (z_frontier_try_branch_match(0, 10, 3) != 7) return 12;
    if (z_frontier_try_branch_match(1, 30, 4) != -41) return 13;
    return 0;
}
