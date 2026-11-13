#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t(*kernel)(void *,const void *,uint64_t);
struct test_case{kernel run;unsigned bits,dirty;};
static unsigned model(uint64_t lo,uint64_t hi,uint64_t salt,unsigned bits,unsigned dirty){
 if(bits<128)hi&=(UINT64_C(1)<<(bits-64))-1;
 if(dirty)return (unsigned)(lo^hi^salt)&1;
 uint64_t value=(lo*UINT64_C(0x9182736455aaccdd))^(hi*UINT64_C(0x123456789abcdef1))^salt;value^=value>>17;value*=UINT64_C(0x8123456789abcdef);return (unsigned)(value>>(salt%64))&1;
}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);
 unsigned char *map=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(map==MAP_FAILED||mprotect(map+page,page,PROT_READ|PROT_WRITE))return 2;
 for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<128;seed++){
  unsigned bits=cases[which].bits,bytes=(bits+7)/8;unsigned char *input=map+2*page-bytes,saved[16];uint64_t words[2]={seed*UINT64_C(0x9182736455aaccdd),seed*UINT64_C(0xfedcba9876543211)^UINT64_MAX};
  memcpy(input,words,bytes);memcpy(saved,input,bytes);memset(input-8,0xa5,8);
  uint64_t salt=seed*UINT64_C(0x123456789abcdef1),expected=model(words[0],words[1],salt,bits,cases[which].dirty);
  struct{uint64_t pre;unsigned char data[16];uint64_t post;}out;memset(&out,0xa5,sizeof out);uint64_t answer=cases[which].run(out.data,input,salt);
  if(fault==1)out.data[0]^=1;if(fault==2)answer^=1;if(fault==3)out.post^=1;uint64_t live;memcpy(&live,out.data+8,8);unsigned char guards[8];memset(guards,0xa5,8);int padding=1;for(unsigned i=1;i<8;i++)padding&=out.data[i]==0xa5;
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"boolean-wide-arguments case=%zu bits=%u seed=%u observation=%zu fault=%u\n",which,bits,seed,observations,fault);return 1;}}while(0)
  CHECK(answer==(expected^salt));CHECK((out.data[0]&1)==expected);CHECK(live==salt);CHECK(out.pre==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(padding);CHECK(out.post==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(memcmp(input,saved,bytes)==0);CHECK(memcmp(input-8,guards,8)==0);
#undef CHECK
 }
 printf("boolean-wide-arguments observations=%zu multiword-c-abi=defined-al-only=live-pointers=live-salt=exact-stores=guard-pages=preserved\n",observations);return munmap(map,page*3)!=0;
}
extern uint64_t boolean_wide_65_0_0(void *,const void *,uint64_t);
_Bool boolean_wide_65_0_0_provider(uint64_t lo,uint64_t hi,uint64_t salt){return model(lo,hi,salt,65,0);}
extern uint64_t boolean_wide_65_0_1(void *,const void *,uint64_t);
_Bool boolean_wide_65_0_1_provider(uint64_t lo,uint64_t hi,uint64_t salt){return model(lo,hi,salt,65,0);}
extern uint64_t boolean_wide_96_0_0(void *,const void *,uint64_t);
_Bool boolean_wide_96_0_0_provider(uint64_t lo,uint64_t hi,uint64_t salt){return model(lo,hi,salt,96,0);}
extern uint64_t boolean_wide_96_0_1(void *,const void *,uint64_t);
_Bool boolean_wide_96_0_1_provider(uint64_t lo,uint64_t hi,uint64_t salt){return model(lo,hi,salt,96,0);}
extern uint64_t boolean_wide_127_0_0(void *,const void *,uint64_t);
_Bool boolean_wide_127_0_0_provider(uint64_t lo,uint64_t hi,uint64_t salt){return model(lo,hi,salt,127,0);}
extern uint64_t boolean_wide_127_0_1(void *,const void *,uint64_t);
_Bool boolean_wide_127_0_1_provider(uint64_t lo,uint64_t hi,uint64_t salt){return model(lo,hi,salt,127,0);}
extern uint64_t boolean_wide_128_0_0(void *,const void *,uint64_t);
_Bool boolean_wide_128_0_0_provider(uint64_t lo,uint64_t hi,uint64_t salt){return model(lo,hi,salt,128,0);}
extern uint64_t boolean_wide_128_0_1(void *,const void *,uint64_t);
_Bool boolean_wide_128_0_1_provider(uint64_t lo,uint64_t hi,uint64_t salt){return model(lo,hi,salt,128,0);}
extern uint64_t boolean_wide_128_1_0(void *,const void *,uint64_t);
__asm__(".text\n.globl boolean_wide_128_1_0_provider\n.type boolean_wide_128_1_0_provider,@function\nboolean_wide_128_1_0_provider:\nmovabs $0xa5a5a5a5a5a5a500,%rax\nmovb %dil,%al\nxorb %sil,%al\nxorb %dl,%al\nandb $1,%al\nret\n.size boolean_wide_128_1_0_provider,.-boolean_wide_128_1_0_provider\n");
extern uint64_t boolean_wide_128_1_1(void *,const void *,uint64_t);
__asm__(".text\n.globl boolean_wide_128_1_1_provider\n.type boolean_wide_128_1_1_provider,@function\nboolean_wide_128_1_1_provider:\nmovabs $0xa5a5a5a5a5a5a500,%rax\nmovb %dil,%al\nxorb %sil,%al\nxorb %dl,%al\nandb $1,%al\nret\n.size boolean_wide_128_1_1_provider,.-boolean_wide_128_1_1_provider\n");
static const struct test_case cases[]={
{boolean_wide_65_0_0,65,0},
{boolean_wide_65_0_1,65,0},
{boolean_wide_96_0_0,96,0},
{boolean_wide_96_0_1,96,0},
{boolean_wide_127_0_0,127,0},
{boolean_wide_127_0_1,127,0},
{boolean_wide_128_0_0,128,0},
{boolean_wide_128_0_1,128,0},
{boolean_wide_128_1_0,128,1},
{boolean_wide_128_1_1,128,1},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
