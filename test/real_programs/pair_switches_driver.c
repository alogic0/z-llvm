#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef unsigned __int128 U;
extern uint64_t pair_switch_33(uint64_t *,U,uint64_t);
extern uint64_t pair_switch_63(uint64_t *,U,uint64_t);
extern uint64_t pair_switch_65(uint64_t *,U,uint64_t);
extern uint64_t pair_switch_97(uint64_t *,U,uint64_t);
extern uint64_t pair_switch_127(uint64_t *,U,uint64_t);
extern uint64_t pair_switch_128(uint64_t *,U,uint64_t);
int main(int argc,char **argv) {
    unsigned fault=argc>1 ? (unsigned)strtoul(argv[1],NULL,10) : 0;
    size_t observations=0;
    const unsigned widths[]={33,63,65,97,127,128};
    uint64_t (*functions[])(uint64_t *,U,uint64_t)={pair_switch_33,pair_switch_63,pair_switch_65,pair_switch_97,pair_switch_127,pair_switch_128};
#define CHECK(c) do {++observations; if(!(c)) {fprintf(stderr,"pair-switches fault=%u observation=%zu\n",fault,observations); return 1;}} while(0)
    for(unsigned seed=0;seed<64;seed++) for(unsigned i=0;i<6;i++) {
        unsigned width=widths[i];
        U mask=width==128 ? ~(U)0 : ((U)1<<width)-1;
        U sign=(U)1<<(width-1);
        U values[]={0,1,sign,sign+7,mask,2,sign-1,sign+1,mask-1,((U)1<<64)^UINT64_C(0xfedcba9876543210),(sign+7)|~mask,(mask>>1)^seed};
        for(unsigned j=0;j<12;j++) {
            U x=values[j]&mask;
            uint64_t tag=x==0 ? 10 : x==1 ? 11 : x==sign ? 12 : x==sign+7 ? 13 : 99;
            uint64_t salt=seed*UINT64_C(0x9e3779b97f4a7c15)+j;
            struct {uint64_t pre[2],value,post[2];} out;
            memset(&out,0xa5,sizeof(out));
            uint64_t got=functions[i](&out.value,values[j],salt);
            if(fault==1) got^=1;
            if(fault==2) out.pre[1]^=1;
            if(fault==3) out.post[0]^=1;
            CHECK(got==(tag^salt));
            CHECK(out.value==(tag^salt));
            CHECK(out.pre[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.pre[1]==out.pre[0]);
            CHECK(out.post[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.post[1]==out.post[0]);
        }
    }
    printf("pair-switches observations=%zu upper-bits=odd-widths=pair-inputs=duplicate-phi-edges=live-values=guards=preserved\n",observations);
    return 0;
}
