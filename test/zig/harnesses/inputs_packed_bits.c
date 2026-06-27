#include <stdbool.h>
extern bool z_read_flag(unsigned char) __asm__("packed_bits.read_flag");
extern unsigned char z_replace_low(unsigned char, unsigned char) __asm__("packed_bits.replace_low");
int main(void) {
    if (!z_read_flag(128)) return 1;
    if (z_read_flag(0)) return 2;
    if (z_replace_low(0xf0u, 0x0bu) != 0xf3u) return 3;
    return 0;
}

