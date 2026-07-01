#include <sys/wait.h>
#include <unistd.h>

extern int z_frontier_optional_merge(int, int) __asm__("frontier_optionals_errors.frontier_optional_merge");
extern int z_frontier_optional_ptr_non_null(const int *) __asm__("frontier_optionals_errors.frontier_optional_ptr_non_null");
extern int z_frontier_optional_payload_branch(int, int, int) __asm__("frontier_optionals_errors.frontier_optional_payload_branch");
extern int z_frontier_error_payload(int, int) __asm__("frontier_optionals_errors.frontier_error_payload");
extern int z_frontier_error_union_match(int) __asm__("frontier_optionals_errors.frontier_error_union_match");
extern int z_frontier_try_match(int, int) __asm__("frontier_optionals_errors.frontier_try_match");
extern int z_frontier_nested_try_match(int, int, int) __asm__("frontier_optionals_errors.frontier_nested_try_match");
extern int z_frontier_try_branch_match(int, int, int) __asm__("frontier_optionals_errors.frontier_try_branch_match");
extern int z_frontier_try_slot_update_match(int, int, int) __asm__("frontier_optionals_errors.frontier_try_slot_update_match");
extern int z_frontier_try_call_result_match(int, int, int) __asm__("frontier_optionals_errors.frontier_try_call_result_match");
extern int z_frontier_catch_return_error_match(int, int) __asm__("frontier_optionals_errors.frontier_catch_return_error_match");
extern int z_frontier_try_local_override_match(int, int, int) __asm__("frontier_optionals_errors.frontier_try_local_override_match");
extern int z_frontier_branch_then_try_match(int, int, int) __asm__("frontier_optionals_errors.frontier_branch_then_try_match");
extern int z_frontier_switch_then_try_match(int, int, int) __asm__("frontier_optionals_errors.frontier_switch_then_try_match");
extern int z_frontier_branch_both_try_match(int, int, int, int) __asm__("frontier_optionals_errors.frontier_branch_both_try_match");
extern int z_frontier_switch_both_try_match(int, int, int, int) __asm__("frontier_optionals_errors.frontier_switch_both_try_match");
extern int z_frontier_loop_try_match(int, int) __asm__("frontier_optionals_errors.frontier_loop_try_match");
extern int z_frontier_loop_try_post_branch(int, int, int) __asm__("frontier_optionals_errors.frontier_loop_try_post_branch");
extern int z_frontier_loop_try_post_switch(int, int) __asm__("frontier_optionals_errors.frontier_loop_try_post_switch");
extern int z_frontier_try_switch_match(int, int) __asm__("frontier_optionals_errors.frontier_try_switch_match");
extern int z_frontier_try_cold_match(int, int) __asm__("frontier_optionals_errors.frontier_try_cold_match");
extern int z_frontier_try_ptr_match(int, int) __asm__("frontier_optionals_errors.frontier_try_ptr_match");
extern int z_frontier_try_ptr_cold_match(int, int) __asm__("frontier_optionals_errors.frontier_try_ptr_cold_match");
extern int z_frontier_try_ptr_branch_match(int, int, int) __asm__("frontier_optionals_errors.frontier_try_ptr_branch_match");
extern int z_frontier_nested_try_ptr_match(int, int, int) __asm__("frontier_optionals_errors.frontier_nested_try_ptr_match");
extern int z_frontier_try_ptr_switch_match(int, int) __asm__("frontier_optionals_errors.frontier_try_ptr_switch_match");
extern int z_frontier_errunion_payload_ptr_branch(int, int, int) __asm__("frontier_optionals_errors.frontier_errunion_payload_ptr_branch");
extern int z_frontier_errunion_payload_ptr_error_switch(int, int) __asm__("frontier_optionals_errors.frontier_errunion_payload_ptr_error_switch");
extern int z_frontier_try_catch_map_match(int, int) __asm__("frontier_optionals_errors.frontier_try_catch_map_match");
extern int z_frontier_try_catch_branch_map_match(int, int) __asm__("frontier_optionals_errors.frontier_try_catch_branch_map_match");
extern int z_frontier_catch_error_value_switch(int, int, int) __asm__("frontier_optionals_errors.frontier_catch_error_value_switch");
extern int z_frontier_catch_error_call_match(int, int, int) __asm__("frontier_optionals_errors.frontier_catch_error_call_match");
extern int z_frontier_try_void_catch_match(int, int) __asm__("frontier_optionals_errors.frontier_try_void_catch_match");
extern int z_frontier_try_void_catch_switch(int, int) __asm__("frontier_optionals_errors.frontier_try_void_catch_switch");
extern int z_frontier_try_void_payload_match(int, int) __asm__("frontier_optionals_errors.frontier_try_void_payload_match");
extern int z_frontier_wrap_error_switch_match(int, int) __asm__("frontier_optionals_errors.frontier_wrap_error_switch_match");
extern int z_frontier_wrap_error_branch_match(int) __asm__("frontier_optionals_errors.frontier_wrap_error_branch_match");
extern int z_frontier_maybe_error_tag_match(int, int) __asm__("frontier_optionals_errors.frontier_maybe_error_tag_match");
extern int z_frontier_error_tag_switch(int, int) __asm__("frontier_optionals_errors.frontier_error_tag_switch");
extern int z_frontier_error_tag_branch(int, int) __asm__("frontier_optionals_errors.frontier_error_tag_branch");
extern int z_frontier_error_catch_default_merge(int, int, int) __asm__("frontier_optionals_errors.frontier_error_catch_default_merge");
extern int z_frontier_error_catch_const_merge(int, int) __asm__("frontier_optionals_errors.frontier_error_catch_const_merge");
extern int z_frontier_wrap_selected_error_switch(int) __asm__("frontier_optionals_errors.frontier_wrap_selected_error_switch");
extern unsigned long z_frontier_error_name_len(int) __asm__("frontier_optionals_errors.frontier_error_name_len");
extern unsigned long z_frontier_error_name_three_len(int) __asm__("frontier_optionals_errors.frontier_error_name_three_len");
void z_frontier_optionals_unwrap_null(void) __asm__("frontier_optionals_errors.unwrapNull");
void z_frontier_optionals_unwrap_null(void) { __builtin_trap(); }
void z_frontier_optionals_invalid_error_code(void) __asm__("frontier_optionals_errors.invalidErrorCode");
void z_frontier_optionals_invalid_error_code(void) { __builtin_trap(); }

static int expect_death(void (*fn)(void)) {
    int status = 0;
    pid_t pid = fork();
    if (pid < 0) return 100;
    if (pid == 0) {
        fn();
        _exit(101);
    }
    if (waitpid(pid, &status, 0) < 0) return 102;
    return WIFSIGNALED(status) ? 0 : 103;
}

#ifdef ZLLVM_HARNESS_MODE_ReleaseSafe
static void death_error_name_invalid_code(void) { (void)z_frontier_error_name_three_len(4); }
#endif

int main(void) {
    const int ptr_value = 49;
    if (z_frontier_optional_merge(1, 30) != 30) return 1;
    if (z_frontier_optional_merge(0, 30) != -17) return 2;
    if (z_frontier_optional_ptr_non_null(&ptr_value) != 49) return 27;
    if (z_frontier_optional_ptr_non_null(0) != -49) return 28;
    if (z_frontier_optional_payload_branch(1, 30, 4) != 34) return 51;
    if (z_frontier_optional_payload_branch(1, 10, 3) != 7) return 52;
    if (z_frontier_optional_payload_branch(0, 30, 4) != -63) return 53;
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
    if (z_frontier_try_slot_update_match(0, 30, 12) != 42) return 60;
    if (z_frontier_try_slot_update_match(1, 30, 12) != -69) return 61;
    if (z_frontier_try_call_result_match(0, 37, 5) != 42) return 98;
    if (z_frontier_try_call_result_match(1, 37, 5) != -98) return 99;
    if (z_frontier_catch_return_error_match(0, 31) != 42) return 100;
    if (z_frontier_catch_return_error_match(1, 31) != -86) return 101;
    if (z_frontier_try_local_override_match(0, 27, 0) != 42) return 102;
    if (z_frontier_try_local_override_match(1, 27, 0) != -88) return 103;
    if (z_frontier_try_local_override_match(0, 27, 1) != -88) return 104;
    if (z_frontier_branch_then_try_match(1, 0, 38) != 42) return 14;
    if (z_frontier_branch_then_try_match(0, 1, 46) != 42) return 15;
    if (z_frontier_branch_then_try_match(1, 1, 38) != -42) return 16;
    if (z_frontier_switch_then_try_match(0, 1, 47) != 42) return 65;
    if (z_frontier_switch_then_try_match(1, 0, 37) != 42) return 66;
    if (z_frontier_switch_then_try_match(1, 1, 37) != -73) return 67;
    if (z_frontier_branch_both_try_match(1, 0, 1, 38) != 42) return 68;
    if (z_frontier_branch_both_try_match(0, 1, 0, 36) != 42) return 69;
    if (z_frontier_branch_both_try_match(1, 1, 0, 38) != -75) return 70;
    if (z_frontier_branch_both_try_match(0, 0, 1, 36) != -75) return 71;
    if (z_frontier_switch_both_try_match(0, 0, 1, 38) != 42) return 72;
    if (z_frontier_switch_both_try_match(1, 1, 0, 36) != 42) return 73;
    if (z_frontier_switch_both_try_match(0, 1, 0, 38) != -77) return 74;
    if (z_frontier_switch_both_try_match(1, 0, 1, 36) != -77) return 75;
    if (z_frontier_loop_try_match(5, -1) != 10) return 76;
    if (z_frontier_loop_try_match(0, -1) != 0) return 77;
    if (z_frontier_loop_try_match(5, 3) != -79) return 78;
    if (z_frontier_loop_try_post_branch(5, -1, 8) != 11) return 79;
    if (z_frontier_loop_try_post_branch(5, -1, 10) != 9) return 80;
    if (z_frontier_loop_try_post_branch(5, 3, 0) != -81) return 81;
    if (z_frontier_loop_try_post_switch(4, -1) != 13) return 82;
    if (z_frontier_loop_try_post_switch(2, -1) != 6) return 83;
    if (z_frontier_loop_try_post_switch(5, 3) != -83) return 84;
    if (z_frontier_try_switch_match(0, 28) != 29) return 17;
    if (z_frontier_try_switch_match(0, 29) != 31) return 18;
    if (z_frontier_try_switch_match(0, 30) != 33) return 19;
    if (z_frontier_try_switch_match(1, 28) != -43) return 20;
    if (z_frontier_try_cold_match(0, 31) != 42) return 29;
    if (z_frontier_try_cold_match(1, 31) != -51) return 30;
    if (z_frontier_try_ptr_match(0, 29) != 42) return 31;
    if (z_frontier_try_ptr_match(1, 29) != -53) return 32;
    if (z_frontier_try_ptr_cold_match(0, 27) != 42) return 33;
    if (z_frontier_try_ptr_cold_match(1, 27) != -55) return 34;
    if (z_frontier_try_ptr_branch_match(0, 30, 4) != 34) return 35;
    if (z_frontier_try_ptr_branch_match(0, 10, 3) != 7) return 36;
    if (z_frontier_try_ptr_branch_match(1, 30, 4) != -57) return 37;
    if (z_frontier_nested_try_ptr_match(0, 0, 28) != 42) return 38;
    if (z_frontier_nested_try_ptr_match(1, 0, 28) != -59) return 39;
    if (z_frontier_nested_try_ptr_match(0, 1, 28) != -59) return 40;
    if (z_frontier_try_ptr_switch_match(0, 39) != 42) return 41;
    if (z_frontier_try_ptr_switch_match(0, 40) != 41) return 42;
    if (z_frontier_try_ptr_switch_match(0, 41) != 43) return 43;
    if (z_frontier_try_ptr_switch_match(1, 39) != -61) return 44;
    if (z_frontier_errunion_payload_ptr_branch(0, 66, 5) != 71) return 54;
    if (z_frontier_errunion_payload_ptr_branch(0, 10, 3) != 7) return 55;
    if (z_frontier_errunion_payload_ptr_branch(1, 66, 5) != -65) return 56;
    if (z_frontier_errunion_payload_ptr_error_switch(0, 40) != 42) return 57;
    if (z_frontier_errunion_payload_ptr_error_switch(1, 40) != -67) return 58;
    if (z_frontier_errunion_payload_ptr_error_switch(2, 40) != -68) return 59;
    if (z_frontier_try_catch_map_match(0, 36) != 42) return 62;
    if (z_frontier_try_catch_map_match(1, 36) != -72) return 63;
    if (z_frontier_try_catch_map_match(2, 36) != -71) return 64;
    if (z_frontier_try_catch_branch_map_match(0, 34) != 42) return 113;
    if (z_frontier_try_catch_branch_map_match(1, 34) != -114) return 114;
    if (z_frontier_try_catch_branch_map_match(2, 34) != -113) return 115;
    if (z_frontier_catch_error_value_switch(0, 38, 4) != 42) return 85;
    if (z_frontier_catch_error_value_switch(1, 38, 4) != 24) return 86;
    if (z_frontier_catch_error_value_switch(2, 38, 4) != 34) return 87;
    if (z_frontier_catch_error_call_match(0, 38, 4) != 42) return 118;
    if (z_frontier_catch_error_call_match(1, 38, 4) != 45) return 119;
    if (z_frontier_catch_error_call_match(2, 38, 4) != 47) return 120;
    if (z_frontier_try_void_catch_match(0, 5) != 12) return 121;
    if (z_frontier_try_void_catch_match(1, 5) != 46) return 122;
    if (z_frontier_try_void_catch_match(2, 5) != 48) return 123;
    if (z_frontier_try_void_catch_switch(0, 5) != 22) return 124;
    if (z_frontier_try_void_catch_switch(1, 5) != 16) return 125;
    if (z_frontier_try_void_catch_switch(2, 5) != 18) return 126;
    if (z_frontier_try_void_payload_match(0, 5) != 29) return 127;
    if (z_frontier_try_void_payload_match(1, 5) != 46) return 128;
    if (z_frontier_try_void_payload_match(2, 5) != 48) return 129;
    if (z_frontier_wrap_error_switch_match(0, 41) != 42) return 88;
    if (z_frontier_wrap_error_switch_match(1, 41) != -86) return 89;
    if (z_frontier_wrap_error_switch_match(2, 41) != -87) return 90;
    if (z_frontier_wrap_error_branch_match(0) != -116) return 116;
    if (z_frontier_wrap_error_branch_match(1) != -117) return 117;
    if (z_frontier_maybe_error_tag_match(0, 46) != 46) return 21;
    if (z_frontier_maybe_error_tag_match(1, 46) != -46) return 22;
    if (z_frontier_maybe_error_tag_match(2, 46) != -46) return 23;
    if (z_frontier_error_tag_switch(0, 46) != 47) return 24;
    if (z_frontier_error_tag_switch(1, 46) != -47) return 25;
    if (z_frontier_error_tag_switch(2, 46) != -48) return 26;
    if (z_frontier_error_tag_branch(0, 39) != 42) return 91;
    if (z_frontier_error_tag_branch(1, 39) != -91) return 92;
    if (z_frontier_error_tag_branch(2, 39) != -92) return 93;
    if (z_frontier_error_catch_default_merge(0, 38, 5) != 42) return 94;
    if (z_frontier_error_catch_default_merge(1, 38, 5) != 9) return 95;
    if (z_frontier_error_catch_const_merge(0, 38) != 42) return 96;
    if (z_frontier_error_catch_const_merge(1, 38) != 10) return 97;
    if (z_frontier_wrap_selected_error_switch(0) != -111) return 111;
    if (z_frontier_wrap_selected_error_switch(1) != -112) return 112;
    if (z_frontier_error_name_len(0) != 6) return 105;
    if (z_frontier_error_name_len(1) != 8) return 106;
    if (z_frontier_error_name_three_len(1) != 10) return 107;
    if (z_frontier_error_name_three_len(2) != 5) return 108;
    if (z_frontier_error_name_three_len(3) != 12) return 109;
#ifdef ZLLVM_HARNESS_MODE_ReleaseSafe
    if (expect_death(death_error_name_invalid_code) != 0) return 110;
#endif
    return 0;
}
