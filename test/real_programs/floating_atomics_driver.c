#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <pthread.h>

typedef uint64_t (*operation)(void *, uint64_t, uint64_t *, uint64_t);
#define DECLARE(OP,BITS) extern uint64_t floating_atomic_##OP##_##BITS(void *,uint64_t,uint64_t *,uint64_t);
DECLARE(add,32) DECLARE(sub,32) DECLARE(max,32) DECLARE(min,32)
DECLARE(add,64) DECLARE(sub,64) DECLARE(max,64) DECLARE(min,64)
static operation operations[2][4] = {
    {floating_atomic_add_32,floating_atomic_sub_32,floating_atomic_max_32,floating_atomic_min_32},
    {floating_atomic_add_64,floating_atomic_sub_64,floating_atomic_max_64,floating_atomic_min_64}
};
static uint32_t bits32(float value) { uint32_t bits; memcpy(&bits,&value,4); return bits; }
static uint64_t bits64(double value) { uint64_t bits; memcpy(&bits,&value,8); return bits; }
static float float32(uint32_t bits) { float value; memcpy(&value,&bits,4); return value; }
static double float64(uint64_t bits) { double value; memcpy(&value,&bits,8); return value; }
static uint64_t cell;
struct worker { uint64_t sum; };
static void *increment(void *opaque) {
    struct worker *worker=opaque;
    for(unsigned i=0;i<1000;i++) {
        uint64_t out[2];
        uint64_t old=floating_atomic_add_32(&cell,bits32(1.0f),out,0);
        worker->sum += (uint64_t)float32((uint32_t)old);
    }
    return NULL;
}
int main(int argc,char **argv) {
    const unsigned fault=argc>1 ? (unsigned)strtoul(argv[1],0,10) : 0;
    size_t observations=0;
#define CHECK(condition) do { ++observations; if(!(condition)) { fprintf(stderr,"floating-atomics fault=%u observation=%zu\n",fault,observations); return 1; } } while(0)
    const uint32_t values32[]={0,0x80000000,0x3fc00000,0xc0500000,0x7f800000,0xff800000,0x7fc12345,0x7f812345,1};
    const uint64_t values64[]={0,UINT64_C(0x8000000000000000),UINT64_C(0x3ff8000000000000),UINT64_C(0xc00a000000000000),UINT64_C(0x7ff0000000000000),UINT64_C(0xfff0000000000000),UINT64_C(0x7ff8123456789abc),UINT64_C(0x7ff0123456789abc),1};
    for(unsigned width=0;width<2;width++) for(unsigned op=0;op<4;op++)
    for(unsigned i=0;i<9;i++) for(unsigned j=0;j<9;j++) {
        uint64_t left=width ? values64[i] : values32[i];
        uint64_t right=width ? values64[j] : values32[j];
        uint64_t cells[]={UINT64_C(0x123456789abcdef0),left | (width ? 0 : UINT64_C(0xa5a5a5a500000000)),UINT64_C(0xfedcba9876543210)};
        uint64_t out[2]={0,0};
        uint64_t old=operations[width][op](&cells[1],right,out,UINT64_C(0x5790));
        if(fault==1) old^=1;
        if(fault==2) cells[1]^=1;
        if(fault==3) cells[0]^=1;
        CHECK(old==left);
        CHECK(out[0]==left);
        CHECK(out[1]==(right^UINT64_C(0x5790)));
        CHECK(cells[0]==UINT64_C(0x123456789abcdef0));
        CHECK(cells[2]==UINT64_C(0xfedcba9876543210));
        if(width) {
            double a=float64(left),b=float64(right),actual=float64(cells[1]);
            double expected=op==0 ? a+b : op==1 ? a-b : op==2 ? fmax(a,b) : fmin(a,b);
            if(op>=2) expected=isnan(a) ? b : isnan(b) ? a : expected;
            CHECK(isnan(expected) ? isnan(actual) : actual==expected);
            CHECK(op>=2 || isnan(expected) || cells[1]==bits64(expected));
        } else {
            float a=float32((uint32_t)left),b=float32((uint32_t)right),actual=float32((uint32_t)cells[1]);
            float expected=op==0 ? a+b : op==1 ? a-b : op==2 ? fmaxf(a,b) : fminf(a,b);
            if(op>=2) expected=isnan(a) ? b : isnan(b) ? a : expected;
            CHECK(isnan(expected) ? isnan(actual) : actual==expected);
            CHECK((cells[1]>>32)==UINT64_C(0xa5a5a5a5) && (op>=2 || isnan(expected) || (uint32_t)cells[1]==bits32(expected)));
        }
    }
    pthread_t threads[4];
    struct worker workers[4]={{0},{0},{0},{0}};
    cell=UINT64_C(0xa5a5a5a500000000);
    for(unsigned i=0;i<4;i++) CHECK(pthread_create(&threads[i],NULL,increment,&workers[i])==0);
    for(unsigned i=0;i<4;i++) CHECK(pthread_join(threads[i],NULL)==0);
    CHECK(float32((uint32_t)cell)==4000.0f);
    CHECK((cell>>32)==UINT64_C(0xa5a5a5a5));
    uint64_t sum=0;
    for(unsigned i=0;i<4;i++) sum+=workers[i].sum;
    CHECK(sum==UINT64_C(4000)*3999/2);
    printf("floating-atomics observations=%zu returned-bits=guards=preserved contention=linearized\n",observations);
    return 0;
}
