extern int z_read_tls(void) __asm__("tls_concurrency.read_tls");
extern int z_bump_tls(int) __asm__("tls_concurrency.bump_tls");
int main(void) {
    if (z_read_tls() != 1) return 1;
    if (z_bump_tls(5) != 6) return 2;
    if (z_read_tls() != 6) return 3;
    return 0;
}

