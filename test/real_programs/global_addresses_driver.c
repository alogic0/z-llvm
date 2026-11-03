#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern void *global_object_address(void);
extern void *global_payload_address(void);
extern void *global_bits_address(void);
extern uint64_t global_live_offset(uint64_t);

uint64_t global_address_echo(uint64_t value) { return value ^ UINT64_C(0xdeadbeef12345678); }

int main(void) {
    struct Object {
        uint8_t tag;
        uint64_t number;
        unsigned char *payload;
        uint16_t halfwords[2];
        uint64_t (*function)(uint64_t);
    } object;
    const uint64_t values[] = {0, 1, 127, 128, UINT32_MAX, UINT64_C(1) << 63,
                               UINT64_MAX, UINT64_C(0xdeadbeef01234567)};
    unsigned observations = 0;
    for (unsigned i = 0; i < sizeof(values) / sizeof(values[0]); ++i) {
        void *address = global_object_address();
        if (((uintptr_t)address & 63) != 0) return 1;
        memcpy(&object, address, sizeof(object));
        if (object.tag != 165 || object.number != UINT32_MAX ||
            object.halfwords[0] != UINT16_MAX || object.halfwords[1] != 4660 ||
            object.function != global_address_echo ||
            object.function(values[i]) != global_address_echo(values[i])) return 2;
        ++observations;
        unsigned char *payload = global_payload_address();
        if (memcmp(payload, "payload", 8) || object.payload != payload + 3) return 3;
        ++observations;
        unsigned char *bits = global_bits_address();
        uint64_t pointer_bits;
        memcpy(&pointer_bits, bits, 8);
        if (pointer_bits != UINT64_MAX) return 4;
        for (unsigned byte = 16; byte < 32; ++byte) if (bits[byte] != 255) return 5;
        ++observations;
        if (global_live_offset(values[i]) != (((uintptr_t)address + 8) ^ values[i])) return 6;
        ++observations;
    }
    printf("global-addresses observations=%u layout=pointers=alignment=live=preserved\n", observations);
    return 0;
}
