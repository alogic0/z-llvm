#define _GNU_SOURCE
#include <inttypes.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <unistd.h>

extern uint64_t large_frame_2m(uint64_t, uint64_t, uint64_t *);
extern uint64_t large_frame_4m(uint64_t, uint64_t, uint64_t *);
extern uint64_t large_frame_7m(uint64_t, uint64_t, uint64_t *);
extern uint64_t large_frame_probe(void);
enum { object_bytes = 1048576, max_objects = 7 };
static uintptr_t addresses[max_objects];
static unsigned fills, checks, expected_objects, errors;

static uint64_t word_value(uint64_t seed, unsigned id, unsigned index) {
    return (seed ^ (UINT64_C(0x9e3779b97f4a7c15) * (id + 1))) +
           UINT64_C(0x100000001b3) * index;
}
static uint64_t answer(uint64_t seed, unsigned id) {
    return (seed + UINT64_C(0xd1b54a32d192ed03) * (id + 1)) ^
           word_value(seed, id, object_bytes / 8 - 1);
}
__attribute__((noinline))
void large_frame_fill(void *storage, uint64_t id64, uint64_t seed) {
    unsigned id = (unsigned)id64;
    uintptr_t address = (uintptr_t)storage;
    if (id64 != id || id != fills || id >= expected_objects || (address & 15)) abort();
    for (unsigned previous = 0; previous < fills; ++previous)
        if (!(address + object_bytes <= addresses[previous] ||
              addresses[previous] + object_bytes <= address)) abort();
    addresses[id] = address;
    ++fills;
    for (unsigned index = 0; index < object_bytes / 8; ++index) {
        uint64_t value = word_value(seed, id, index);
        memcpy((uint8_t *)storage + index * 8, &value, 8);
    }
    __asm__ volatile("mov $17, %%rax\n\tmov $19, %%rcx\n\tmov $23, %%rdx\n\t"
                     "mov $29, %%rsi\n\tmov $31, %%rdi\n\tmov $37, %%r8\n\t"
                     "mov $41, %%r9\n\tmov $43, %%r10\n\tmov $47, %%r11"
                     ::: "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "cc", "memory");
}
__attribute__((noinline))
uint64_t large_frame_check(const void *storage, uint64_t id64, uint64_t seed) {
    unsigned id = (unsigned)id64;
    if (id64 != id || id != checks || fills != expected_objects ||
        id >= expected_objects || addresses[id] != (uintptr_t)storage) abort();
    ++checks;
    for (unsigned index = 0; index < object_bytes / 8; ++index) {
        uint64_t value;
        memcpy(&value, (const uint8_t *)storage + index * 8, 8);
        if (value != word_value(seed, id, index)) ++errors;
    }
    return answer(seed, id);
}
__attribute__((noinline))
uint64_t large_frame_probe_sink(const void *storage) {
    if ((uintptr_t)storage & 15) abort();
    __asm__ volatile("" :: "r"(storage) : "memory");
    return 124;
}

extern uint64_t large_frame_on_stack(void *, uint64_t (*)(void));
__asm__(".text\n.type large_frame_on_stack,@function\nlarge_frame_on_stack:\n"
        "push %r12\nmov %rsp,%r12\nmov %rdi,%rsp\ncall *%rsi\nmov %r12,%rsp\npop %r12\nret\n"
        ".size large_frame_on_stack,.-large_frame_on_stack\n");
__attribute__((noinline)) static uint64_t small_frame(void) {
    __asm__ volatile("" ::: "memory");
    return 124;
}
static int child_check(void *top, uint64_t (*run)(void), int signal_expected) {
    pid_t child = fork();
    if (child < 0) return 1;
    if (child == 0) {
        const struct rlimit limit = {0, 0};
        if (setrlimit(RLIMIT_CORE, &limit)) _exit(3);
        _exit(large_frame_on_stack(top, run) == 124 ? 0 : 2);
    }
    int status = 0;
    if (waitpid(child, &status, 0) != child) return 1;
    return signal_expected ? !(WIFSIGNALED(status) && WTERMSIG(status) == SIGSEGV)
                           : !(WIFEXITED(status) && WEXITSTATUS(status) == 0);
}
static int probe_checks(void) {
    long page = sysconf(_SC_PAGESIZE);
    if (page != 4096) return 2;
    size_t length = 12 * 1024 * 1024;
    uint8_t *memory = mmap(NULL, length, PROT_READ | PROT_WRITE,
                           MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (memory == MAP_FAILED) return 2;
    void *top = memory + length - 16;
    int failed = child_check(top, large_frame_probe, 0);
    if (mprotect(memory + length - 2 * page, (size_t)page, PROT_NONE)) failed = 1;
    failed |= child_check(top, small_frame, 0);
    failed |= child_check(top, large_frame_probe, 1);
    if (munmap(memory, length)) failed = 1;
    if (failed) {
        fputs("large-frame stack probe did not stop at the guard page\n", stderr);
        return 1;
    }
    puts("bounded-storage guard_checks=3 accessible=small-frame=guard-fault=verified");
    return 0;
}
int main(int argc, char **argv) {
    if (argc == 2 && strcmp(argv[1], "--guard-probe") == 0) return probe_checks();
    if (argc != 1) return 2;
    uint64_t (*functions[])(uint64_t, uint64_t, uint64_t *) = {
        large_frame_2m, large_frame_4m, large_frame_7m
    };
    const unsigned object_counts[] = {2, 4, 7};
    const uint64_t seeds[] = {0, 1, UINT64_MAX, UINT64_C(0x80000000deadbeef)};
    const uint64_t guard = UINT64_C(0xa5a5a5a5a5a5a5a5);
    unsigned observations = 0;
    for (unsigned f = 0; f < 3; ++f) for (unsigned i = 0; i < 4; ++i)
        for (unsigned j = 0; j < 4; ++j) {
            uint64_t seed = seeds[i], salt = seeds[j];
            uint64_t output[] = {guard, UINT64_C(0xdeadbeef), guard};
            fills = checks = errors = 0;
            expected_objects = object_counts[f];
            uint64_t expected = seed ^ salt;
            for (unsigned id = 0; id < expected_objects; ++id) expected ^= answer(seed, id);
            uint64_t result = functions[f](seed, salt, output + 1);
            if (errors || fills != expected_objects || checks != expected_objects ||
                output[0] != guard || output[2] != guard || output[1] != expected ||
                result != (expected ^ salt)) {
                fprintf(stderr, "large-frame f=%u seed=%" PRIx64 " salt=%" PRIx64 " errors=%u\n",
                        f, seed, salt, errors);
                return 1;
            }
            ++observations;
        }
    for (unsigned i = 0; i < 16; ++i) {
        if (large_frame_probe() != 124) return 1;
        ++observations;
    }
    if (observations != 64) return 2;
    puts("large-frame observations=64 objects=2m=4m=7m pages=clobbers=live=guards=preserved");
    return 0;
}
