extern int z_base64_table_lookup(unsigned char) __asm__("base64_table_lookup.base64_table_lookup");
void z_base64_table_lookup_oob(unsigned long, unsigned long) __asm__("base64_table_lookup.outOfBounds");
void z_base64_table_lookup_oob(unsigned long index, unsigned long len) { (void)index; (void)len; __builtin_trap(); }
int main(void) {
    if (z_base64_table_lookup(0) != 0) return 1;
    if (z_base64_table_lookup(1) != 4) return 2;
    if (z_base64_table_lookup(2) != 8) return 3;
    if (z_base64_table_lookup(7) != 12) return 4;
    return 0;
}

