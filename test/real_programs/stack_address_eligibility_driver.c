#include <stdint.h>
#include <stdbool.h>
typedef uint64_t (*eligibility_fn)(unsigned char*,uint64_t,bool,uint64_t,uint64_t);
extern uint64_t eligibility_i8_false(unsigned char*,uint64_t,bool,uint64_t,uint64_t);
extern uint64_t eligibility_i8_true(unsigned char*,uint64_t,bool,uint64_t,uint64_t);
extern uint64_t eligibility_i16_false(unsigned char*,uint64_t,bool,uint64_t,uint64_t);
extern uint64_t eligibility_i16_true(unsigned char*,uint64_t,bool,uint64_t,uint64_t);
extern uint64_t eligibility_i32_false(unsigned char*,uint64_t,bool,uint64_t,uint64_t);
extern uint64_t eligibility_i32_true(unsigned char*,uint64_t,bool,uint64_t,uint64_t);
extern uint64_t eligibility_i64_false(unsigned char*,uint64_t,bool,uint64_t,uint64_t);
extern uint64_t eligibility_i64_true(unsigned char*,uint64_t,bool,uint64_t,uint64_t);
extern uint64_t eligibility_i128_false(unsigned char*,uint64_t,bool,uint64_t,uint64_t);
extern uint64_t eligibility_i128_true(unsigned char*,uint64_t,bool,uint64_t,uint64_t);
extern uint64_t eligibility_array16_false(unsigned char*,uint64_t,bool,uint64_t,uint64_t);
extern uint64_t eligibility_array16_true(unsigned char*,uint64_t,bool,uint64_t,uint64_t);
static const struct { eligibility_fn run; unsigned bytes; bool local_on_true; } cases[]={
 {eligibility_i8_false,1,false},
 {eligibility_i8_true,1,true},
 {eligibility_i16_false,2,false},
 {eligibility_i16_true,2,true},
 {eligibility_i32_false,4,false},
 {eligibility_i32_true,4,true},
 {eligibility_i64_false,4,false},
 {eligibility_i64_true,4,true},
 {eligibility_i128_false,4,false},
 {eligibility_i128_true,4,true},
 {eligibility_array16_false,4,false},
 {eligibility_array16_true,4,true},
};
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
static unsigned observations,fault;
static int mismatch(const char *kind) {
 fprintf(stderr,"stack eligibility mismatch kind=%s fault=%u observation=%u\n",kind,fault,observations); return 1;
}
static void source_words(uint32_t out[3],uint64_t value) {
 out[0]=(uint32_t)(value^UINT64_C(0x0102030405060708));
 out[1]=(uint32_t)(value>>32); out[2]=out[0]^UINT32_C(0x5a69c3d4);
}
static uint64_t expected_result(unsigned c,const unsigned char *external,uint64_t value,bool choose,uint64_t seed) {
 uint64_t mask=(UINT64_C(1)<<(cases[c].bytes*8))-1;
 uint64_t original=value&mask,selected=original;
 if(choose!=cases[c].local_on_true){selected=0;memcpy(&selected,external,cases[c].bytes);}
 return selected^(original<<17)^seed^value;
}
static int check(unsigned c,uint64_t value,bool choose,unsigned length,uint64_t seed) {
 unsigned char data[32],expected[32]; uint32_t source[3]; source_words(source,value);
 memset(data,0x93,sizeof(data));memcpy(expected,data,sizeof(data));
 memcpy(expected+5,source,length);
 uint64_t actual=cases[c].run(data+5,value,choose,length,seed);
 if(fault==1)actual^=1; if(fault==2)data[5]^=1;
 if(fault==3)data[4]^=1; if(fault==4)data[17]^=1;
 if(actual!=expected_result(c,expected+5,value,choose,seed)||memcmp(data,expected,sizeof(data)))return mismatch("copy-select");
 observations++;return 0;
}
int main(int argc,char **argv) {
 if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);if(argc>2||fault>4)return 2;
 const uint64_t values[]={0,UINT64_C(0x0123456789abcdef),UINT64_C(0xfedcba9876543210),UINT64_MAX};
 const uint64_t seeds[]={0,1,UINT64_MAX};
 const unsigned count=sizeof(cases)/sizeof(cases[0]);if(count!=12)return 2;
 for(unsigned c=0;c<count;c++)for(unsigned v=0;v<4;v++)for(unsigned s=0;s<3;s++)
  for(unsigned choose=0;choose<2;choose++)for(unsigned n=0;n<=12;n++)
   if(check(c,values[v],choose!=0,n,seeds[s]))return 1;
 long page=sysconf(_SC_PAGESIZE);if(page<32)return 2;
 unsigned char *mapping=mmap(0,(size_t)page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
 if(mapping==MAP_FAILED||mprotect(mapping+page,(size_t)page,PROT_NONE))return 2;
 for(unsigned c=0;c<count;c++) {
  const uint64_t value=values[1],seed=UINT64_MAX;
  const bool local_choice=cases[c].local_on_true;
  uint64_t actual=cases[c].run(mapping+page,value,local_choice,0,seed);
  if(actual!=expected_result(c,mapping+page,value,local_choice,seed))return mismatch("zero-length-page");
  observations++;
  for(unsigned choose=0;choose<2;choose++) {
   unsigned char expected[16];uint32_t source[3];source_words(source,value);
   memset(mapping+page-16,0x7b,16);memset(expected,0x7b,16);memcpy(expected+4,source,12);
   actual=cases[c].run(mapping+page-12,value,choose!=0,12,seed);
   if(actual!=expected_result(c,expected+4,value,choose!=0,seed)||memcmp(mapping+page-16,expected,16))return mismatch("full-length-page");
   observations++;
  }
 }
 if(munmap(mapping,(size_t)page*2))return 2;
 if(observations!=3780)return mismatch("count");
 puts("stack-address-eligibility observations=3780 choices=copies=live=guards=preserved");return 0;
}
