#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static unsigned observations,fault,helper_calls,helper_errors;
static uint64_t expected_args[8];
static const uint64_t values[]={0,1,127,255,65535,UINT64_C(0x8000000000000000),UINT64_C(0x0123456789abcdef),UINT64_MAX};
static const uint64_t seeds[]={0,1,UINT64_C(0xa55a55aa12345678),UINT64_MAX};
static int mismatch(const char *kind,unsigned which,unsigned value,unsigned seed){
 fprintf(stderr,"call return mismatch kind=%s case=%u value=%u seed=%u fault=%u observation=%u\n",kind,which,value,seed,fault,observations);return 1;
}
static uint64_t provider_value(uint64_t a,uint64_t b,uint64_t c,uint64_t d,uint64_t e,uint64_t f,uint64_t g,uint64_t h){return ((((((a+b)^c)+d)^e)-f)^g)+h;}
#define CLOBBER_CALLERS() __asm__ volatile("mov $17,%%rax\n\tmov $19,%%rcx\n\tmov $23,%%rdx\n\tmov $29,%%rsi\n\tmov $31,%%rdi\n\tmov $37,%%r8\n\tmov $41,%%r9\n\tmov $43,%%r10\n\tmov $47,%%r11":::"rax","rcx","rdx","rsi","rdi","r8","r9","r10","r11","cc","memory")
__attribute__((noinline)) static uint32_t narrow_provider(unsigned bits,uint32_t a,uint64_t b,uint64_t c,uint64_t d,uint64_t e,uint64_t f,uint64_t g,uint64_t h){
 const uint64_t actual[]={a,b,c,d,e,f,g,h};helper_calls++;
 for(unsigned i=0;i<8;i++)if(actual[i]!=expected_args[i])helper_errors++;
 volatile uint32_t result=(uint32_t)provider_value(a,b,c,d,e,f,g,h)&((UINT32_C(1)<<bits)-1);
 CLOBBER_CALLERS();return result;
}
#define PROVIDER(bits) uint32_t return_attr_helper_##bits(uint32_t a,uint64_t b,uint64_t c,uint64_t d,uint64_t e,uint64_t f,uint64_t g,uint64_t h){return narrow_provider(bits,a,b,c,d,e,f,g,h);}
PROVIDER(1) PROVIDER(7) PROVIDER(8) PROVIDER(16) PROVIDER(23) PROVIDER(31)
static int check_narrow(void){
 for(unsigned k=0;k<sizeof(narrow_cases)/sizeof(narrow_cases[0]);k++)for(unsigned i=0;i<8;i++)for(unsigned s=0;s<4;s++){
  uint64_t a=values[i],b=seeds[s],c=values[(i+1)&7],d=values[(i+3)&7]^b,e=~b,f=values[(i+5)&7]+b,g=a^b,h=a-b;
  uint32_t mask=(UINT32_C(1)<<narrow_cases[k].bits)-1;
  const uint64_t arguments[]={a&mask,b,c,d,e,f,g,h};memcpy(expected_args,arguments,sizeof(arguments));helper_calls=helper_errors=0;
  uint64_t result=provider_value(a&mask,b,c,d,e,f,g,h)&mask;
  uint64_t expected=((((((result^a)+b)^c)+d)^e)-f)^g;expected+=h;
  uint64_t actual=narrow_cases[k].run(a,b,c,d,e,f,g,h);
  if(fault==1)actual^=1;if(fault==2)helper_errors++;
  if(actual!=expected||helper_calls!=1||helper_errors)return mismatch("call-registers",k,i,s);observations++;
  helper_calls=helper_errors=0;uint32_t clean=(uint32_t)a&mask;
  uint32_t returned=narrow_cases[k].raw(clean,b);
  if(fault==4)returned^=UINT32_C(1)<<narrow_cases[k].bits;
  if(returned!=((clean^b)&mask)||helper_calls||helper_errors)return mismatch("raw-zero-extension",k,i,s);observations++;
 }
 return 0;
}
__attribute__((noinline)) static unsigned char *pointer_provider(unsigned char *input,uint64_t choose,uint64_t seed,uint64_t live){
 const uint64_t actual[]={(uintptr_t)input,choose,seed,live};helper_calls++;
 for(unsigned i=0;i<4;i++)if(actual[i]!=expected_args[i])helper_errors++;
 unsigned char *volatile result=(choose&1)?input:0;CLOBBER_CALLERS();return result;
}
unsigned char *return_attr_pointer_helper_16(unsigned char *p,uint64_t c,uint64_t s,uint64_t l){return pointer_provider(p,c,s,l);}
unsigned char *return_attr_pointer_helper_140(unsigned char *p,uint64_t c,uint64_t s,uint64_t l){return pointer_provider(p,c,s,l);}
static int check_nullable(void){
 const struct{uint64_t(*run)(unsigned char*,uint64_t,uint64_t,uint64_t);unsigned bytes;} cases[]={{return_attr_nullable_16,16},{return_attr_nullable_140,140}};
 for(unsigned k=0;k<2;k++)for(unsigned present=0;present<2;present++)for(unsigned choose=0;choose<2;choose++)for(unsigned s=0;s<4;s++)for(unsigned l=0;l<4;l++){
  unsigned char memory[160],expected[160];for(unsigned i=0;i<sizeof(memory);i++)memory[i]=(unsigned char)(i*37+s+l);memcpy(expected,memory,sizeof(memory));
  unsigned char *input=present?memory+8:0;const uint64_t arguments[]={(uintptr_t)input,choose,seeds[s],seeds[l]};memcpy(expected_args,arguments,sizeof(arguments));helper_calls=helper_errors=0;
  uint64_t payload=(present&&choose)?(expected[8]^expected[8+cases[k].bytes-1]):74565;
  uint64_t wanted=(payload^seeds[s])+seeds[l],actual=cases[k].run(input,choose,seeds[s],seeds[l]);
  if(fault==3)memory[0]^=1;
  if(actual!=wanted||memcmp(memory,expected,sizeof(memory))||helper_calls!=1||helper_errors)return mismatch("nullable-call",k,s,l);observations++;
 }
 for(unsigned present=0;present<2;present++)for(unsigned s=0;s<4;s++){
  unsigned char memory[32],expected[32];memset(memory,(int)(0x5a+s),sizeof(memory));memcpy(expected,memory,sizeof(memory));
  unsigned char *input=present?memory+8:0,*actual=return_attr_nullable_forward(input);
  if(fault==5)actual=memory+9;
  if(actual!=input||memcmp(memory,expected,sizeof(memory)))return mismatch("nullable-forward",0,present,s);observations++;
 }
 return 0;
}
int main(int argc,char **argv){
 if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);if(argc>2||fault>5)return 2;
 if(check_narrow()||check_nullable())return 1;
 if(observations!=520)return mismatch("count",0,0,0);
 puts("call-return-attributes observations=520 zeroext=nullable=padding=live=guards=preserved");return 0;
}
