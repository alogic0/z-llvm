extern int z_expanded_branch_pointer_load(int, const int *, const int *) __asm__("expanded_cfg_memory_aggregates.expanded_branch_pointer_load");
extern int z_expanded_branch_pointer_phi_load(int, const int *, const int *) __asm__("expanded_cfg_memory_aggregates.expanded_branch_pointer_phi_load");
extern int z_expanded_branch_store(int, int *, int, int) __asm__("expanded_cfg_memory_aggregates.expanded_branch_store");
extern int z_expanded_branch_store_computed(int, int *, int) __asm__("expanded_cfg_memory_aggregates.expanded_branch_store_computed");
extern int z_expanded_slice_conditional_sum(const int *, unsigned long, int) __asm__("expanded_cfg_memory_aggregates.expanded_slice_conditional_sum");
extern int z_expanded_branch_call(int, int) __asm__("expanded_cfg_memory_aggregates.expanded_branch_call");
extern int z_expanded_branch_call_two(int, int) __asm__("expanded_cfg_memory_aggregates.expanded_branch_call_two");
extern int z_expanded_optional_pointer_branch(int, const int *) __asm__("expanded_cfg_memory_aggregates.expanded_optional_pointer_branch");
void z_expanded_cfg_unwrap_null(void) __asm__("expanded_cfg_memory_aggregates.unwrapNull");
void z_expanded_cfg_unwrap_null(void) { __builtin_trap(); }
struct pair_i32 { int a; int b; };
extern int z_expanded_struct_branch_update(int, struct pair_i32 *) __asm__("expanded_cfg_memory_aggregates.expanded_struct_branch_update");
extern int z_expanded_struct_field_b(const struct pair_i32 *) __asm__("expanded_cfg_memory_aggregates.expanded_struct_field_b");
extern int z_expanded_struct_field_a(const struct pair_i32 *) __asm__("expanded_cfg_memory_aggregates.expanded_struct_field_a");
int main(void) {
    int left = 10;
    int right = 20;
    int out = 0;
    struct pair_i32 pair = { 20, 44 };
    const int mixed_values[4] = { 1, 9, 4, 12 };
    const int below_values[3] = { 1, 2, 3 };
    const int above_values[3] = { 6, 7, 8 };
    if (z_expanded_branch_pointer_load(1, &left, &right) != 10) return 1;
    if (z_expanded_branch_pointer_load(0, &left, &right) != 20) return 2;
    if (z_expanded_branch_pointer_phi_load(1, &left, &right) != 10) return 3;
    if (z_expanded_branch_pointer_phi_load(0, &left, &right) != 20) return 4;
    if (z_expanded_branch_store(1, &out, 31, 41) != 31 || out != 31) return 5;
    if (z_expanded_branch_store(0, &out, 31, 41) != 41 || out != 41) return 6;
    if (z_expanded_branch_store_computed(1, &out, 50) != 54 || out != 54) return 7;
    if (z_expanded_branch_store_computed(0, &out, 50) != 46 || out != 46) return 8;
    if (z_expanded_slice_conditional_sum(mixed_values, 4, 5) != 21) return 9;
    if (z_expanded_slice_conditional_sum(below_values, 3, 5) != 0) return 10;
    if (z_expanded_slice_conditional_sum(above_values, 3, 5) != 21) return 21;
    if (z_expanded_slice_conditional_sum(mixed_values, 0, 5) != 0) return 22;
    if (z_expanded_branch_call(1, 39) != 42) return 11;
    if (z_expanded_branch_call(0, 39) != 36) return 12;
    if (z_expanded_branch_call_two(1, 39) != 42) return 13;
    if (z_expanded_branch_call_two(0, 39) != 36) return 14;
    if (z_expanded_optional_pointer_branch(1, &left) != 11) return 19;
    if (z_expanded_optional_pointer_branch(0, (const int *)0) != -11) return 20;
    if (z_expanded_struct_field_b(&pair) != 44) return 15;
    if (z_expanded_struct_field_a(&pair) != 20) return 16;
    if (z_expanded_struct_branch_update(1, &pair) != 25 || pair.a != 25) return 17;
    if (z_expanded_struct_branch_update(0, &pair) != 32 || pair.a != 32) return 18;
    return 0;
}

