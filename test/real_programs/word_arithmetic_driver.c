#include <stdint.h>
#include <stdio.h>
typedef uint64_t (*probe)(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_udiv32_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_udiv32_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_udiv32_3(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_udiv32_24(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_udiv32_100(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_udiv32_2147483648(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_udiv32_4294967295(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_udiv32_left(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_urem32_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_urem32_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_urem32_3(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_urem32_24(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_urem32_100(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_urem32_2147483648(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_urem32_4294967295(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_urem32_left(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_udiv64_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_udiv64_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_udiv64_3(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_udiv64_24(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_udiv64_100(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_udiv64_9223372036854775808(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_udiv64_18446744073709551615(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_udiv64_left(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_urem64_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_urem64_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_urem64_3(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_urem64_24(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_urem64_100(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_urem64_9223372036854775808(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_urem64_18446744073709551615(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_urem64_left(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_umul_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_umul_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_umul_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_umul_fixed_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_umul_fixed_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_smul_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_smul_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_smul_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_smul_fixed_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_smul_fixed_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_sadd_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_sadd_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_sadd_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_sadd_fixed_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_sadd_fixed_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_ssub_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_ssub_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_ssub_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_ssub_fixed_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_ssub_fixed_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_umax32_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_umax32_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_umax32_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_smin32_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_smin32_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_smin32_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_smax32_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_smax32_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_smax32_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_umax64_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_umax64_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_umax64_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_smin64_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_smin64_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_smin64_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_smax64_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_smax64_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_smax64_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_swap16_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_swap16_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_swap32_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_swap32_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_swap64_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_swap64_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t word_zero_extend(uint64_t,uint64_t,uint64_t *,uint64_t);
struct row {probe run;unsigned kind,bits,op,side;uint64_t constant;unsigned variant;};
static const struct row rows[]={
{word_udiv32_1,0,32,0,0,UINT64_C(1),0},
{word_udiv32_2,0,32,0,0,UINT64_C(2),0},
{word_udiv32_3,0,32,0,0,UINT64_C(3),0},
{word_udiv32_24,0,32,0,0,UINT64_C(24),0},
{word_udiv32_100,0,32,0,0,UINT64_C(100),0},
{word_udiv32_2147483648,0,32,0,0,UINT64_C(2147483648),0},
{word_udiv32_4294967295,0,32,0,0,UINT64_C(4294967295),0},
{word_udiv32_left,0,32,0,1,UINT64_C(100),0},
{word_urem32_1,0,32,1,0,UINT64_C(1),0},
{word_urem32_2,0,32,1,0,UINT64_C(2),0},
{word_urem32_3,0,32,1,0,UINT64_C(3),0},
{word_urem32_24,0,32,1,0,UINT64_C(24),0},
{word_urem32_100,0,32,1,0,UINT64_C(100),0},
{word_urem32_2147483648,0,32,1,0,UINT64_C(2147483648),0},
{word_urem32_4294967295,0,32,1,0,UINT64_C(4294967295),0},
{word_urem32_left,0,32,1,1,UINT64_C(100),0},
{word_udiv64_1,0,64,0,0,UINT64_C(1),0},
{word_udiv64_2,0,64,0,0,UINT64_C(2),0},
{word_udiv64_3,0,64,0,0,UINT64_C(3),0},
{word_udiv64_24,0,64,0,0,UINT64_C(24),0},
{word_udiv64_100,0,64,0,0,UINT64_C(100),0},
{word_udiv64_9223372036854775808,0,64,0,0,UINT64_C(9223372036854775808),0},
{word_udiv64_18446744073709551615,0,64,0,0,UINT64_C(18446744073709551615),0},
{word_udiv64_left,0,64,0,1,UINT64_C(100),0},
{word_urem64_1,0,64,1,0,UINT64_C(1),0},
{word_urem64_2,0,64,1,0,UINT64_C(2),0},
{word_urem64_3,0,64,1,0,UINT64_C(3),0},
{word_urem64_24,0,64,1,0,UINT64_C(24),0},
{word_urem64_100,0,64,1,0,UINT64_C(100),0},
{word_urem64_9223372036854775808,0,64,1,0,UINT64_C(9223372036854775808),0},
{word_urem64_18446744073709551615,0,64,1,0,UINT64_C(18446744073709551615),0},
{word_urem64_left,0,64,1,1,UINT64_C(100),0},
{word_umul_0,1,64,0,0,UINT64_C(0),0},
{word_umul_1,1,64,0,1,UINT64_C(0),0},
{word_umul_2,1,64,0,2,UINT64_C(0),0},
{word_umul_fixed_1,1,64,0,0,UINT64_C(0),1},
{word_umul_fixed_2,1,64,0,0,UINT64_C(0),2},
{word_smul_0,1,64,1,0,UINT64_C(0),0},
{word_smul_1,1,64,1,1,UINT64_C(0),0},
{word_smul_2,1,64,1,2,UINT64_C(0),0},
{word_smul_fixed_1,1,64,1,0,UINT64_C(0),1},
{word_smul_fixed_2,1,64,1,0,UINT64_C(0),2},
{word_sadd_0,1,64,2,0,UINT64_C(0),0},
{word_sadd_1,1,64,2,1,UINT64_C(0),0},
{word_sadd_2,1,64,2,2,UINT64_C(0),0},
{word_sadd_fixed_1,1,64,2,0,UINT64_C(0),1},
{word_sadd_fixed_2,1,64,2,0,UINT64_C(0),2},
{word_ssub_0,1,64,3,0,UINT64_C(0),0},
{word_ssub_1,1,64,3,1,UINT64_C(0),0},
{word_ssub_2,1,64,3,2,UINT64_C(0),0},
{word_ssub_fixed_1,1,64,3,0,UINT64_C(0),1},
{word_ssub_fixed_2,1,64,3,0,UINT64_C(0),2},
{word_umax32_0,2,32,0,0,UINT64_C(0),0},
{word_umax32_1,2,32,0,1,UINT64_C(0),0},
{word_umax32_2,2,32,0,2,UINT64_C(0),0},
{word_smin32_0,2,32,1,0,UINT64_C(0),0},
{word_smin32_1,2,32,1,1,UINT64_C(0),0},
{word_smin32_2,2,32,1,2,UINT64_C(0),0},
{word_smax32_0,2,32,2,0,UINT64_C(0),0},
{word_smax32_1,2,32,2,1,UINT64_C(0),0},
{word_smax32_2,2,32,2,2,UINT64_C(0),0},
{word_umax64_0,2,64,0,0,UINT64_C(0),0},
{word_umax64_1,2,64,0,1,UINT64_C(0),0},
{word_umax64_2,2,64,0,2,UINT64_C(0),0},
{word_smin64_0,2,64,1,0,UINT64_C(0),0},
{word_smin64_1,2,64,1,1,UINT64_C(0),0},
{word_smin64_2,2,64,1,2,UINT64_C(0),0},
{word_smax64_0,2,64,2,0,UINT64_C(0),0},
{word_smax64_1,2,64,2,1,UINT64_C(0),0},
{word_smax64_2,2,64,2,2,UINT64_C(0),0},
{word_swap16_0,3,16,0,0,UINT64_C(0),0},
{word_swap16_1,3,16,0,1,UINT64_C(0),0},
{word_swap32_0,3,32,0,0,UINT64_C(0),0},
{word_swap32_1,3,32,0,1,UINT64_C(0),0},
{word_swap64_0,3,64,0,0,UINT64_C(0),0},
{word_swap64_1,3,64,0,1,UINT64_C(0),0},
{word_zero_extend,4,64,0,0,UINT64_C(0),0},
};
int main(void) {
    const uint64_t guard=UINT64_C(0xa5a5a5a5a5a5a5a5);
    unsigned observations=0;
    for(unsigned f=0;f<sizeof rows/sizeof *rows;++f) {
        struct row r=rows[f];uint64_t sign=UINT64_C(1)<<(r.bits-1),mask=(sign-1)|sign;
        const uint64_t values[]={0,1,2,sign-1,sign,UINT64_C(0xffffffff),mask,UINT64_MAX};
        for(unsigned i=0;i<8;++i) for(unsigned j=0;j<8;++j) {
            uint64_t a=values[i],b=values[j],salt=(a<<7)^(b>>3)^UINT64_C(0x123456789abcdef0);
            uint64_t out[]={guard,0,0,guard},flag=0,value=0,x=a&mask,y=b&mask;
            if(r.kind==0) {
                if(r.side) {x=r.constant;y|=1;} else y=r.constant;
                value=r.op==0?x/y:x%y;
            } else if(r.kind==1) {
                if(r.side==1)x=UINT64_MAX;if(r.side==2)y=UINT64_MAX;
                if(r.variant==1)x=a+b;if(r.variant==2)y=salt;
                if(r.op==0) {__uint128_t full=(__uint128_t)x*y;value=(uint64_t)full;flag=full>UINT64_MAX;}
                else {
                    __int128 sx=(x&UINT64_C(0x8000000000000000))?(__int128)x-((__int128)1<<64):x;
                    __int128 sy=(y&UINT64_C(0x8000000000000000))?(__int128)y-((__int128)1<<64):y;
                    __int128 full=r.op==1?sx*sy:r.op==2?sx+sy:sx-sy;
                    value=(uint64_t)full;flag=full<-((__int128)1<<63) || full>(((__int128)1<<63)-1);
                }
            } else if(r.kind==2) {
                if(r.side==1)x=mask;if(r.side==2)y=mask;
                value=r.op==0?(x>y?x:y):r.op==1?((x^sign)<(y^sign)?x:y):((x^sign)>(y^sign)?x:y);
            } else if(r.kind==3) {
                if(r.side)x=r.bits==16?UINT64_C(0x1234):r.bits==32?UINT64_C(0x12345678):UINT64_C(0x123456789abcdef0);
                value=r.bits==16?__builtin_bswap16((uint16_t)x):r.bits==32?__builtin_bswap32((uint32_t)x):__builtin_bswap64(x);
            } else value=(a+b)&UINT32_MAX;
            uint64_t live=a^b;if(r.variant!=2)live^=salt;
            uint64_t actual=r.run(a,b,out+1,salt);
            if(actual!=flag || out[1]!=value || out[2]!=live || out[0]!=guard || out[3]!=guard) {
                fprintf(stderr,"word arithmetic row=%u a=%llx b=%llx flag=%llx/%llx value=%llx/%llx live=%llx/%llx\n",f,(unsigned long long)a,(unsigned long long)b,(unsigned long long)actual,(unsigned long long)flag,(unsigned long long)out[1],(unsigned long long)value,(unsigned long long)out[2],(unsigned long long)live);return 1;
            }
            ++observations;
        }
    }
    printf("word-arithmetic observations=%u division=products=signed=extrema=bytes=aliases=live=guards=preserved\n",observations);
    return 0;
}

