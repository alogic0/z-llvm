extern int z_load_store(int *, int *) __asm__("pointers_memory.load_store");
extern int z_volatile_roundtrip(int *, int) __asm__("pointers_memory.volatile_roundtrip");
int main(void) {
    int input = 5;
    int output = 0;
    if (z_load_store(&input, &output) != 6) return 1;
    if (output != 6) return 2;
    if (z_volatile_roundtrip(&output, 9) != 9) return 3;
    return 0;
}

