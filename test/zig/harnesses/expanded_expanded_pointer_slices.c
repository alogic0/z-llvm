extern int z_expanded_slice_sum(const int *, unsigned long) __asm__("expanded_pointer_slices.expanded_slice_sum");
extern int z_expanded_load_store(int *, int *) __asm__("expanded_pointer_slices.expanded_load_store");
int main(void) {
    int values[4] = { 2, 4, 6, 8 };
    int input = 39;
    int output = 0;
    if (z_expanded_slice_sum(values, 4) != 20) return 1;
    if (z_expanded_load_store(&input, &output) != 42) return 2;
    if (output != 42) return 3;
    return 0;
}

