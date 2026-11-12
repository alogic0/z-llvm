#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <ucontext.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel_t)(void *, void *, void *);
extern uint64_t volatile_native_8(void *, void *, void *);
extern uint64_t volatile_native_16(void *, void *, void *);
extern uint64_t volatile_native_32(void *, void *, void *);
extern uint64_t volatile_native_64(void *, void *, void *);
extern uint64_t volatile_native_ptr(void *, void *, void *);
struct event { uintptr_t address; uint64_t before, after; unsigned write; };
static struct event events[16];
static volatile sig_atomic_t active, pending, count;
static unsigned char *watched_page, *watched_address;
static size_t page_size;
static unsigned access_bytes;
static uint64_t read_word(void) {
    uint64_t result = 0;
    for (unsigned i = 0; i < access_bytes; i++) result |= (uint64_t)watched_address[i] << (8 * i);
    return result;
}
static void failed_signal(void) { static const char text[] = "volatile-native unexpected signal event\n"; (void)write(2, text, sizeof text - 1); _exit(3); }
static void segv(int signal, siginfo_t *info, void *context) {
    (void)signal;
    if (!active || pending || count >= 16 || info->si_addr != watched_address) failed_signal();
    ucontext_t *state = context;
    if (mprotect(watched_page, page_size, PROT_READ | PROT_WRITE)) failed_signal();
    events[count].address = (uintptr_t)info->si_addr;
    events[count].write = (state->uc_mcontext.gregs[REG_ERR] & 2) != 0;
    events[count].before = read_word();
    pending = 1;
    state->uc_mcontext.gregs[REG_EFL] |= 0x100; // Resume exactly one x86 instruction.
}
static void trap(int signal, siginfo_t *info, void *context) {
    (void)signal;
    if (!active || !pending || count >= 16 || info->si_code != TRAP_TRACE) failed_signal();
    ucontext_t *state = context;
    events[count].after = read_word();
    if (mprotect(watched_page, page_size, PROT_NONE)) failed_signal();
    state->uc_mcontext.gregs[REG_EFL] &= ~(greg_t)0x100;
    pending = 0;
    count++;
}
int main(int argc, char **argv) {
    unsigned fault = argc > 1 ? (unsigned)strtoul(argv[1], NULL, 10) : 0;
    const unsigned widths[] = {8, 16, 32, 64, 64};
    const kernel_t kernels[] = {volatile_native_8, volatile_native_16, volatile_native_32, volatile_native_64, volatile_native_ptr};
    page_size = (size_t)sysconf(_SC_PAGESIZE);
    unsigned char *mapping = mmap(NULL, page_size * 3, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (mapping == MAP_FAILED) return 2;
    watched_page = mapping + page_size;
    struct sigaction old_segv, old_trap, action;
    memset(&action, 0, sizeof action); sigemptyset(&action.sa_mask); action.sa_flags = SA_SIGINFO;
    action.sa_sigaction = segv; if (sigaction(SIGSEGV, &action, &old_segv)) return 2;
    action.sa_sigaction = trap; if (sigaction(SIGTRAP, &action, &old_trap)) return 2;
    size_t observations = 0;
    for (unsigned shape = 0; shape < 5; shape++) for (unsigned seed = 0; seed < 16; seed++) {
        const unsigned bits = widths[shape]; access_bytes = bits / 8;
        const uint64_t mask = bits == 64 ? UINT64_MAX : (UINT64_C(1) << bits) - 1;
        const uint64_t initial = (seed == 0 ? 0 : seed == 1 ? UINT64_MAX : UINT64_C(0xf06dea67e461de5b) * seed) & mask;
        watched_address = watched_page + page_size - access_bytes;
        if (mprotect(watched_page, page_size, PROT_READ | PROT_WRITE)) return 2;
        memcpy(watched_address, &initial, access_bytes); memset(events, 0, sizeof events); count = pending = 0;
        if (mprotect(watched_page, page_size, PROT_NONE)) return 2;
        active = 1;
        uint64_t returned = kernels[shape](watched_address, (void *)(uintptr_t)47, (void *)(uintptr_t)99);
        active = 0;
        if (mprotect(watched_page, page_size, PROT_READ | PROT_WRITE)) return 2;
        if (fault == 1) returned ^= 1;
        if (fault == 2) count--;
        if (fault == 3) events[1].after ^= 1;
#define CHECK(c) do { ++observations; if (!(c)) { fprintf(stderr, "volatile-native shape=%u seed=%u observation=%zu fault=%u\n", shape, seed, observations, fault); return 1; } } while (0)
        CHECK(returned == initial + 99); CHECK(count == 7); CHECK(read_word() == 99);
        for (unsigned i = 0; i < 7; i++) {
            CHECK(events[i].write == (i == 1 || i == 3 || i == 5));
            CHECK(events[i].address == (uintptr_t)watched_address);
            if (i == 0 || i == 2 || i == 4 || i == 6) CHECK(events[i].before == events[i].after);
        }
        CHECK(events[0].before == initial); CHECK(events[1].after == 47); CHECK(events[2].before == 47);
        CHECK(events[4].before == events[3].after); CHECK(events[5].after == 99); CHECK(events[6].before == 99);
    }
    if (sigaction(SIGSEGV, &old_segv, NULL) || sigaction(SIGTRAP, &old_trap, NULL) || munmap(mapping, page_size * 3)) return 2;
    printf("volatile-native observations=%zu single-step-events=unused-loads=unspecified-store=exact-widths=preserved\n", observations);
    return 0;
}
