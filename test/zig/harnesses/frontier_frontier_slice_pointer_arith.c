extern int z_frontier_slice_stride_sum(const int *) __asm__("frontier_slice_pointer_arith.frontier_slice_stride_sum");
extern int z_frontier_pointer_offset_load(const int *) __asm__("frontier_slice_pointer_arith.frontier_pointer_offset_load");
extern int z_frontier_dynamic_ptr_add(const int *, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_dynamic_ptr_add");
extern int z_frontier_dynamic_ptr_pair_sum(const int *, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_dynamic_ptr_pair_sum");
int main(void) {
    const int value = 37;
    const int values[] = { 3, 5, 8, 13, 21 };
    if (z_frontier_slice_stride_sum(&value) != 37) return 1;
    if (z_frontier_pointer_offset_load(&value) != 37) return 2;
    if (z_frontier_dynamic_ptr_add(values, 3) != 13) return 3;
    if (z_frontier_dynamic_ptr_pair_sum(values, 1) != 13) return 4;
    return 0;
}

