extern int z_scale_slice_sum(const int *, unsigned long) __asm__("scale_memory_loops.scale_slice_sum");
extern int z_scale_slice_threshold_sum(const int *, unsigned long, int) __asm__("scale_memory_loops.scale_slice_threshold_sum");
extern int z_scale_branch_pointer_load(int, const int *, const int *) __asm__("scale_memory_loops.scale_branch_pointer_load");
extern int z_scale_branch_store(int, int *, int) __asm__("scale_memory_loops.scale_branch_store");
int main(void) {
    const int values[5] = { 1, 2, 3, 4, 5 };
    const int mixed[5] = { 1, 8, 4, 11, 2 };
    int left = 13;
    int right = 29;
    int out = 0;
    if (z_scale_slice_sum(values, 5) != 15) return 1;
    if (z_scale_slice_sum(values, 0) != 0) return 2;
    if (z_scale_slice_threshold_sum(mixed, 5, 5) != 19) return 3;
    if (z_scale_slice_threshold_sum(values, 5, 9) != 0) return 4;
    if (z_scale_branch_pointer_load(1, &left, &right) != 13) return 5;
    if (z_scale_branch_pointer_load(0, &left, &right) != 29) return 6;
    if (z_scale_branch_store(1, &out, 40) != 45 || out != 45) return 7;
    if (z_scale_branch_store(0, &out, 40) != 35 || out != 35) return 8;
    return 0;
}

