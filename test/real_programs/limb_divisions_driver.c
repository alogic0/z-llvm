#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern uint64_t limb_divisions_140(uint8_t*,const uint8_t*,const uint8_t*,uint64_t);
extern uint64_t limb_divisions_200(uint8_t*,const uint8_t*,const uint8_t*,uint64_t);
extern uint64_t limb_divisions_256(uint8_t*,const uint8_t*,const uint8_t*,uint64_t);
extern uint64_t limb_divisions_495(uint8_t*,const uint8_t*,const uint8_t*,uint64_t);
static unsigned bit(const uint8_t *p,unsigned n){return(p[n/8]>>(n%8))&1;}
static void canonical(uint8_t *p,unsigned bits){if(bits%8)p[bits/8]&=(1u<<(bits%8))-1;}
static void negate(uint8_t *p,unsigned bits){unsigned carry=1;for(unsigned i=0;i<(bits+7)/8;i++){unsigned t=(unsigned)(uint8_t)~p[i]+carry;p[i]=(uint8_t)t;carry=t>>8;}canonical(p,bits);}
static void sample(uint8_t *p,unsigned bits,unsigned index) {
    memset(p,0,64);unsigned bytes=(bits+7)/8;
    if(index==1)p[0]=1;if(index==2)memset(p,255,bytes);
    if(index==3)p[(bits-1)/8]|=1u<<((bits-1)%8);
    if(index==4){memset(p,255,bytes);canonical(p,bits);p[(bits-1)/8]&=~(1u<<((bits-1)%8));}
    if(index==5){p[(bits-1)/8]|=1u<<((bits-1)%8);p[0]=1;}
    if(index==6){p[8]=1;p[0]=5;}
    if(index==7)for(unsigned i=0;i<bytes;i++)p[i]=(uint8_t)(i*131+0x43);
    canonical(p,bits);
}
static int zero(const uint8_t *p,unsigned bytes){unsigned x=0;for(unsigned i=0;i<bytes;i++)x|=p[i];return x==0;}
/* Independent bit-at-a-time division. The generated compiler calls the pinned
   runtime's Knuth division implementation through its real C ABI. */
static void divmod(uint8_t *q,uint8_t *r,const uint8_t *x,const uint8_t *y,unsigned bits) {
    unsigned bytes=(bits+7)/8;uint8_t rem[65]={0};memset(q,0,64);memset(r,0,64);
    for(unsigned step=bits;step>0;step--) {
        unsigned carry=bit(x,step-1);for(unsigned i=0;i<=bytes;i++){unsigned t=(unsigned)rem[i]*2+carry;rem[i]=(uint8_t)t;carry=t>>8;}
        int order=rem[bytes]?1:0;
        if(!order)for(unsigned i=bytes;i>0;i--)if(rem[i-1]!=y[i-1]){order=rem[i-1]>y[i-1]?1:-1;break;}
        if(order>=0) {
            unsigned borrow=0;for(unsigned i=0;i<=bytes;i++){unsigned a=rem[i],b=(i<bytes?y[i]:0)+borrow;rem[i]=(uint8_t)(a-b);borrow=a<b;}
            q[(step-1)/8]|=1u<<((step-1)%8);
        }
    }
    memcpy(r,rem,bytes);
}
int main(int argc,char **argv) {
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0;
    const unsigned widths[]={140,200,256,495};uint64_t(*functions[])(uint8_t*,const uint8_t*,const uint8_t*,uint64_t)={limb_divisions_140,limb_divisions_200,limb_divisions_256,limb_divisions_495};
#define CHECK(C) do{observations++;if(!(C)){fprintf(stderr,"limb-divisions fault=%u observation=%zu width=%u seed=%u\n",fault,observations,bits,seed);return 1;}}while(0)
    for(unsigned w=0;w<4;w++)for(unsigned seed=0;seed<96;seed++) {
        unsigned bits=widths[w],bytes=(bits+7)/8;uint8_t x[64],y[64];
        if(seed<64){sample(x,bits,seed%8);sample(y,bits,seed/8);}else{memset(x,0,64);memset(y,0,64);for(unsigned i=0;i<bytes;i++){x[i]=(uint8_t)(seed*73+i*131);y[i]=(uint8_t)(seed*19+i*37+255);}canonical(x,bits);canonical(y,bits);}
        if(zero(y,bytes))y[0]=1;
        uint8_t minimum[64],minus_one[64];sample(minimum,bits,3);sample(minus_one,bits,2);
        if(memcmp(x,minimum,bytes)==0&&memcmp(y,minus_one,bytes)==0){memset(y,0,64);y[0]=1;}
        uint8_t before_x[64],before_y[64];memcpy(before_x,x,64);memcpy(before_y,y,64);
        uint8_t results[4][64],ax[64],ay[64];divmod(results[0],results[1],x,y,bits);
        memcpy(ax,x,64);memcpy(ay,y,64);unsigned sx=bit(x,bits-1),sy=bit(y,bits-1);if(sx)negate(ax,bits);if(sy)negate(ay,bits);
        divmod(results[2],results[3],ax,ay,bits);if(sx!=sy)negate(results[2],bits);if(sx)negate(results[3],bits);
        uint8_t expected[4][64];memset(expected,0xa5,sizeof expected);for(unsigned op=0;op<4;op++)memcpy(expected[op],results[op],bytes);
        struct {uint64_t pre[2];uint8_t data[4][64];uint64_t post[2];}out;memset(&out,0xa5,sizeof out);
        uint64_t a,b;memcpy(&a,x,8);memcpy(&b,y,8);uint64_t live=UINT64_C(0x9e3779b97f4a7c15)*seed,got=functions[w](&out.data[0][0],x,y,live);
        if(fault==1)got^=1;if(fault==2)out.pre[0]^=1;if(fault==3)out.post[1]^=1;
        CHECK(got==(a^b^live));
        for(unsigned op=0;op<4;op++)for(unsigned i=0;i<64;i++){unsigned mask=i+1==bytes&&bits%8?(1u<<(bits%8))-1:255;CHECK((out.data[op][i]&mask)==(expected[op][i]&mask));}
        CHECK(out.pre[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.pre[1]==out.pre[0]);CHECK(out.post[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.post[1]==out.post[0]);CHECK(memcmp(x,before_x,64)==0);CHECK(memcmp(y,before_y,64)==0);
    }
    printf("limb-divisions observations=%zu unsigned-signed=quotient-remainder=private-inputs=live-values=guards=preserved\n",observations);return 0;
}
