#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern uint64_t limb_overflow_140(uint8_t *,uint8_t *,const uint8_t *,const uint8_t *,uint64_t);
extern uint64_t limb_overflow_200(uint8_t *,uint8_t *,const uint8_t *,const uint8_t *,uint64_t);
extern uint64_t limb_overflow_256(uint8_t *,uint8_t *,const uint8_t *,const uint8_t *,uint64_t);
extern uint64_t limb_overflow_495(uint8_t *,uint8_t *,const uint8_t *,const uint8_t *,uint64_t);
static unsigned bit(const uint8_t *p,unsigned n){return (p[n/8]>>(n%8))&1;}
static void put(uint8_t *p,unsigned n,unsigned value){if(value) p[n/8]|=1u<<(n%8);}
static void sample(uint8_t *out,unsigned bits,unsigned index) {
    memset(out,0,64);
    if(index==1) out[0]=1;
    if(index==2) {memset(out,255,(bits+7)/8);}
    if(index==3) put(out,bits-1,1);
    if(index==4) for(unsigned i=0;i+1<bits;i++) put(out,i,1);
    if(index==5) {put(out,bits-1,1);out[0]|=1;}
    if(bits%8) out[bits/8]|=(uint8_t)(0xa5&~((1u<<(bits%8))-1));
}
int main(int argc,char **argv) {
    unsigned fault=argc>1 ? (unsigned)strtoul(argv[1],NULL,10):0;size_t observations=0;
    const unsigned widths[]={140,200,256,495};
    uint64_t (*functions[])(uint8_t *,uint8_t *,const uint8_t *,const uint8_t *,uint64_t)={limb_overflow_140,limb_overflow_200,limb_overflow_256,limb_overflow_495};
#define CHECK(c) do {++observations;if(!(c)){fprintf(stderr,"limb-overflow fault=%u observation=%zu width=%u seed=%u\n",fault,observations,bits,seed);return 1;}} while(0)
    for(unsigned w=0;w<4;w++) for(unsigned seed=0;seed<44;seed++) {
        const unsigned bits=widths[w],bytes=(bits+7)/8;
        uint8_t x[64]={0},y[64]={0};
        if(seed<36){sample(x,bits,seed/6);sample(y,bits,seed%6);}
        else for(unsigned i=0;i<bytes;i++){x[i]=(uint8_t)(seed*73+i*131);y[i]=(uint8_t)(seed*19+i*37+255);}
        if(bits%8){x[bits/8]&=(1u<<(bits%8))-1;y[bits/8]&=(1u<<(bits%8))-1;} uint8_t before_x[64],before_y[64];memcpy(before_x,x,64);memcpy(before_y,y,64);
        uint8_t expected[4][64],expected_flags[4];memset(expected,0xa5,sizeof expected);
        for(unsigned op=0;op<4;op++) {
            memset(expected[op],0,bytes);unsigned subtract=op&1,carry=subtract;
            for(unsigned i=0;i<bits;i++){unsigned sum=bit(x,i)+(bit(y,i)^subtract)+carry;put(expected[op],i,sum&1);carry=sum>>1;}
            unsigned sx=bit(x,bits-1),sy=bit(y,bits-1),sr=bit(expected[op],bits-1);
            expected_flags[op]=op==0 ? carry:op==1 ? !carry:op==2 ? sx==sy&&sr!=sx:sx!=sy&&sr!=sx;
        }
        struct {uint64_t pre[2];uint8_t data[4][64];uint64_t post[2];} out;
        struct {uint8_t pre[2],data[4],post[2];} flags;
        memset(&out,0xa5,sizeof out);memset(&flags,0xa5,sizeof flags);
        uint64_t salt=seed*UINT64_C(0x9e3779b97f4a7c15)+w;
        uint64_t got=functions[w](&out.data[0][0],flags.data,x,y,salt);
        if(fault==1) got^=1;if(fault==2) out.pre[0]^=1;if(fault==3) out.post[1]^=1;
        CHECK(got==(salt^90));
        for(unsigned op=0;op<4;op++) {
            for(unsigned i=0;i<64;i++){unsigned mask=(i+1==bytes&&bits%8) ? (1u<<(bits%8))-1:255;CHECK((out.data[op][i]&mask)==(expected[op][i]&mask));}
            CHECK(flags.data[op]==expected_flags[op]);
        }
        CHECK(out.pre[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.pre[1]==out.pre[0]);CHECK(out.post[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.post[1]==out.post[0]);
        CHECK(flags.pre[0]==0xa5&&flags.pre[1]==0xa5);CHECK(flags.post[0]==0xa5&&flags.post[1]==0xa5);
        CHECK(memcmp(x,before_x,64)==0);CHECK(memcmp(y,before_y,64)==0);
    }
    printf("limb-overflow observations=%zu exact-width-results=signed-unsigned-flags=canonical-inputs=live-values=guards=preserved\n",observations);return 0;
}
