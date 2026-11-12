#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern uint64_t limb_intrinsics_140(uint8_t *,const uint8_t *,const uint8_t *,const uint8_t *,uint64_t);
extern uint64_t limb_intrinsics_200(uint8_t *,const uint8_t *,const uint8_t *,const uint8_t *,uint64_t);
extern uint64_t limb_intrinsics_256(uint8_t *,const uint8_t *,const uint8_t *,const uint8_t *,uint64_t);
extern uint64_t limb_intrinsics_495(uint8_t *,const uint8_t *,const uint8_t *,const uint8_t *,uint64_t);
static unsigned bit(const uint8_t *p,unsigned n) {return (p[n/8]>>(n%8))&1;}
static void put(uint8_t *p,unsigned n,unsigned v) {if(v) p[n/8]|=(uint8_t)(1u<<(n%8));}
static void limit(uint8_t *out,unsigned bits,unsigned negative) {
    memset(out,0,(bits+7)/8);
    for(unsigned i=0;i<bits;i++) put(out,i,i+1==bits ? negative : !negative);
}
static void oracle(uint8_t out[12][64],const uint8_t *x,const uint8_t *y,const uint8_t *n,unsigned bits) {
    unsigned bytes=(bits+7)/8,sx=bit(x,bits-1),sy=bit(y,bits-1);
    memset(out,0xa5,12*64);
    for(unsigned op=0;op<12;op++) {
        if(op==5&&bits%16) continue;
        memset(out[op],0,bytes);
        if(op==0) {
            unsigned carry=sx;
            for(unsigned i=0;i<bits;i++) {unsigned v=(bit(x,i)^sx)+carry;put(out[op],i,v&1);carry=v>>1;}
        } else if(op<=3) {
            unsigned count=0;
            if(op==1) for(unsigned i=0;i<bits;i++) count+=bit(x,i);
            if(op==2) for(unsigned i=bits;i>0&&!bit(x,i-1);i--) count++;
            if(op==3) for(unsigned i=0;i<bits&&!bit(x,i);i++) count++;
            out[op][0]=(uint8_t)count;out[op][1]=(uint8_t)(count>>8);
        } else if(op==4) {
            for(unsigned i=0;i<bits;i++) put(out[op],bits-1-i,bit(x,i));
        } else if(op==5) {
            for(unsigned i=0;i<bytes;i++) out[op][bytes-1-i]=x[i];
        } else if(op<=9) {
            unsigned subtract=op==7||op==9,carry=subtract;
            for(unsigned i=0;i<bits;i++) {unsigned v=bit(x,i)+(bit(y,i)^subtract)+carry;put(out[op],i,v&1);carry=v>>1;}
            unsigned sr=bit(out[op],bits-1);
            if(op==6&&carry) {memset(out[op],0,bytes);for(unsigned i=0;i<bits;i++) put(out[op],i,1);}
            if(op==7&&!carry) memset(out[op],0,bytes);
            if((op==8&&sx==sy&&sr!=sx)||(op==9&&sx!=sy&&sr!=sx)) limit(out[op],bits,sx);
        } else {
            unsigned shift=0;
            for(unsigned i=bits;i>0;i--) shift=(shift*2+bit(n,i-1))%bits;
            for(unsigned i=0;i<bits;i++) {
                unsigned v=op==10 ? (i>=shift ? bit(x,i-shift) : bit(y,bits+i-shift)) : (i+shift<bits ? bit(y,i+shift) : bit(x,i+shift-bits));
                put(out[op],i,v);
            }
        }
    }
}
int main(int argc,char **argv) {
    unsigned fault=argc>1 ? (unsigned)strtoul(argv[1],NULL,10) : 0;
    size_t observations=0;
    unsigned widths[]={140,200,256,495};
    uint64_t (*functions[])(uint8_t *,const uint8_t *,const uint8_t *,const uint8_t *,uint64_t)={limb_intrinsics_140,limb_intrinsics_200,limb_intrinsics_256,limb_intrinsics_495};
#define CHECK(c) do {++observations; if(!(c)) {fprintf(stderr,"limb-intrinsics fault=%u observation=%zu width=%u seed=%u\n",fault,observations,widths[w],seed);return 1;}} while(0)
    for(unsigned w=0;w<4;w++) for(unsigned seed=0;seed<16;seed++) {
        unsigned bits=widths[w],bytes=(bits+7)/8;
        uint8_t x[64]={0},y[64]={0},n[64]={0},expected[12][64];
        for(unsigned i=0;i<bytes;i++) {x[i]=(uint8_t)(seed*73+i*131);y[i]=(uint8_t)(seed*19+i*37+255);n[i]=(uint8_t)(seed*17+i*97);}
        if(seed<4) {memset(x,0,64);if(seed==1) x[0]=1;if(seed==2) memset(x,255,bytes);if(seed==3) put(x,bits-1,1);}
        if(seed==4) {memset(x,255,bytes);x[(bits-1)/8]&=(uint8_t)((1u<<((bits-1)%8))-1);}
        if(seed==5) {memset(n,0,64);}
        if(seed==6) {memset(n,0,64);n[0]=(uint8_t)bits;n[1]=(uint8_t)(bits>>8);}
        if(bits%8) {x[bytes-1]&=(uint8_t)((1u<<(bits%8))-1);y[bytes-1]&=(uint8_t)((1u<<(bits%8))-1);n[bytes-1]&=(uint8_t)((1u<<(bits%8))-1);}
        oracle(expected,x,y,n,bits);
        uint8_t original[3][64];memcpy(original[0],x,64);memcpy(original[1],y,64);memcpy(original[2],n,64);
        struct {uint64_t pre[2];uint8_t data[12][64];uint64_t post[2];} out;
        memset(&out,0xa5,sizeof(out));
        uint64_t salt=seed*UINT64_C(0x9e3779b97f4a7c15)+w;
        uint64_t got=functions[w](&out.data[0][0],x,y,n,salt);
        if(fault==1) got^=1;if(fault==2) out.pre[1]^=1;if(fault==3) out.post[0]^=1;
        CHECK(got==(salt^90));
        for(unsigned op=0;op<12;op++) for(unsigned i=0;i<64;i++) CHECK(out.data[op][i]==expected[op][i]);
        CHECK(out.pre[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.pre[1]==out.pre[0]);
        CHECK(out.post[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.post[1]==out.post[0]);
        CHECK(memcmp(original[0],x,64)==0);CHECK(memcmp(original[1],y,64)==0);CHECK(memcmp(original[2],n,64)==0);
    }
    printf("limb-intrinsics observations=%zu counts=permutations=saturation=full-width-funnels=live-values=guards=preserved\n",observations);
    return 0;
}
