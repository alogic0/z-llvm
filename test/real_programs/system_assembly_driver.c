#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/syscall.h>

extern long system_call0(long);
extern long system_call1(long, long);
extern long system_call2(long, long, long);
extern long system_call3(long, long, long, long);
extern long system_call4(long, long, long, long, long);
extern long system_call5(long, long, long, long, long, long);
extern long system_call6(long, long, long, long, long, long, long);
extern uint64_t system_pressure(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t);
extern void system_snapshot(uint64_t *);

int main(void) {
    int fd = open("/dev/null", O_WRONLY);
    if (fd < 0) return 1;
    unsigned observations = 0;
    for (unsigned i = 0; i < 128; ++i) {
        if (system_call0(SYS_getpid) != getpid()) return 2;
        if (system_call1(SYS_close, -1) != -9) return 3;
        if (system_call2(SYS_kill, getpid(), 0) != 0) return 4;
        char data[16] = {0};
        if (system_call3(SYS_write, fd, (long)data, sizeof(data)) != sizeof(data)) return 5;
        uint64_t mask = 0;
        if (system_call4(SYS_rt_sigprocmask, 0, 0, (long)&mask, 8) != 0) return 6;
        struct statx info = {0};
        if (system_call5(SYS_statx, AT_FDCWD, (long)"/proc/self", 0, STATX_TYPE, (long)&info) != 0 || !S_ISDIR(info.stx_mode)) return 7;
        long address = system_call6(SYS_mmap, 0, 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
        if ((unsigned long)address >= (unsigned long)-4095) return 8;
        volatile uint64_t *memory = (void *)address;
        memory[0] = i;
        memory[511] = ~((uint64_t)i);
        if (memory[0] != i || memory[511] != ~((uint64_t)i) || munmap((void *)address, 4096)) return 9;
        uint64_t a = ((uint64_t)i << 48) | 0x80000000u;
        uint64_t b = i & 1 ? a + 1 : a - 1;
        uint64_t c = UINT64_C(0xfedcba9876543210) + i;
        uint64_t d = (uint64_t)i * 0x102030405u;
        uint64_t e = ~a, f = ~c;
        uint64_t expected = a < b ? (a ^ b) + (c + d) + ((e ^ f) ^ (uint64_t)getpid()) : (a ^ b);
        if (system_pressure(a, b, c, d, e, f) != expected) return 10;
        uint64_t snapshot[19] = {0};
        snapshot[0] = snapshot[18] = UINT64_C(0xabcdef0123456789);
        system_snapshot(snapshot + 1);
        if (snapshot[0] != UINT64_C(0xabcdef0123456789) || snapshot[18] != snapshot[0] ||
            snapshot[6] != (uintptr_t)(snapshot + 1) || snapshot[8] == 0 ||
            (snapshot[8] & 7) || snapshot[17] == 0) return 12;
        observations += 9;
    }
    if (close(fd)) return 11;
    printf("system-assembly observations=%u syscall-arity=0-6 live=preserved snapshot=bounded\n", observations);
    return 0;
}
