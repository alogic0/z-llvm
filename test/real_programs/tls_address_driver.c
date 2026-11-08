#include <pthread.h>
#include <stdint.h>
#include <stdio.h>

extern uint64_t *tls_address_counter(void);
extern uint64_t *tls_address_alias(void);
extern unsigned char *tls_address_offset(void);
extern uint64_t tls_address_update(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t);
extern double tls_address_double(double, double);
extern uint64_t tls_address_choose(uint64_t, uint64_t);

static pthread_barrier_t ready;
static int errors[5];
static unsigned observations[5];

static void *run(void *argument) {
    unsigned id = (unsigned)(uintptr_t)argument;
    uint64_t *counter = tls_address_counter();
    unsigned char *bytes = tls_address_offset();
    int bad = ((uintptr_t)counter & 63) != 0 || *counter != 17 ||
              tls_address_alias() != counter || ((uintptr_t)(bytes - 7) & 31) != 0;
    for (unsigned i = 0; i < 80; ++i) if ((bytes - 7)[i]) bad = 1;
    for (unsigned i = 0; i < 80; ++i) (bytes - 7)[i] = (unsigned char)(id + 1);
    *counter = 1000 + id;
    pthread_barrier_wait(&ready);
    uint64_t expected = 1000 + id;
    for (unsigned i = 0; i < 128; ++i) {
        uint64_t a = ((uint64_t)id << 48) + i + 1;
        uint64_t b = a * 17, c = a ^ UINT64_MAX, d = a + 123, e = a * 31, f = a ^ 0x12345678;
        if (tls_address_update(a, b, c, d, e, f) != (a ^ b ^ c ^ d ^ e ^ f ^ expected)) bad = 1;
        expected += a;
        ++observations[id];
        if (tls_address_double((double)i + 0.5, (double)id) != (double)(i + id) + 0.5) bad = 1;
        ++expected;
        ++observations[id];
        uint64_t x = (i & 1) ? UINT64_MAX : 0, y = i + 1;
        if (tls_address_choose(x, y) != ((x < y ? expected : x ^ y) ^ x)) bad = 1;
        ++observations[id];
        if (*counter != expected || tls_address_alias() != counter || tls_address_offset() != bytes) bad = 1;
        for (unsigned j = 0; j < 80; ++j) if ((bytes - 7)[j] != id + 1) bad = 1;
        ++observations[id];
    }
    errors[id] = bad;
    return NULL;
}

int main(void) {
    pthread_t threads[4];
    if (pthread_barrier_init(&ready, NULL, 5)) return 1;
    for (unsigned i = 0; i < 4; ++i) if (pthread_create(&threads[i], NULL, run, (void *)(uintptr_t)i)) return 2;
    run((void *)(uintptr_t)4);
    for (unsigned i = 0; i < 4; ++i) if (pthread_join(threads[i], NULL)) return 3;
    unsigned count = 0;
    for (unsigned i = 0; i < 5; ++i) { if (errors[i]) return 4; count += observations[i]; }
    if (pthread_barrier_destroy(&ready)) return 5;
    printf("tls-address observations=%u threads=5 initialization=alignment=aliases=live=phi=preserved\n", count);
    return 0;
}
