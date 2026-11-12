#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(uint64_t,uint64_t);
struct test_case{unsigned bytes,literal;kernel run;};
static size_t observations;
static void check(int pass,unsigned slot,unsigned seed,unsigned fault){observations++;if(!pass){fprintf(stderr,"volatile-absolute slot=%u seed=%u observation=%zu fault=%u\n",slot,seed,observations,fault);exit(1);}}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;if(fault>3||sysconf(_SC_PAGESIZE)!=4096)return 2;
 unsigned char *base=(void *)(uintptr_t)UINT64_C(0x520000000000);
 void *mapping=mmap(base,4096*3,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS|MAP_FIXED_NOREPLACE,-1,0);
 if(mapping!=base||mprotect(base,4096,PROT_NONE)||mprotect(base+8192,4096,PROT_NONE))return 2;
 for(unsigned slot=0;slot<count;slot++)for(unsigned seed=0;seed<64;seed++){
  unsigned bytes=cases[slot].bytes;unsigned char *cell=base+8192-bytes;memset(base+4096,0xa5,4096);
  uint64_t before=seed*UINT64_C(0x8123456789abcdef),value=(seed+slot)*UINT64_C(0xf06dea67e461de5b),expected=cases[slot].literal?88:value,salt=~before;
  memcpy(cell,&before,bytes);uint64_t actual=cases[slot].run(value,salt);if(fault==1)actual^=1;if(fault==2)cell[0]^=1;if(fault==3)cell[-1]^=1;
  uint64_t mask=bytes==8?UINT64_MAX:(UINT64_C(1)<<(bytes*8))-1;
  check(actual==(((before^expected)&mask)^salt),slot,seed,fault);check(memcmp(cell,&expected,bytes)==0,slot,seed,fault);
  int guard=1;for(unsigned i=0;i<4096-bytes;i++)guard&=base[4096+i]==0xa5;check(guard,slot,seed,fault);
 }
 if(munmap(mapping,4096*3)||count!=10||observations!=1920)return 2;
 printf("volatile-absolute observations=%zu native-widths=constant-addresses=exact-events=guard-pages=preserved\n",observations);return 0;
}
extern uint64_t volatile_absolute_0_value(uint64_t,uint64_t);
extern uint64_t volatile_absolute_0_literal(uint64_t,uint64_t);
extern uint64_t volatile_absolute_1_value(uint64_t,uint64_t);
extern uint64_t volatile_absolute_1_literal(uint64_t,uint64_t);
extern uint64_t volatile_absolute_2_value(uint64_t,uint64_t);
extern uint64_t volatile_absolute_2_literal(uint64_t,uint64_t);
extern uint64_t volatile_absolute_3_value(uint64_t,uint64_t);
extern uint64_t volatile_absolute_3_literal(uint64_t,uint64_t);
extern uint64_t volatile_absolute_4_value(uint64_t,uint64_t);
extern uint64_t volatile_absolute_4_literal(uint64_t,uint64_t);
static const struct test_case cases[]={
{1,0,volatile_absolute_0_value},
{1,1,volatile_absolute_0_literal},
{2,0,volatile_absolute_1_value},
{2,1,volatile_absolute_1_literal},
{4,0,volatile_absolute_2_value},
{4,1,volatile_absolute_2_literal},
{8,0,volatile_absolute_3_value},
{8,1,volatile_absolute_3_literal},
{8,0,volatile_absolute_4_value},
{8,1,volatile_absolute_4_literal},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
