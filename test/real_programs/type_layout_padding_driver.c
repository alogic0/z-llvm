#include <stdint.h>
#include <stdio.h>

extern void *layout_i24_field(void *);
extern void *layout_fp80_field(void *);
extern void *layout_nested_field(void *);
extern void *layout_array_field(void *);

int main(void) {
    unsigned char buffer[96];
    void *(*const functions[])(void *) = {
        layout_i24_field, layout_fp80_field, layout_nested_field, layout_array_field
    };
    const uintptr_t expected[] = {4, 16, 8, 16};
    unsigned observations = 0;
    for (unsigned base = 0; base < 32; ++base) {
        for (unsigned field = 0; field < 4; ++field) {
            uintptr_t address = (uintptr_t)(buffer + base);
            if ((uintptr_t)functions[field](buffer + base) != address + expected[field]) return 1 + field;
            ++observations;
        }
    }
    printf("type-layout-padding observations=%u scalar=nested=array=preserved\n", observations);
    return 0;
}
