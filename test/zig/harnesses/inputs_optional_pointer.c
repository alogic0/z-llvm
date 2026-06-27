extern int z_optional_ptr_value(const int *) __asm__("optional_pointer.optional_ptr_value");
int main(void) {
    int value = 41;
    if (z_optional_ptr_value(&value) != 41) return 1;
    if (z_optional_ptr_value((const int *)0) != -1) return 2;
    return 0;
}

