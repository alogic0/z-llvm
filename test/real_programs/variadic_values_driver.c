#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
extern uint64_t va_sum_u64(unsigned,...);
extern double va_sum_f64(unsigned,...);
extern double va_mixed(unsigned,uint64_t,double,...);
extern uint64_t va_copy_pair(uint64_t,...);
extern uint64_t va_consume_record(void *);
extern uint64_t va_unfixed();
extern uint64_t va_call_unfixed(uint64_t,uint64_t);
static unsigned fault;
static size_t observations;
#define CHECK(c) do { ++observations; if(!(c)) { fprintf(stderr,"variadic-values fault=%u observation=%zu\n",fault,observations); exit(1); } } while(0)
uint64_t va_c_consume(void *opaque) {
    va_list *list=opaque;
    uint64_t a=va_arg(*list,uint64_t);
    uint64_t b=va_arg(*list,uint64_t);
    return 3*a+5*b;
}
static uint64_t c_call_record(uint64_t fixed,...) {
    struct { unsigned char before[16]; va_list list; unsigned char after[16]; } guarded;
    memset(&guarded,0xa5,sizeof guarded);
    va_start(guarded.list,fixed);
    uint64_t value=va_consume_record(&guarded.list);
    va_end(guarded.list);
    if(fault==2) guarded.before[0]^=1;
    for(unsigned i=0;i<16;i++) { CHECK(guarded.before[i]==0xa5); CHECK(guarded.after[i]==0xa5); }
    return value;
}
int main(int argc,char **argv) {
    fault=argc>1 ? (unsigned)strtoul(argv[1],NULL,10) : 0;
    for(uint64_t seed=0;seed<32;seed++) {
        uint64_t u=va_sum_u64(10,seed+1,seed+2,seed+3,seed+4,seed+5,seed+6,seed+7,seed+8,seed+9,seed+10);
        if(fault==1) u^=1;
        CHECK(u==10*seed+55);
        double f=va_sum_f64(10,1.+.5*seed,2.+.5*seed,3.+.5*seed,4.+.5*seed,5.+.5*seed,6.+.5*seed,7.+.5*seed,8.+.5*seed,9.+.5*seed,10.+.5*seed);
        CHECK(f==55.+5.*seed);
        f=va_mixed(10,seed+7,.5,seed+1,1.25,seed+2,2.25,seed+3,3.25,seed+4,4.25,seed+5,5.25,seed+6,6.25,seed+7,7.25,seed+8,8.25,seed+9,9.25,seed+10,10.25);
        CHECK(f==11.*seed+120.);
        uint64_t a=seed+3,b=7*seed+1;
        uint64_t copied=va_copy_pair(UINT64_C(99),a,b);
        if(fault==3) copied^=1;
        CHECK(copied==20*a+22*b);
        CHECK(c_call_record(UINT64_C(0),a,b)==a+b);
        CHECK(va_unfixed(a,b)==a+b);
        CHECK(va_call_unfixed(a,b)==a+b);
    }
    printf("variadic-values observations=%zu gp=sse=overflow=copy=interop=preserved\n",observations);
    return 0;
}
