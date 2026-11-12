#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern void frame_compact_abs64(const void *, void *);
struct context { unsigned fault, failed; size_t observations; };
static uint16_t u16(const void *p) { uint16_t x; memcpy(&x, p, 2); return x; }
static uint64_t u64(const void *p) { uint64_t x; memcpy(&x, p, 8); return x; }
static const struct { uint64_t lo; uint16_t hi; } values[] = {
    {0,0}, {0,0x8000}, {1,0}, {UINT64_C(0x8000000000000000),0x3fff},
    {UINT64_C(0x8000000000000000),0xbfff}, {UINT64_C(0x8000000000000000),0xffff},
    {UINT64_C(0xc000000000000123),0xffff}, {UINT64_C(0x8000000000000001),0xffff}
};
static void *worker(void *opaque) {
    struct context *c = opaque;
    unsigned char input[640], output[656];
#define WORK_CHECK(condition) do { ++c->observations; if (!(condition)) { \
    fprintf(stderr,"frame-compaction fault=%u observation=%zu\n",c->fault,c->observations); \
    c->failed=1; return NULL; } } while (0)
    for (unsigned seed=0; seed<8; ++seed) {
        for (unsigned i=0; i<64; ++i) {
            unsigned k=(seed+i)%8;
            memcpy(input+10*i,&values[k].lo,8); memcpy(input+10*i+8,&values[k].hi,2);
        }
        memset(output,0xa5,sizeof output);
        frame_compact_abs64(input,output+8);
        if (c->fault==1) output[8]^=1;
        if (c->fault==2) output[0]^=1;
        if (c->fault==3) output[648]^=1;
        for (unsigned i=0; i<64; ++i) {
            unsigned k=(seed+i)%8;
            WORK_CHECK(u64(output+8+10*i)==values[k].lo && u16(output+16+10*i)==(values[k].hi&0x7fff));
        }
        for (unsigned i=0; i<8; ++i) WORK_CHECK(output[i]==0xa5);
        for (unsigned i=648; i<sizeof output; ++i) WORK_CHECK(output[i]==0xa5);
    }
    return NULL;
}
int main(int argc, char **argv) {
    struct context c = {argc>1 ? (unsigned)strtoul(argv[1],0,10) : 0,0,0};
    size_t setup_observations=0;
#define CHECK(condition) do { ++setup_observations; if (!(condition)) { \
    fprintf(stderr,"frame-compaction fault=%u setup=%zu\n",c.fault,setup_observations); return 1; } } while (0)
    pthread_attr_t attr;
    pthread_t thread;
    CHECK(pthread_attr_init(&attr)==0);
    CHECK(pthread_attr_setstacksize(&attr,65536)==0);
    CHECK(pthread_create(&thread,&attr,worker,&c)==0);
    CHECK(pthread_attr_destroy(&attr)==0);
    CHECK(pthread_join(thread,NULL)==0);
    CHECK(c.failed==0);
    printf("frame-compaction observations=%zu frame-budget=65536 payloads=guards=preserved\n",setup_observations+c.observations);
    return 0;
}
