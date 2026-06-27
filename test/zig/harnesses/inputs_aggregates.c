struct Pair { int a; int b; };
extern int z_array_sum(int, int, int) __asm__("aggregates.array_sum");
extern int z_struct_sum(const struct Pair *) __asm__("aggregates.struct_sum");
extern int z_slice_sum(const int *, unsigned long) __asm__("aggregates.slice_sum");
extern int z_optional_payload(int, int) __asm__("aggregates.optional_payload");
extern int z_error_union_payload(int) __asm__("aggregates.error_union_payload");
int main(void) {
    int values[4] = { 1, 2, 3, 4 };
    struct Pair pair = { 8, 13 };
    if (z_array_sum(2, 3, 4) != 9) return 1;
    if (z_struct_sum(&pair) != 21) return 2;
    if (z_slice_sum(values, 4) != 10) return 3;
    if (z_optional_payload(1, 99) != 99) return 4;
    if (z_optional_payload(0, 99) != -1) return 5;
    if (z_error_union_payload(0) != 7) return 6;
    if (z_error_union_payload(1) != -1) return 7;
    return 0;
}

