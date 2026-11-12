#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern uint64_t vector_intrinsics_16(uint8_t*,const uint8_t*,const uint8_t*,uint64_t);
extern uint64_t vector_intrinsics_32(uint8_t*,const uint8_t*,const uint8_t*,uint64_t);
extern uint64_t vector_intrinsics_64(uint8_t*,const uint8_t*,const uint8_t*,uint64_t);
static __int128 signed_value(uint64_t x,unsigned bits){return x&(UINT64_C(1)<<(bits-1))?(__int128)x-((__int128)1<<bits):x;}
static uint64_t clamp_signed(__int128 x,unsigned bits,uint64_t mask){__int128 minimum=-((__int128)1<<(bits-1)),maximum=-minimum-1;return(uint64_t)(x<minimum?minimum:x>maximum?maximum:x)&mask;}
static uint64_t oracle(unsigned op,unsigned bits,uint64_t x,uint64_t y) {
    uint64_t mask=bits==64?UINT64_MAX:(UINT64_C(1)<<bits)-1,value=0;unsigned amount=(unsigned)(y&(bits-1));
    __int128 sx=signed_value(x,bits),sy=signed_value(y,bits);
    switch(op) {
    case 0:return(uint64_t)(sx<0?-sx:sx)&mask;
    case 1:for(unsigned i=0;i<bits;i++)value+=(x>>i)&1;return value;
    case 2:for(unsigned i=bits;i>0&&!((x>>(i-1))&1);i--)value++;return value;
    case 3:for(unsigned i=0;i<bits&&!((x>>i)&1);i++)value++;return value;
    case 4:for(unsigned i=0;i<bits;i++)value|=((x>>i)&1)<<(bits-1-i);return value;
    case 5:for(unsigned i=0;i<bits/8;i++)value=(value<<8)|((x>>(8*i))&255);return value;
    case 6:{unsigned __int128 r=(unsigned __int128)x+y;return r>mask?mask:(uint64_t)r;}
    case 7:return x>=y?x-y:0;
    case 8:return clamp_signed(sx+sy,bits,mask);
    case 9:return clamp_signed(sx-sy,bits,mask);
    case 10:return amount?(uint64_t)(((unsigned __int128)x<<amount)|(y>>(bits-amount)))&mask:x;
    case 11:return amount?(uint64_t)(((unsigned __int128)x<<(bits-amount))|(y>>amount))&mask:y;
    case 12:return x<y?x:y;
    case 13:return x>y?x:y;
    case 14:return sx<sy?x:y;
    case 15:return sx>sy?x:y;
    case 16:{unsigned __int128 r=(unsigned __int128)x<<amount;return r>mask?mask:(uint64_t)r;}
    case 17:return clamp_signed(sx*((__int128)1<<amount),bits,mask);
    case 18:{unsigned __int128 r=(unsigned __int128)x*y;return r>mask?mask:(uint64_t)r;}
    default:return clamp_signed(sx*sy,bits,mask);
    }
}
int main(int argc,char **argv) {
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0;
    unsigned widths[]={16,32,64};uint64_t(*functions[])(uint8_t*,const uint8_t*,const uint8_t*,uint64_t)={vector_intrinsics_16,vector_intrinsics_32,vector_intrinsics_64};
#define CHECK(C) do{observations++;if(!(C)){fprintf(stderr,"vector-intrinsics fault=%u observation=%zu width=%u seed=%u\n",fault,observations,bits,seed);return 1;}}while(0)
    for(unsigned w=0;w<3;w++)for(unsigned seed=0;seed<64;seed++) {
        unsigned bits=widths[w],bytes=bits/8,lanes=16/bytes;uint64_t mask=bits==64?UINT64_MAX:(UINT64_C(1)<<bits)-1,sign=UINT64_C(1)<<(bits-1);
        uint64_t samples[]={0,1,sign-1,sign,sign+1,mask,UINT64_C(0x123456789abcdef0)&mask,UINT64_C(0xfedcba9876543210)&mask};
        uint8_t x[16],y[16],before_x[16],before_y[16],expected[20][16];
        for(unsigned lane=0;lane<lanes;lane++) {
            uint64_t a=seed<32?samples[(seed+lane)%8]:UINT64_C(0x9e3779b97f4a7c15)*(seed+lane)&mask;
            uint64_t b=seed<32?samples[(seed/8+lane)%8]:UINT64_C(0xfedcba9876543211)*(seed+3*lane)&mask;
            memcpy(x+lane*bytes,&a,bytes);memcpy(y+lane*bytes,&b,bytes);
            for(unsigned op=0;op<20;op++){uint64_t result=oracle(op,bits,a,b);memcpy(expected[op]+lane*bytes,&result,bytes);}
        }
        memcpy(before_x,x,16);memcpy(before_y,y,16);
        struct{uint64_t pre[2];uint8_t data[20][16];uint64_t post[2];}out;memset(&out,0xa5,sizeof out);
        uint64_t live=UINT64_C(0x9e3779b97f4a7c15)*seed,got=functions[w](&out.data[0][0],x,y,live);
        if(fault==1)got^=1;if(fault==2)out.pre[0]^=1;if(fault==3)out.post[1]^=1;
        CHECK(got==(live^19));for(unsigned op=0;op<20;op++)for(unsigned i=0;i<16;i++)CHECK(out.data[op][i]==expected[op][i]);
        CHECK(out.pre[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.pre[1]==out.pre[0]);CHECK(out.post[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.post[1]==out.post[0]);CHECK(memcmp(x,before_x,16)==0);CHECK(memcmp(y,before_y,16)==0);
    }
    printf("vector-intrinsics observations=%zu lane-flags=permutations=saturation=funnels=extrema=live-values=guards=preserved\n",observations);return 0;
}
