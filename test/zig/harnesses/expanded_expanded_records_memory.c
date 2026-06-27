struct Pair { int a; int b; };
extern struct Pair z_expanded_make_pair(int, int) __asm__("expanded_records_memory.expanded_make_pair");
extern int z_expanded_pair_first(struct Pair) __asm__("expanded_records_memory.expanded_pair_first");
extern int z_expanded_global_update(int) __asm__("expanded_records_memory.expanded_global_update");
extern int z_expanded_tls_bump(int) __asm__("expanded_records_memory.expanded_tls_bump");
int main(void) {
    struct Pair pair = z_expanded_make_pair(12, 30);
    if (pair.a != 12) return 1;
    if (pair.b != 30) return 2;
    if (z_expanded_pair_first(pair) != 12) return 3;
    if (z_expanded_global_update(5) != 16) return 4;
    if (z_expanded_tls_bump(7) != 9) return 5;
    return 0;
}

