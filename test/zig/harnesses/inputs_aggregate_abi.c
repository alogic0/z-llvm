struct Pair { int a; int b; };
extern struct Pair z_make_pair(int, int) __asm__("aggregate_abi.make_pair");
extern int z_pair_first(struct Pair) __asm__("aggregate_abi.pair_first");
int main(void) {
    struct Pair pair = z_make_pair(11, 31);
    if (pair.a != 11) return 1;
    if (pair.b != 31) return 2;
    if (z_pair_first(pair) != 11) return 3;
    return 0;
}

