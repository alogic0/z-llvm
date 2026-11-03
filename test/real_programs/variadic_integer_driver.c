#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

extern int32_t exercise_one(int32_t, const void *);
extern int32_t exercise_two(int32_t, const void *, const void *);
extern int32_t exercise_immediate(const void *);
extern int32_t exercise_heap(void);
extern int32_t exercise_one_no_live(int32_t, const void *);
extern int32_t exercise_heap_value(int32_t);
void *zllvm_alloc(uint64_t size) { return malloc((size_t)size); }
static const uint32_t first = 0x12345678u, second = 0xabcdef01u;

int32_t zllvm_varargs_one_impl(const uint32_t *p, int32_t value) {
    if (p != &first || *p != first) return -999;
    return (int32_t)((uint32_t)value ^ first);
}

int32_t zllvm_varargs_two_impl(const uint32_t *p, const uint32_t *q, int32_t value) {
    if (p != &first || q != &second || *p != first || *q != second) return -998;
    return (int32_t)((uint32_t)value ^ first ^ second);
}

int main(void) {
    const int32_t values[] = {0, -1, 123, INT32_MIN, INT32_MAX};
    for (unsigned i = 0; i < sizeof(values) / sizeof(values[0]); ++i) {
        int32_t value = values[i];
        uint32_t one = ((uint32_t)value ^ first) + (uint32_t)value + 17u;
        uint32_t two = ((uint32_t)value ^ first ^ second) + (uint32_t)value + 29u;
        if ((uint32_t)exercise_one(value, &first) != one) return 1;
        if ((uint32_t)exercise_two(value, &first, &second) != two) return 2;
        if ((uint32_t)exercise_one_no_live(value, &first) != ((uint32_t)value ^ first)) return 5;
        if (exercise_heap_value(value) != value) return 6;
    }
    if ((uint32_t)exercise_immediate(&first) != (UINT32_MAX ^ first)) return 3;
    if (exercise_heap() != 123) return 4;
    puts("integer-call-canary varargs_cases=16 heap_cases=6 al=0 pointers=preserved live=preserved");
    return 0;
}
