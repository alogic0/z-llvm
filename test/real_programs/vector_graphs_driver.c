#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern uint64_t vector_graph_phi8(void *, void *, uint32_t, uint64_t);
extern uint64_t vector_graph_parallel(void *, void *, uint32_t);
extern uint64_t vector_graph_wide(void *, void *, void *);
extern uint64_t vector_graph_repack(void *, void *);
extern void *vector_graph_pointers(void *, void *, uint32_t, void *);
extern uint64_t vector_graph_freeze(uint64_t, void *);
extern uint32_t vector_graph_intrinsics(void *, void *);
extern uint64_t vector_graph_ctpop6(void *, void *);

static uint64_t next(uint64_t *state) {
    *state ^= *state << 13; *state ^= *state >> 7; *state ^= *state << 17;
    return *state;
}
int main(void) {
    uint64_t state = UINT64_C(0xd5347ac0b91e286f);
    unsigned observations = 0;
    for (unsigned i = 0; i < 128; ++i) {
        uint64_t left[8], right[8];
        for (unsigned j = 0; j < 8; ++j) { left[j] = next(&state); right[j] = next(&state); }
        if (i % 8 == 0) { left[0] = UINT64_MAX; right[0] = 1; }
        const unsigned offset = 1 + i % 15, steps = 1 + i % 8;
        unsigned char out[96], expected[96], bytes[8], pool[64];
        memcpy(bytes, left, 8);
        for (unsigned step = 0; step < steps; ++step) {
            unsigned char changed[8];
            for (unsigned j = 0; j < 8; ++j) changed[j] = bytes[(j + 7) % 8] ^ 165;
            memcpy(bytes, changed, 8);
        }
        uint64_t bits; memcpy(&bits, bytes, 8);
        memset(out, 0x5a, sizeof out); memcpy(expected, out, sizeof out); memcpy(expected + offset, bytes, 8);
        if (vector_graph_phi8(left, out + offset, steps, right[7]) != (bits ^ right[7]) || memcmp(out, expected, sizeof out)) return 1;
        ++observations;

        const unsigned swap = (steps - 1) & 1;
        memset(out, 0x5a, sizeof out); memcpy(expected, out, sizeof out);
        memcpy(expected + offset, left + (swap ? 2 : 0), 16);
        memcpy(expected + offset + 16, left + (swap ? 0 : 2), 16);
        const uint64_t parallel = left[swap ? 2 : 0] ^ left[swap ? 1 : 3];
        if (vector_graph_parallel(left, out + offset, steps) != parallel || memcmp(out, expected, sizeof out)) return 2;
        ++observations;

        uint64_t carries[4], fold = 0;
        for (unsigned j = 0; j < 4; ++j) {
            const unsigned __int128 sum = (unsigned __int128)left[j] + right[j];
            carries[j] = (uint64_t)(sum >> 64); fold += (uint64_t)sum;
        }
        memset(out, 0x5a, sizeof out); memcpy(expected, out, sizeof out); memcpy(expected + offset, carries, 32);
        if (vector_graph_wide(left, right, out + offset) != fold || memcmp(out, expected, sizeof out)) return 3;
        ++observations;

        uint32_t halves[8], mixed[8];
        const unsigned order[] = {7, 0, 6, 1, 5, 2, 4, 3};
        memcpy(halves, left, 32);
        for (unsigned j = 0; j < 8; ++j) mixed[j] = halves[order[j]];
        unsigned __int128 pairs[2]; memcpy(pairs, mixed, 32);
        pairs[0] >>= 13; pairs[1] >>= 7;
        memset(out, 0x5a, sizeof out); memcpy(expected, out, sizeof out); memcpy(expected + offset, pairs, 32);
        if (vector_graph_repack(left, out + offset) != ((uint64_t)pairs[0] ^ (uint64_t)pairs[1]) || memcmp(out, expected, sizeof out)) return 4;
        ++observations;

        void *fallback = pool + i % 32;
        void *pointers[2] = { i % 3 ? pool + 40 : 0, i % 5 ? pool + 48 : 0 };
        void *filled[2] = { pointers[0] ? pointers[0] : fallback, pointers[1] ? pointers[1] : fallback };
        filled[i & 1] = fallback;
        void *reversed[2] = { filled[1], filled[0] };
        memset(out, 0x5a, sizeof out); memcpy(expected, out, sizeof out); memcpy(expected + offset, reversed, 16);
        if (vector_graph_pointers(pointers, out + offset, i & 1, fallback) != reversed[i & 1] || memcmp(out, expected, sizeof out)) return 5;
        ++observations;

        uint16_t frozen[4] = { (uint16_t)left[0], 9, (uint16_t)(left[0] >> 16), 11 };
        uint64_t frozen_bits; memcpy(&frozen_bits, frozen, 8);
        memset(out, 0x5a, sizeof out); memcpy(expected, out, sizeof out); memcpy(expected + offset, frozen, 8);
        if (vector_graph_freeze(left[0], out + offset) != frozen_bits || memcmp(out, expected, sizeof out)) return 6;
        ++observations;

        uint32_t input[4], reversed_words[4], saturated[4], sum = 0;
        const unsigned shifts[] = {0, 1, 17, 31}, subtrahends[] = {3, 7, 31, 32};
        memcpy(input, left, 16);
        for (unsigned j = 0; j < 4; ++j) {
            const unsigned n = shifts[j];
            const uint32_t rotated = n ? (input[j] << n) | (input[j] >> (32 - n)) : input[j];
            reversed_words[j] = __builtin_bswap32(rotated);
            const unsigned count = __builtin_popcount(reversed_words[j]);
            saturated[j] = count > subtrahends[j] ? count - subtrahends[j] : 0;
            sum += saturated[j];
        }
        memset(out, 0x5a, sizeof out); memcpy(expected, out, sizeof out);
        memcpy(expected + offset, reversed_words, 16); memcpy(expected + offset + 16, saturated, 16);
        if (vector_graph_intrinsics(left, out + offset) != sum || memcmp(out, expected, sizeof out)) return 7;
        ++observations;

        uint64_t counts[6], total = 0;
        for (unsigned j = 0; j < 6; ++j) { counts[j] = __builtin_popcountll(left[j]); total += counts[j]; }
        memset(out, 0x5a, sizeof out); memcpy(expected, out, sizeof out); memcpy(expected + offset, counts, 48);
        if (vector_graph_ctpop6(left, out + offset) != total || memcmp(out, expected, sizeof out)) return 8;
        ++observations;
    }
    printf("vector-graphs observations=%u phi=wide=pointer=intrinsics=guards=preserved\n", observations);
    return 0;
}
