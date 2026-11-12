#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define STORE2 "movd %xmm0,%eax\nmovw %ax,(%rbx)\n"
#define STORE4 "movd %xmm0,(%rbx)\n"
#define STORE8 "movq %xmm0,(%rbx)\n"
/* These GNU assembly boundaries independently enforce raw LLVM vector ABI.
   C frontend vector typedefs may use different scalar ABI coercions. */
#define DEF(TAG,OP,STORE) \
extern void call_add_##TAG(uint8_t*,const uint64_t*,const uint64_t*,uint64_t); \
extern void call_eight_##TAG(uint8_t*,const uint64_t*,uint64_t); \
extern uint64_t small_relay_##TAG(uint8_t*,const uint64_t*,const uint64_t*,uint64_t); \
__asm__(".text\n.globl call_add_"#TAG"\n.type call_add_"#TAG",@function\ncall_add_"#TAG":\n" \
"push %rbx\nmov %rdi,%rbx\nmovq (%rsi),%xmm0\nmovq (%rdx),%xmm1\nmov %rcx,%rsi\ncall small_add_"#TAG"\n" STORE "pop %rbx\nret\n" \
".size call_add_"#TAG",.-call_add_"#TAG"\n.globl call_eight_"#TAG"\n.type call_eight_"#TAG",@function\ncall_eight_"#TAG":\n" \
"push %rbx\nmov %rdi,%rbx\nmovq 0(%rsi),%xmm0\nmovq 8(%rsi),%xmm1\nmovq 16(%rsi),%xmm2\nmovq 24(%rsi),%xmm3\n" \
"movq 32(%rsi),%xmm4\nmovq 40(%rsi),%xmm5\nmovq 48(%rsi),%xmm6\nmovq 56(%rsi),%xmm7\nmov %rdx,%rsi\ncall small_eight_"#TAG"\n" STORE "pop %rbx\nret\n" \
".size call_eight_"#TAG",.-call_eight_"#TAG"\n.globl small_peer_"#TAG"\n.type small_peer_"#TAG",@function\nsmall_peer_"#TAG":\n" \
OP" %xmm1,%xmm0\nmovq %rdi,%xmm2\npxor %xmm2,%xmm0\nret\n.size small_peer_"#TAG",.-small_peer_"#TAG"\n");
DEF(c_2_8,"paddb",STORE2) DEF(fast_2_8,"paddb",STORE2)
DEF(c_4_8,"paddb",STORE4) DEF(fast_4_8,"paddb",STORE4)
DEF(c_8_8,"paddb",STORE8) DEF(fast_8_8,"paddb",STORE8)
DEF(c_2_16,"paddw",STORE4) DEF(fast_2_16,"paddw",STORE4)
DEF(c_4_16,"paddw",STORE8) DEF(fast_4_16,"paddw",STORE8)
DEF(c_2_32,"paddd",STORE8) DEF(fast_2_32,"paddd",STORE8)
struct Result {uint64_t pre[2];uint8_t data[8];uint64_t live;uint64_t post[2];};
struct Case {unsigned lanes,bits;void(*add)(uint8_t*,const uint64_t*,const uint64_t*,uint64_t);void(*eight)(uint8_t*,const uint64_t*,uint64_t);uint64_t(*relay)(uint8_t*,const uint64_t*,const uint64_t*,uint64_t);};
#define ROW(TAG,N,B) {N,B,call_add_##TAG,call_eight_##TAG,small_relay_##TAG}
static uint64_t sum(const uint64_t *values,unsigned count,unsigned lanes,unsigned bits) {
    uint64_t result=0,mask=(UINT64_C(1)<<bits)-1;
    for(unsigned lane=0;lane<lanes;lane++){uint64_t value=0;for(unsigned i=0;i<count;i++)value+=(values[i]>>(lane*bits))&mask;result|=(value&mask)<<(lane*bits);}return result;
}
int main(int argc,char **argv) {
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0;
    const struct Case cases[]={ROW(c_2_8,2,8),ROW(fast_2_8,2,8),ROW(c_4_8,4,8),ROW(fast_4_8,4,8),ROW(c_8_8,8,8),ROW(fast_8_8,8,8),ROW(c_2_16,2,16),ROW(fast_2_16,2,16),ROW(c_4_16,4,16),ROW(fast_4_16,4,16),ROW(c_2_32,2,32),ROW(fast_2_32,2,32)};
#define CHECK(C) do {++observations;if(!(C)){fprintf(stderr,"small-vector-abi fault=%u observation=%zu case=%u seed=%u route=%u\n",fault,observations,ci,seed,route);return 1;}}while(0)
    for(unsigned ci=0;ci<12;ci++)for(unsigned seed=0;seed<16;seed++) {
        const struct Case *c=&cases[ci];unsigned bytes=c->lanes*c->bits/8;
        uint64_t values[8],before[8];for(unsigned i=0;i<8;i++)values[i]=seed==0?0:seed==1?UINT64_MAX:UINT64_C(0x9e3779b97f4a7c15)*(seed+i)+i*131;
        memcpy(before,values,sizeof values);uint64_t live=UINT64_C(0x123456789abcdef0)^seed;
        for(unsigned route=0;route<3;route++) {
            struct Result out;memset(&out,0xa5,sizeof out);uint64_t expected=sum(values,route==2?8:2,c->lanes,c->bits);
            if(route==0)c->add(out.data,&values[0],&values[1],live);
            if(route==1){uint64_t got=c->relay(out.data,&values[0],&values[1],live);CHECK(got==(live^123));expected^=live;}
            if(route==2)c->eight(out.data,values,live);
            if(fault==1)out.data[0]^=1;if(fault==2)out.pre[0]^=1;if(fault==3)out.post[1]^=1;
            for(unsigned i=0;i<8;i++)CHECK(out.data[i]==(i<bytes?(uint8_t)(expected>>(8*i)):0xa5));
            CHECK(out.live==live);CHECK(out.pre[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.pre[1]==out.pre[0]);CHECK(out.post[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.post[1]==out.post[0]);
        }
        {unsigned route=3;CHECK(memcmp(values,before,sizeof values)==0);}
    }
    printf("small-vector-abi observations=%zu c-fastcc=inbound-outbound=eight-xmm=mixed-gpr=exact-stores=guards=preserved\n",observations);return 0;
}
