#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
extern uint64_t wide_switch_129(const void *,void *,uint64_t);
extern uint64_t wide_switch_140(const void *,void *,uint64_t);
extern uint64_t wide_switch_200(const void *,void *,uint64_t);
extern uint64_t wide_switch_257(const void *,void *,uint64_t);
extern uint64_t wide_switch_500(const void *,void *,uint64_t);
extern uint64_t wide_switch_512(const void *,void *,uint64_t);
static const struct {unsigned bits;kernel run;} cases[]={{129,wide_switch_129},{140,wide_switch_140},{200,wide_switch_200},{257,wide_switch_257},{500,wide_switch_500},{512,wide_switch_512},};
int main(int argc,char **argv){unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0;size_t page=(size_t)sysconf(_SC_PAGESIZE);unsigned char *map=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(map==MAP_FAILED||mprotect(map+page,page,PROT_READ|PROT_WRITE))return 2;
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"wide-switch bits=%u pattern=%u seed=%u observation=%zu fault=%u\n",bits,pattern,seed,observations,fault);return 1;}}while(0)
for(unsigned which=0;which<sizeof cases/sizeof cases[0];which++){unsigned bits=cases[which].bits,n=(bits+7)/8;unsigned char mask=bits%8?(1u<<(bits%8))-1:255;unsigned char keys[4][64]={{0}};memset(keys[0],255,n);keys[0][0]=131;keys[1][0]=125;keys[2][(bits-1)/8]=1u<<((bits-1)%8);memset(keys[3],255,n);keys[3][(bits-1)/8]&=~(1u<<((bits-1)%8));for(unsigned key=0;key<4;key++)keys[key][n-1]&=mask;
for(unsigned pattern=0;pattern<16;pattern++)for(unsigned seed=0;seed<64;seed++){unsigned char *input=map+2*page-n,saved[64],normal[64];if(pattern<4)memcpy(input,keys[pattern],n);else for(unsigned i=0;i<n;i++)input[i]=(unsigned char)((seed*73+i*131)^(pattern*19+255));if(pattern==4)memset(input,0,n);if(pattern==5)memset(input,255,n);input[n-1]=(input[n-1]&mask)|((seed*41)&~mask);memcpy(saved,input,n);memcpy(normal,input,n);normal[n-1]&=mask;uint64_t tag=5;for(unsigned key=0;key<4;key++)if(memcmp(normal,keys[key],n)==0)tag=key+1;uint64_t value;memcpy(&value,input,8);uint64_t salt=UINT64_C(0x8123456789abcdef)^(seed*113+pattern);struct {uint64_t pre,data[3],post;} out;memset(&out,0xa5,sizeof out);uint64_t returned=cases[which].run(input,out.data,salt);if(fault==1)out.data[0]^=1;if(fault==2)out.data[1]^=1;if(fault==3)out.post^=1;uint64_t expected=(tag+value)^salt;CHECK(returned==(expected^(value+salt)));CHECK(out.data[0]==expected);CHECK(out.data[1]==salt);CHECK(out.data[2]==value);CHECK(out.pre==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(out.post==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(memcmp(input,saved,n)==0);}}
printf("wide-switch observations=%zu exact-limbs=cfg-phi-edges=stack-arguments=dirty-tail-bits=live-values=guard-pages=preserved\n",observations);return munmap(map,page*3)!=0;}
