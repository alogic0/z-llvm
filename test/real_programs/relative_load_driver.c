#include <stdint.h>
#include <stdio.h>
#include <string.h>
extern unsigned char *relative_load(const void *, int64_t);
extern uint64_t relative_load_live(const void *, int64_t, uint64_t);
int main(void) {
    _Alignas(16) unsigned char storage[512];
    unsigned char *base = storage + 256;
    unsigned observations = 0;
    for (unsigned i = 0; i < 256; ++i) {
        memset(storage, (int)(i & 255), sizeof storage);
        int32_t target = (i & 1) ? 100 : -100;
        int64_t slot = (int64_t)(i % 16) * 4 - 32;
        memcpy(base + slot, &target, 4);
        uint64_t live = UINT64_C(0xdeadbeef01234567) * (i + 1);
        if (relative_load(base, slot) != base + target) return 1;
        ++observations;
        if (relative_load_live(base, slot, live) != ((i & 255) ^ live)) return 2;
        ++observations;
    }
    printf("relative-load observations=%u signed=base=live=preserved\n", observations);
    return 0;
}
