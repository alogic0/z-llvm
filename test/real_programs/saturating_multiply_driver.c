#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#define DECL(B) extern uint64_t sat_mul_umul_##B(uint64_t*,uint64_t,uint64_t,uint64_t);extern uint64_t sat_mul_smul_##B(uint64_t*,uint64_t,uint64_t,uint64_t);
DECL(4) DECL(8) DECL(25) DECL(64)
int main(int argc,char **argv) {
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0;
    const unsigned widths[]={4,8,25,64};
    uint64_t (*functions[][2])(uint64_t*,uint64_t,uint64_t,uint64_t)={{sat_mul_umul_4,sat_mul_smul_4},{sat_mul_umul_8,sat_mul_smul_8},{sat_mul_umul_25,sat_mul_smul_25},{sat_mul_umul_64,sat_mul_smul_64}};
#define CHECK(C) do {observations++;if(!(C)){fprintf(stderr,"saturating-multiply fault=%u observation=%zu width=%u signed=%u pair=%u,%u\n",fault,observations,bits,sign,i,j);return 1;}}while(0)
    for(unsigned w=0;w<4;w++) for(unsigned sign=0;sign<2;sign++) {
        unsigned bits=widths[w];uint64_t signbit=UINT64_C(1)<<(bits-1),mask=(signbit-1)|signbit;
        uint64_t values[]={0,1,signbit-1,signbit,signbit+1,mask,UINT64_C(0x123456789abcdef0),UINT64_C(0xffffffffffffffff)};
        for(unsigned i=0;i<8;i++) for(unsigned j=0;j<8;j++) for(unsigned seed=0;seed<3;seed++) {
            uint64_t x=values[i]&mask,y=values[j]&mask,expected;
            if(sign) {
                __int128 modulus=(__int128)1<<bits;
                __int128 sx=(x&signbit)?(__int128)x-modulus:x,sy=(y&signbit)?(__int128)y-modulus:y;
                __int128 minimum=-((__int128)1<<(bits-1)),maximum=-minimum-1,product=sx*sy;
                expected=(uint64_t)(product<minimum?minimum:product>maximum?maximum:product)&mask;
            } else {
                unsigned __int128 product=(unsigned __int128)x*y;
                expected=product>mask?mask:(uint64_t)product;
            }
            struct {uint64_t pre,value,post;} out={UINT64_C(0xa5a5a5a5a5a5a5a5),0,UINT64_C(0x5a5a5a5a5a5a5a5a)};
            uint64_t live=UINT64_C(0x9e3779b97f4a7c15)*seed;
            uint64_t got=functions[w][sign](&out.value,values[i],values[j],live);
            if(fault==1)got^=1;if(fault==2)out.pre^=1;if(fault==3)out.post^=1;
            CHECK(got==(expected^values[i]^values[j]^live));CHECK(out.value==expected);
            CHECK(out.pre==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(out.post==UINT64_C(0x5a5a5a5a5a5a5a5a));
        }
    }
    printf("saturating-multiply observations=%zu signed-unsigned=full-products=live-values=guards=preserved\n",observations);return 0;
}
