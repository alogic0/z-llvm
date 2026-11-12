#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#define DECL(n) extern uint64_t limb_saturation_##n(uint8_t *,const uint8_t *,const uint8_t *,uint64_t,uint64_t)
DECL(140);DECL(200);DECL(256);DECL(495);
static unsigned bit(const uint8_t *p,unsigned n) {return (p[n/8]>>(n%8))&1;}
static void put(uint8_t *p,unsigned n) {p[n/8]|=(uint8_t)(1u<<(n%8));}
static void product(uint8_t *out,const uint8_t *x,const uint8_t *y,unsigned n) {
    memset(out,0,128);
    for(unsigned i=0;i<n;i++) {
        unsigned carry=0;
        for(unsigned j=0;i+j<n;j++) {unsigned sum=(unsigned)x[i]*y[j]+out[i+j]+carry;out[i+j]=(uint8_t)sum;carry=sum>>8;}
    }
}
static int less(const uint8_t *x,const uint8_t *y,unsigned bits,int signed_value) {
    for(unsigned i=bits;i--;) {
        unsigned a=bit(x,i),b=bit(y,i);
        if(signed_value && i==bits-1) {a^=1;b^=1;}
        if(a!=b) return a<b;
    }
    return 0;
}
static void limit(uint8_t *p,unsigned bits,int signed_value,unsigned negative) {
    memset(p,0,64);
    if(signed_value && negative) put(p,bits-1);
    else for(unsigned i=0;i<bits-(signed_value?1:0);i++) put(p,i);
}
static void clamp(uint8_t *out,const uint8_t *full,unsigned bits,int signed_value,unsigned negative) {
    unsigned overflow=0,sign=bit(full,bits-1);
    for(unsigned i=bits;i<2*bits;i++) overflow|=bit(full,i)!=(signed_value?sign:0);
    if(overflow) limit(out,bits,signed_value,negative);
    else {memset(out,0,64);for(unsigned i=0;i<bits;i++) if(bit(full,i)) put(out,i);}
}
static void special(uint8_t *p,unsigned bits,unsigned seed) {
    memset(p,0,128);
    if(seed==1)p[0]=1;
    if(seed==2)for(unsigned i=0;i<bits;i++)put(p,i);
    if(seed==3 || seed==5)put(p,bits-1);
    if(seed==4)for(unsigned i=0;i+1<bits;i++)put(p,i);
    if(seed==5)p[0]|=1;
    if(seed==6)memset(p,255,8);
    if(seed==7)put(p,bits/2);
}
int main(int argc,char **argv) {
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;
    if(fault>3)return 2;
    const unsigned widths[]={140,200,256,495};
    uint64_t(*functions[])(uint8_t *,const uint8_t *,const uint8_t *,uint64_t,uint64_t)={limb_saturation_140,limb_saturation_200,limb_saturation_256,limb_saturation_495};
    size_t page=(size_t)sysconf(_SC_PAGESIZE),observations=0;
    uint8_t *map=mmap(0,page*4,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(map==MAP_FAILED || mprotect(map+page,page,PROT_NONE) || mprotect(map+3*page,page,PROT_NONE))return 2;
    uint64_t random=UINT64_C(0x97ac5d3e20b1846f);
    for(unsigned wi=0;wi<4;wi++)for(unsigned seed=0;seed<128;seed++) {
        unsigned bits=widths[wi],bytes=(bits+7)/8,fullbytes=(2*bits+7)/8;
        uint8_t x[128]={0},y[128]={0},ex[128],ey[128],p[128],expected[8][64];
        if(seed<64){special(x,bits,seed/8);special(y,bits,seed%8);}
        else for(unsigned i=0;i<bytes;i++){random^=random<<13;random^=random>>7;random^=random<<17;x[i]=(uint8_t)random;y[i]=(uint8_t)(random>>32);}
        if(seed>=96){memset(y,0,sizeof y);y[0]=(uint8_t)(1+seed%7);}
        if(bits%8){x[bytes-1]&=(1u<<(bits%8))-1;y[bytes-1]&=(1u<<(bits%8))-1;}
        memset(expected,0,sizeof expected);
        for(unsigned sign=0;sign<2;sign++) {
            int a_less=less(x,y,bits,sign);
            memcpy(expected[2*sign],a_less?x:y,bytes);memcpy(expected[2*sign+1],a_less?y:x,bytes);
        }
        product(p,x,y,fullbytes);clamp(expected[4],p,bits,0,0);
        memcpy(ex,x,128);memcpy(ey,y,128);
        for(unsigned i=bits;i<2*bits;i++){if(bit(x,bits-1))put(ex,i);if(bit(y,bits-1))put(ey,i);}
        product(p,ex,ey,fullbytes);clamp(expected[5],p,bits,1,bit(x,bits-1)^bit(y,bits-1));
        unsigned edges[]={0,1,31,63,64,65,bits-1};
        unsigned amount=seed<7?edges[seed]:(seed*67)%bits;
        for(unsigned sign=0;sign<2;sign++) {
            memset(p,0,sizeof p);
            for(unsigned i=0;i<2*bits-amount;i++)if(i<bits?bit(x,i):(sign&&bit(x,bits-1)))put(p,i+amount);
            clamp(expected[6+sign],p,bits,sign,bit(x,bits-1));
        }
        uint8_t *xp=map+page-bytes,*yp=map+3*page-bytes;
        memcpy(xp,x,bytes);memcpy(yp,y,bytes);
        struct{uint8_t before[9],values[8][64],after[9];}out;
        memset(&out,0xa5,sizeof out);
        uint64_t salt=seed*UINT64_C(0x9e3779b97f4a7c15)+wi;
        uint64_t result=functions[wi](&out.values[0][0],xp,yp,amount,salt);
        if(fault==1)out.values[0][0]^=1;
        if(fault==2)out.values[4][0]^=1;
        if(fault==3)out.after[0]^=1;
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"limb-saturation bits=%u seed=%u observation=%zu fault=%u\n",bits,seed,observations,fault);return 1;}}while(0)
        CHECK(result==(salt^90));
        for(unsigned op=0;op<8;op++)for(unsigned i=0;i<64;i++) {
            unsigned mask=i+1==bytes && bits%8?(1u<<(bits%8))-1:255;
            CHECK((out.values[op][i]&mask)==((i<bytes?expected[op][i]:0xa5)&mask));
        }
        unsigned prefix=1,suffix=1;for(unsigned i=0;i<9;i++){prefix&=out.before[i]==0xa5;suffix&=out.after[i]==0xa5;}
        CHECK(prefix);CHECK(suffix);CHECK(memcmp(x,xp,bytes)==0);CHECK(memcmp(y,yp,bytes)==0);
    }
    if(observations!=264704)return 2;
    printf("limb-saturation observations=%zu signed-unsigned-limits=minmax=scale-zero-products=defined-shifts=guard-pages=preserved\n",observations);
    return munmap(map,page*4)!=0;
}
