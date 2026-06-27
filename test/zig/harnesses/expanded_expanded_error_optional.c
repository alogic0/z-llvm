extern int z_expanded_error_optional(int, int) __asm__("expanded_error_optional.expanded_error_optional");
extern int z_expanded_optional_pointer(const int *) __asm__("expanded_error_optional.expanded_optional_pointer");
int main(void) {
    int value = 34;
    if (z_expanded_error_optional(1, 17) != 17) return 1;
    if (z_expanded_error_optional(0, 17) != -9) return 2;
    if (z_expanded_optional_pointer(&value) != 42) return 3;
    if (z_expanded_optional_pointer((const int *)0) != -1) return 4;
    return 0;
}

