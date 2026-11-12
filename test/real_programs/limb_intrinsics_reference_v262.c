#include <stdint.h>
#include <string.h>

// Byte-stream windows implement the two funnel operations without an illegal
// arbitrary-width remainder in LLVM's target lowering. The driver independently
// checks individual result bits; the candidate uses scalar word operations.
__attribute__((noinline)) static void funnel(uint8_t *out,const uint8_t *x,const uint8_t *y,const uint8_t *amount,unsigned bits,unsigned left) {
    const unsigned bytes=(bits+7)/8;unsigned shift=0;
    for(unsigned i=bytes;i>0;i--) {
        unsigned byte=amount[i-1];if(i==bytes&&bits%8) byte&=(1u<<(bits%8))-1;
        shift=(shift*256+byte)%bits;
    }
    uint8_t joined[129]={0};
    for(unsigned i=0;i<bits;i++) {
        joined[i/8]|=((y[i/8]>>(i%8))&1u)<<(i%8);
        joined[(bits+i)/8]|=((x[i/8]>>(i%8))&1u)<<((bits+i)%8);
    }
    unsigned base=left ? bits-shift:shift;
    for(unsigned i=0;i<bytes;i++) {
        unsigned at=base+i*8,offset=at%8;
        out[i]=(uint8_t)((joined[at/8]>>offset)|(joined[at/8+1]<<(8-offset)));
    }
    if(bits%8) out[bytes-1]&=(1u<<(bits%8))-1;
}

#define DEFINE(B) \
uint64_t limb_intrinsics_##B(uint8_t *out,const uint8_t *xp,const uint8_t *yp,const uint8_t *np,uint64_t salt) { \
    typedef unsigned _BitInt(B) U;typedef _BitInt(B) S; \
    U x=0,y=0;const unsigned bytes=(B+7)/8; \
    for(unsigned i=0;i<bytes;i++){x|=(U)xp[i]<<(i*8);y|=(U)yp[i]<<(i*8);} \
    const U sign=(U)1<<(B-1),maximum=sign-1; \
    U results[10];S signed_result; \
    results[0]=(S)x<0 ? (U)(0-x):x; \
    results[1]=__builtin_popcountg(x);results[2]=__builtin_clzg(x,B);results[3]=__builtin_ctzg(x,B); \
    results[4]=0;for(unsigned i=0;i<B;i++) results[4]=(results[4]<<1)|((x>>i)&1); \
    results[5]=0;if(B%16==0) for(unsigned i=0;i<bytes;i++) results[5]|=(U)(uint8_t)(x>>(i*8))<<((bytes-1-i)*8); \
    U sum=x+y;results[6]=sum<x ? ~(U)0:sum;results[7]=x<y ? 0:x-y; \
    results[8]=__builtin_add_overflow((S)x,(S)y,&signed_result) ? ((S)x<0 ? sign:maximum):(U)signed_result; \
    results[9]=__builtin_sub_overflow((S)x,(S)y,&signed_result) ? ((S)x<0 ? sign:maximum):(U)signed_result; \
    for(unsigned op=0;op<10;op++){if(op==5&&B%16) continue;for(unsigned i=0;i<bytes;i++) out[op*64+i]=(uint8_t)(results[op]>>(i*8));} \
    funnel(out+10*64,xp,yp,np,B,1);funnel(out+11*64,xp,yp,np,B,0);return salt^90; \
}
DEFINE(140)
DEFINE(200)
DEFINE(256)
DEFINE(495)
