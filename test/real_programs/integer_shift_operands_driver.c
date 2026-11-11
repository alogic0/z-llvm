#include <stdint.h>
#include <stdbool.h>
typedef uint64_t (*word_fn)(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
typedef uint64_t (*pair_fn)(unsigned char*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_shl32_0(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_shl32_1(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_shl32_2(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_shl32_3(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_lshr32_0(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_lshr32_1(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_lshr32_2(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_lshr32_3(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_ashr32_0(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_ashr32_1(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_ashr32_2(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_ashr32_3(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_shl64_0(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_shl64_1(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_shl64_2(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_shl64_3(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_lshr64_0(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_lshr64_1(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_lshr64_2(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_lshr64_3(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_ashr64_0(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_ashr64_1(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_ashr64_2(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_word_ashr64_3(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
static const struct { word_fn run; unsigned bits,op; uint64_t literal; } word_cases[]={
 {shift_word_shl32_0,32,0,UINT64_C(2147483648)},
 {shift_word_shl32_1,32,0,UINT64_C(2147483648)},
 {shift_word_shl32_2,32,0,UINT64_C(4294967295)},
 {shift_word_shl32_3,32,0,UINT64_C(1985229328)},
 {shift_word_lshr32_0,32,1,UINT64_C(2147483648)},
 {shift_word_lshr32_1,32,1,UINT64_C(2147483648)},
 {shift_word_lshr32_2,32,1,UINT64_C(4294967295)},
 {shift_word_lshr32_3,32,1,UINT64_C(1985229328)},
 {shift_word_ashr32_0,32,2,UINT64_C(2147483648)},
 {shift_word_ashr32_1,32,2,UINT64_C(2147483648)},
 {shift_word_ashr32_2,32,2,UINT64_C(4294967295)},
 {shift_word_ashr32_3,32,2,UINT64_C(1985229328)},
 {shift_word_shl64_0,64,0,UINT64_C(9223372036854775808)},
 {shift_word_shl64_1,64,0,UINT64_C(9223372036854775808)},
 {shift_word_shl64_2,64,0,UINT64_C(18446744073709551615)},
 {shift_word_shl64_3,64,0,UINT64_C(18364758544493064720)},
 {shift_word_lshr64_0,64,1,UINT64_C(9223372036854775808)},
 {shift_word_lshr64_1,64,1,UINT64_C(9223372036854775808)},
 {shift_word_lshr64_2,64,1,UINT64_C(18446744073709551615)},
 {shift_word_lshr64_3,64,1,UINT64_C(18364758544493064720)},
 {shift_word_ashr64_0,64,2,UINT64_C(9223372036854775808)},
 {shift_word_ashr64_1,64,2,UINT64_C(9223372036854775808)},
 {shift_word_ashr64_2,64,2,UINT64_C(18446744073709551615)},
 {shift_word_ashr64_3,64,2,UINT64_C(18364758544493064720)},
};
extern uint64_t shift_pair_0(unsigned char*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_pair_1(unsigned char*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_pair_7(unsigned char*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_pair_31(unsigned char*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_pair_32(unsigned char*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_pair_40(unsigned char*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_pair_63(unsigned char*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_pair_64(unsigned char*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_pair_65(unsigned char*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_pair_127(unsigned char*,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t shift_pair_named(unsigned char*,uint64_t,uint64_t,uint64_t,uint64_t);
static const struct { pair_fn run; int count; } pair_cases[]={
 {shift_pair_0,0},
 {shift_pair_1,1},
 {shift_pair_7,7},
 {shift_pair_31,31},
 {shift_pair_32,32},
 {shift_pair_40,40},
 {shift_pair_63,63},
 {shift_pair_64,64},
 {shift_pair_65,65},
 {shift_pair_127,127},
 {shift_pair_named,-1},
};
extern void integer_shift_digest(void*,unsigned char*);
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
static unsigned observations,fault,clobber_calls;
static const uint64_t values[]={0,1,127,UINT64_C(0x8000000000000000),UINT64_C(0x7fffffffffffffff),UINT64_C(0x0123456789abcdef),UINT64_C(0xfedcba9876543210),UINT64_MAX};
static const uint64_t seeds[]={0,1,UINT64_C(0xa55a55aa12345678),UINT64_MAX};
static uint64_t rotate(uint64_t x,unsigned n){return (x<<n)|(x>>(64-n));}
static uint64_t clobber_value(uint64_t x){return (x^UINT64_C(0x9e3779b97f4a7c15))+UINT64_C(0xd1b54a32d192ed03);}
__attribute__((noinline)) uint64_t shift_operand_clobber(uint64_t x){
 volatile uint64_t saved=x;clobber_calls++;
 __asm__ volatile("mov $17,%%rax\n\tmov $19,%%rcx\n\tmov $23,%%rdx\n\tmov $29,%%rsi\n\tmov $31,%%rdi\n\tmov $37,%%r8\n\tmov $41,%%r9\n\tmov $43,%%r10\n\tmov $47,%%r11":::"rax","rcx","rdx","rsi","rdi","r8","r9","r10","r11","cc","memory");
 return clobber_value(saved);
}
static int mismatch(const char *kind,unsigned which,unsigned value,unsigned amount){
 fprintf(stderr,"integer shift mismatch kind=%s case=%u value=%u count=%u fault=%u observation=%u\n",kind,which,value,amount,fault,observations);return 1;
}
static int check_words(void){
 for(unsigned k=0;k<sizeof(word_cases)/sizeof(word_cases[0]);k++)for(unsigned n=0;n<word_cases[k].bits;n++)for(unsigned s=0;s<4;s++){
  uint64_t mask=word_cases[k].bits==64?UINT64_MAX:UINT32_MAX,base=word_cases[k].literal,shifted;
  if(word_cases[k].op==0)shifted=(base<<n)&mask;
  else if(word_cases[k].op==1)shifted=base>>n;
  else shifted=(base>>n)|((n&&(base&(UINT64_C(1)<<(word_cases[k].bits-1))))?(mask^(mask>>n)):0);
  uint64_t a=seeds[s],b=a^UINT64_C(0xa55a55aa12345678),c=a+n,d=~a,e=a*17,f=a^n,g=a-n;
  uint64_t expected=(((((shifted^(a^b))+c)^d)-e)^f)+g;
  uint64_t actual=word_cases[k].run(UINT64_C(0xfedcba9876543200)|n,a,b,c,d,e,f,g);
  if(fault==1)actual^=1;
  if(actual!=expected)return mismatch("literal",k,s,n);observations++;
 }
 return 0;
}
static int check_pairs(void){
 for(unsigned k=0;k<sizeof(pair_cases)/sizeof(pair_cases[0]);k++){
  unsigned counts=pair_cases[k].count<0?128:1;
  for(unsigned n=0;n<counts;n++)for(unsigned l=0;l<8;l++)for(unsigned h=0;h<4;h++)for(unsigned s=0;s<4;s++){
   unsigned char data[32],expected[32];memset(data,0x93,sizeof(data));memcpy(expected,data,sizeof(data));
   unsigned count=pair_cases[k].count<0?n:(unsigned)pair_cases[k].count;
   __uint128_t bits=((__uint128_t)values[h+3]<<64)|values[l],shifted=bits>>count;
   uint64_t low=(uint64_t)shifted,high=(uint64_t)(shifted>>64);
   memcpy(expected+5,&low,8);memcpy(expected+13,&high,8);clobber_calls=0;
   uint64_t actual=pair_cases[k].run(data+5,values[l],values[h+3],UINT64_C(0xfeed0000)|n,seeds[s]);
   if(fault==2)data[5]^=1;if(fault==3)data[4]^=1;
   if(actual!=(((values[l]^values[h+3])+seeds[s])^clobber_value(seeds[s]))||memcmp(data,expected,sizeof(data))||clobber_calls!=1)return mismatch("pair-live-call",k,l,count);
   observations++;
  }
 }
 return 0;
}
struct digest_state{uint64_t v[4];unsigned char total,padding[7];uint64_t length;unsigned char tail[8];};
_Static_assert(sizeof(struct digest_state)==56&&offsetof(struct digest_state,length)==40&&offsetof(struct digest_state,tail)==48,"digest layout");
struct guarded_state{uint64_t prefix[2];struct digest_state state;uint64_t suffix[2];};
static void round_digest(uint64_t v[4]){
 v[0]+=v[1];v[1]=rotate(v[1],13)^v[0];v[0]=rotate(v[0],32);
 v[2]+=v[3];v[3]=rotate(v[3],16)^v[2];v[0]+=v[3];v[3]=rotate(v[3],21)^v[0];
 v[2]+=v[1];v[1]=rotate(v[1],17)^v[2];v[2]=rotate(v[2],32);
}
static void digest_oracle(struct digest_state *state,unsigned char out[16]){
 uint64_t message=0,v[4];memcpy(v,state->v,sizeof(v));
 for(unsigned i=0;i<state->length;i++)message|=(uint64_t)state->tail[i]<<(i*8);
 state->total=(unsigned char)(state->total+state->length);message|=(uint64_t)state->total<<56;
 v[3]^=message;round_digest(v);v[0]^=message;v[2]^=0xee;
 for(unsigned i=0;i<3;i++)round_digest(v);
 uint64_t first=v[0]^v[1]^v[2]^v[3];v[1]^=0xdd;
 for(unsigned i=0;i<3;i++)round_digest(v);
 uint64_t second=v[0]^v[1]^v[2]^v[3];memcpy(state->v,v,sizeof(v));
 for(unsigned i=0;i<8;i++){out[i]=(unsigned char)(first>>(i*8));out[i+8]=(unsigned char)(second>>(i*8));}
}
static void initialize_state(struct digest_state *state,unsigned value,unsigned total,unsigned length){
 state->v[0]=values[value]+UINT64_C(0x736f6d6570736575);state->v[1]=rotate(values[value],7)^UINT64_C(0x646f72616e646f6d);
 state->v[2]=~values[value];state->v[3]=values[value]^UINT64_C(0x7465646279746573);
 state->total=(unsigned char)total;state->length=length;for(unsigned i=0;i<8;i++)state->tail[i]=(unsigned char)(values[value]>>(i*8))^(unsigned char)(17*i+length);
}
static int check_digest(void){
 const unsigned totals[]={0,1,248,255};
 for(unsigned v=0;v<8;v++)for(unsigned t=0;t<4;t++)for(unsigned n=0;n<8;n++){
  struct guarded_state actual,expected;unsigned char out[32],wanted[32];memset(&actual,0xa5,sizeof(actual));initialize_state(&actual.state,v,totals[t],n);memcpy(&expected,&actual,sizeof(actual));
  memset(out,0x93,sizeof(out));memcpy(wanted,out,sizeof(out));digest_oracle(&expected.state,wanted+7);
  integer_shift_digest(&actual.state,out+7);if(fault==4)actual.state.tail[7]^=1;
  if(memcmp(&actual,&expected,sizeof(actual))||memcmp(out,wanted,sizeof(out)))return mismatch("digest-state",v,t,n);observations++;
 }
 long page=sysconf(_SC_PAGESIZE);if(page<128)return 2;
 unsigned char *mapping=mmap(0,(size_t)page*4,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
 if(mapping==MAP_FAILED||mprotect(mapping+page,(size_t)page,PROT_NONE)||mprotect(mapping+page*3,(size_t)page,PROT_NONE))return 2;
 struct digest_state *state=(struct digest_state*)(mapping+page-sizeof(*state));unsigned char *out=mapping+page*3-16;
 for(unsigned n=0;n<8;n++){
  struct digest_state expected;unsigned char wanted[16];memset(state,0xa5,sizeof(*state));initialize_state(state,5,255,n);memcpy(&expected,state,sizeof(expected));digest_oracle(&expected,wanted);
  memset((unsigned char*)state-8,0x7b,8);memset(out-8,0x7b,8);integer_shift_digest(state,out);
  if(memcmp(state,&expected,sizeof(expected))||memcmp(out,wanted,16))return mismatch("digest-page",0,0,n);
  for(unsigned i=0;i<8;i++)if(((unsigned char*)state)[(int)i-8]!=0x7b||out[(int)i-8]!=0x7b)return mismatch("digest-page-guard",0,i,n);
  observations++;
 }
 if(munmap(mapping,(size_t)page*4))return 2;return 0;
}
int main(int argc,char **argv){
 if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);if(argc>2||fault>4)return 2;
 if(check_words()||check_pairs()||check_digest())return 1;
 if(observations!=22536)return mismatch("count",0,0,0);
 puts("integer-shift-operands observations=22536 literals=pairs=digest=abi=guards=preserved");return 0;
}
