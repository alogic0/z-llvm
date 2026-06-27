extern int z_scale_stack_wide_call(void) __asm__("scale_abi_calls.scale_stack_wide_call");
extern double z_scale_mixed_wide_call(void) __asm__("scale_abi_calls.scale_mixed_wide_call");
extern long long z_scale_i64_echo_call(void) __asm__("scale_abi_calls.scale_i64_echo_call");
int main(void) {
    if (z_scale_stack_wide_call() != 24) return 1;
    if (z_scale_mixed_wide_call() != 4.0) return 2;
    if (z_scale_i64_echo_call() != 987654321LL) return 3;
    return 0;
}

