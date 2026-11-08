#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <unistd.h>

extern long sysfact0(long);
extern long sysfact1(long, long);
extern long sysfact2(long, long, long);
extern long sysfact3(long, long, long, long);
extern long sysfact4(long, long, long, long, long);
extern long sysfact5(long, long, long, long, long, long);
extern long sysfact6(long, long, long, long, long, long, long);
extern uint64_t sysfact_live(long, const void *, uint64_t, uint64_t, uint64_t, double *, double);

int main(void) {
    FILE *file = tmpfile();
    int sink = open("/dev/null", O_WRONLY);
    if (!file || sink < 0) return 1;
    int fd = fileno(file);
    unsigned char data[8192];
    for (unsigned i = 0; i < sizeof(data); ++i) data[i] = (unsigned char)(i * 37 + i / 256);
    if (write(fd, data, sizeof(data)) != sizeof(data)) return 2;
    unsigned observations = 0;
    for (unsigned i = 0; i < 128; ++i) {
        if (sysfact0(SYS_getpid) != getpid()) return 3;
        if (sysfact1(-1, SYS_close) != -EBADF) return 4;
        if (sysfact2(8192, fd, SYS_ftruncate) != 0) return 5;
        struct stat size;
        if (fstat(fd, &size) || size.st_size != 8192) return 6;
        size_t length = i % 64 + 1;
        if (sysfact3(length, (long)data, sink, SYS_write) != (long)length) return 7;
        struct { unsigned char before[8], bytes[64], after[8]; } readback;
        memset(&readback, 0xa5, sizeof(readback));
        size_t offset = 37 * i;
        if (sysfact4(offset, length, (long)readback.bytes, fd, SYS_pread64) != (long)length) return 8;
        if (memcmp(readback.bytes, data + offset, length)) return 9;
        for (unsigned j = 0; j < sizeof(readback.before); ++j)
            if (readback.before[j] != 0xa5 || readback.after[j] != 0xa5) return 10;
        for (size_t j = length; j < sizeof(readback.bytes); ++j)
            if (readback.bytes[j] != 0xa5) return 11;
        struct statx info = {0};
        if (sysfact5((long)&info, STATX_TYPE, 0, (long)"/proc/self", AT_FDCWD, SYS_statx) != 0 || !S_ISDIR(info.stx_mode)) return 12;
        int anonymous = i & 1;
        long address = sysfact6(anonymous ? 0 : 4096, anonymous ? -1 : fd,
                               MAP_PRIVATE | (anonymous ? MAP_ANONYMOUS : 0),
                               PROT_READ | PROT_WRITE, 4096, 0, SYS_mmap);
        if ((unsigned long)address >= (unsigned long)-4095) return 13;
        volatile unsigned char *memory = (void *)address;
        if (memory[0] != (anonymous ? 0 : data[4096]) || memory[4095] != (anonymous ? 0 : data[8191])) return 14;
        memory[0] = (unsigned char)i;
        memory[4095] = (unsigned char)~i;
        if (memory[0] != (unsigned char)i || memory[4095] != (unsigned char)~i || munmap((void *)address, 4096)) return 15;
        observations += 7;
        for (unsigned error_case = 0; error_case < 2; ++error_case) {
            uint64_t a = UINT64_C(0xfedcba9876543210) + i;
            uint64_t b = i & 1 ? a + 7 : a - 3;
            double x = i * 0.5 - 32;
            struct { uint64_t before; double value; uint64_t after; } output = {
                UINT64_C(0x123456789abcdef0), 0, UINT64_C(0x0fedcba987654321)
            };
            uint64_t result = error_case ? (uint64_t)-EBADF : length;
            uint64_t word = a < b ? a + 17 : b ^ UINT64_C(305419896);
            uint64_t expected = ((word ^ a) + b) ^ result;
            if (a < b) expected += length;
            if (sysfact_live(error_case ? -1 : sink, data, length, a, b, &output.value, x) != expected) return 16;
            if (output.value != x + 1.25 || output.before != UINT64_C(0x123456789abcdef0) ||
                output.after != UINT64_C(0x0fedcba987654321)) return 17;
            ++observations;
        }
    }
    if (close(sink) || fclose(file)) return 18;
    printf("syscall-facts observations=%u arity=0-6 arguments=memory=errors=live=phis=preserved\n", observations);
    return 0;
}
