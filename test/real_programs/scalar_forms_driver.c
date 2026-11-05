#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern uint64_t forms_min64(uint64_t, uint64_t, uint64_t *);
extern uint32_t forms_min32(uint32_t, uint32_t);
extern uint64_t forms_min_loaded(const uint64_t *, const uint64_t *);
extern uint32_t forms_le32(int32_t);
extern uint32_t forms_le64(int64_t);
extern uint32_t forms_le_named64(int64_t, int64_t);
extern uint32_t forms_switch(uint32_t);
extern uint64_t forms_memset_undef(uint64_t *, uint64_t, uint64_t);
extern uint64_t forms_memset_stack16(uint64_t, uint64_t);
extern void forms_memset_stack24(uint64_t *);

int main(void) {
    const uint64_t inputs[] = {0, 1, 65535, 65536, UINT32_MAX,
                              UINT64_C(1) << 63, UINT64_MAX, UINT64_C(0xdeadbeef01234567)};
    const uint64_t guard = UINT64_C(0x5a5a5a5a5a5a5a5a);
    unsigned observations = 0;
    for (unsigned i = 0; i < 8; ++i) for (unsigned j = 0; j < 8; ++j) {
        const uint64_t a = inputs[i], b = inputs[j], minimum = a < b ? a : b;
        const uint32_t a32 = (uint32_t)a, b32 = (uint32_t)b;
        int64_t sa, sb;
        int32_t sa32;
        memcpy(&sa, &a, sizeof(sa));
        memcpy(&sb, &b, sizeof(sb));
        memcpy(&sa32, &a32, sizeof(sa32));
        uint64_t output[] = {guard, 0, 0, guard};
        if (forms_min64(a, b, output + 1) != (a ^ b) || output[1] != minimum ||
            output[0] != guard || output[2] != 0 || output[3] != guard) return 1;
        ++observations;
        if (forms_min32(a32, b32) != (a32 < b32 ? a32 : b32)) return 2;
        ++observations;
        if (forms_min_loaded(&a, &b) != minimum) return 3;
        ++observations;
        if (forms_le32(sa32) != (uint32_t)(sa32 <= 65535)) return 4;
        ++observations;
        if (forms_le64(sa) != (uint32_t)(sa <= 65535)) return 5;
        ++observations;
        if (forms_le_named64(sa, sb) != (uint32_t)(sa <= sb)) return 6;
        ++observations;
        if (forms_switch(i) != (i == 1 ? 8u : 55u)) return 7;
        ++observations;
        /* The undef fill has no required byte pattern. Overwrite its defined
           range before observation; surrounding guards remain observable. */
        if (forms_memset_undef(output + 1, a, b) != (a ^ b) || output[1] != a || output[2] != b ||
            output[0] != guard || output[3] != guard) return 8;
        ++observations;
        if (forms_memset_stack16(a, b) != (a ^ b)) return 9;
        ++observations;
        uint64_t padded[] = {guard, 0, 0, 0, guard};
        forms_memset_stack24(padded + 1);
        if (padded[0] != guard || padded[4] != guard || padded[1] != UINT64_C(0xa5a5a5a5a5a5a5a5) ||
            padded[2] != padded[1] || padded[3] != padded[1]) return 10;
        ++observations;
    }
    printf("scalar-forms observations=%u minimum=signed=phi=memory=live=guards=preserved\n", observations);
    return 0;
}
