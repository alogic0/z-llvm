struct Pair { int a; int b; };
extern int z_scale_pair_update(int, struct Pair *) __asm__("scale_records_globals.scale_pair_update");
extern int z_scale_pair_read_b(const struct Pair *) __asm__("scale_records_globals.scale_pair_read_b");
extern int z_scale_branch_call(int, int) __asm__("scale_records_globals.scale_branch_call");
extern int z_scale_global_update(int) __asm__("scale_records_globals.scale_global_update");
extern int z_scale_tls_bump(int) __asm__("scale_records_globals.scale_tls_bump");
int main(void) {
    struct Pair pair = { 10, 33 };
    if (z_scale_pair_read_b(&pair) != 33) return 1;
    if (z_scale_pair_update(1, &pair) != 12 || pair.a != 12) return 2;
    if (z_scale_pair_update(0, &pair) != 16 || pair.a != 16) return 3;
    if (z_scale_branch_call(1, 20) != 24) return 4;
    if (z_scale_branch_call(0, 20) != 16) return 5;
    if (z_scale_global_update(4) != 17) return 6;
    if (z_scale_global_update(3) != 20) return 7;
    if (z_scale_tls_bump(2) != 7) return 8;
    if (z_scale_tls_bump(5) != 12) return 9;
    return 0;
}

