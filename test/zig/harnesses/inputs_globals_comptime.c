extern int z_read_global(void) __asm__("globals_comptime.read_global");
extern int z_update_global(int) __asm__("globals_comptime.update_global");
extern int z_comptime_const(int) __asm__("globals_comptime.comptime_const");
int main(void) {
    if (z_read_global() != 3) return 1;
    if (z_update_global(4) != 7) return 2;
    if (z_read_global() != 7) return 3;
    if (z_comptime_const(7) != 35) return 4;
    return 0;
}

