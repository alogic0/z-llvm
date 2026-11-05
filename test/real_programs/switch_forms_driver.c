#include <stdint.h>
#include <stdio.h>
typedef uint64_t (*probe)(uint64_t,uint64_t,uint64_t *);
extern uint64_t switch_8_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t switch_8_9(uint64_t,uint64_t,uint64_t *);
extern uint64_t switch_8_61(uint64_t,uint64_t,uint64_t *);
extern uint64_t switch_8_127(uint64_t,uint64_t,uint64_t *);
extern uint64_t switch_32_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t switch_32_9(uint64_t,uint64_t,uint64_t *);
extern uint64_t switch_32_61(uint64_t,uint64_t,uint64_t *);
extern uint64_t switch_32_127(uint64_t,uint64_t,uint64_t *);
extern uint64_t switch_64_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t switch_64_9(uint64_t,uint64_t,uint64_t *);
extern uint64_t switch_64_61(uint64_t,uint64_t,uint64_t *);
extern uint64_t switch_64_127(uint64_t,uint64_t,uint64_t *);
extern uint64_t cfg_129(uint64_t,uint64_t,uint64_t *);
extern uint64_t cfg_779(uint64_t,uint64_t,uint64_t *);
extern uint64_t cfg_1024(uint64_t,uint64_t,uint64_t *);
extern uint64_t switch_duplicate(uint64_t,uint64_t,uint64_t *);
extern uint64_t switch_loop(uint64_t,uint64_t,uint64_t *);
struct row {probe run;unsigned bits,count,kind;};
static const struct row rows[]={
{switch_8_0,8,0,0},
{switch_8_9,8,9,0},
{switch_8_61,8,61,0},
{switch_8_127,8,127,0},
{switch_32_0,32,0,0},
{switch_32_9,32,9,0},
{switch_32_61,32,61,0},
{switch_32_127,32,127,0},
{switch_64_0,64,0,0},
{switch_64_9,64,9,0},
{switch_64_61,64,61,0},
{switch_64_127,64,127,0},
{cfg_129,64,129,1},
{cfg_779,64,779,1},
{cfg_1024,64,1024,1},
{switch_duplicate,64,3,2},
{switch_loop,64,9,3},
};
int main(void) {
    unsigned observations=0;
    const uint64_t guard=UINT64_C(0xa5a5a5a5a5a5a5a5);
    for(unsigned f=0;f<sizeof rows/sizeof *rows;++f) {
        struct row r=rows[f];uint64_t sign=UINT64_C(1)<<(r.bits-1),mask=(sign-1)|sign;
        for(unsigned i=0;i<256;++i) {
            uint64_t input=i<128?sign+i:i-128;
            if(r.bits<64) input|=~mask;
            if(i==255)input=UINT64_MAX;
            uint64_t salt=(input>>7)^UINT64_C(0x123456789abcdef0),x=input&mask;
            uint64_t expected=salt;
            if(r.kind==0)expected+=x>=sign && x-sign<r.count?x-sign:999;
            else if(r.kind==1)expected+=input+r.count;
            else if(r.kind==2)expected+=input==UINT64_C(0x8000000000000000)?7:0;
            else for(unsigned counter=input&15;counter;--counter)expected+=counter<=9?counter:17;
            uint64_t out[]={guard,0,0,guard};uint64_t result=r.run(input,salt,out+1);
            if(result!=expected || out[1]!=expected || out[2]!=(input^salt) || out[0]!=guard || out[3]!=guard) {
                fprintf(stderr,"switch forms row=%u input=%llx result=%llx/%llx value=%llx live=%llx/%llx\n",f,(unsigned long long)input,(unsigned long long)result,(unsigned long long)expected,(unsigned long long)out[1],(unsigned long long)out[2],(unsigned long long)(input^salt));return 1;
            }
            ++observations;
        }
    }
    printf("switch-forms observations=%u cases=widths=phis=loops=blocks=live=guards=preserved\n",observations);
    return 0;
}

