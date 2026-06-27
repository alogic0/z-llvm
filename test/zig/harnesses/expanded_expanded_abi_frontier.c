struct Pair { int a; int b; };
extern int z_expanded_stack_param_sum(int, int, int, int, int, int, int) __asm__("expanded_abi_frontier.expanded_stack_param_sum");
extern int z_expanded_stack_param_sum9(int, int, int, int, int, int, int, int, int) __asm__("expanded_abi_frontier.expanded_stack_param_sum9");
extern int z_expanded_stack_arg_call(void) __asm__("expanded_abi_frontier.expanded_stack_arg_call");
extern int z_expanded_multi_stack_arg_call(void) __asm__("expanded_abi_frontier.expanded_multi_stack_arg_call");
extern float z_expanded_float_call(void) __asm__("expanded_abi_frontier.expanded_float_call");
extern double z_expanded_double_call(void) __asm__("expanded_abi_frontier.expanded_double_call");
extern double z_expanded_mixed_int_float_call(void) __asm__("expanded_abi_frontier.expanded_mixed_int_float_call");
extern double z_expanded_mixed_int_float_stack_call(void) __asm__("expanded_abi_frontier.expanded_mixed_int_float_stack_call");
extern long long z_expanded_i64_call(void) __asm__("expanded_abi_frontier.expanded_i64_call");
extern struct Pair z_expanded_make_pair(int, int) __asm__("expanded_abi_frontier.expanded_make_pair");
extern int z_expanded_pair_first(struct Pair) __asm__("expanded_abi_frontier.expanded_pair_first");
int main(void) {
    struct Pair pair = z_expanded_make_pair(17, 29);
    if (z_expanded_stack_param_sum(1, 2, 3, 4, 5, 6, 7) != 28) return 1;
    if (z_expanded_stack_param_sum(-4, 2, 3, 4, 5, 6, 7) != 23) return 2;
    if (z_expanded_stack_param_sum9(1, 2, 3, 4, 5, 6, 7, 8, 9) != 24) return 3;
    if (z_expanded_stack_arg_call() != 28) return 4;
    if (z_expanded_multi_stack_arg_call() != 24) return 5;
    if (z_expanded_float_call() != 3.5f) return 6;
    if (z_expanded_double_call() != 3.0) return 7;
    if (z_expanded_mixed_int_float_call() != 6.0) return 8;
    if (z_expanded_mixed_int_float_stack_call() != 4.0) return 9;
    if (z_expanded_i64_call() != 123456789LL) return 10;
    if (pair.a != 17 || pair.b != 29) return 11;
    if (z_expanded_pair_first(pair) != 17) return 12;
    return 0;
}

