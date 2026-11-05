#include <stdint.h>
#include <stdio.h>
#include <inttypes.h>
typedef unsigned __int128 u128; typedef __int128 s128;
__attribute__((noinline)) uint64_t pair_arithmetic_clobber(uint64_t value) { uint64_t r=value^UINT64_C(0x13579bdf2468ace0); __asm__ volatile("xor %%eax,%%eax;xor %%ecx,%%ecx;xor %%edx,%%edx;xor %%edi,%%edi;xor %%esi,%%esi;xor %%r8d,%%r8d;xor %%r9d,%%r9d;xor %%r10d,%%r10d;xor %%r11d,%%r11d" ::: "rax","rcx","rdx","rdi","rsi","r8","r9","r10","r11","cc");return r;}
extern uint64_t pair_arithmetic_add(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_add(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a+b; }
extern uint64_t pair_arithmetic_mul(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_mul(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a*b; }
extern uint64_t pair_arithmetic_and(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_and(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a&b; }
extern uint64_t pair_arithmetic_shl(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_shl(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a<<n; }
extern uint64_t pair_arithmetic_lshr(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_lshr(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a>>n; }
extern uint64_t pair_arithmetic_ashr(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_ashr(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (a>>n)|((n && (a>>127))?~(u128)0<<(128-n):0); }
extern uint64_t pair_arithmetic_cmp_eq(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_cmp_eq(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a==b; }
extern uint64_t pair_arithmetic_cmp_ne(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_cmp_ne(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a!=b; }
extern uint64_t pair_arithmetic_cmp_ult(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_cmp_ult(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a<b; }
extern uint64_t pair_arithmetic_cmp_ule(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_cmp_ule(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a<=b; }
extern uint64_t pair_arithmetic_cmp_ugt(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_cmp_ugt(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a>b; }
extern uint64_t pair_arithmetic_cmp_uge(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_cmp_uge(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a>=b; }
extern uint64_t pair_arithmetic_cmp_slt(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_cmp_slt(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (s128)a<(s128)b; }
extern uint64_t pair_arithmetic_cmp_sle(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_cmp_sle(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (s128)a<=(s128)b; }
extern uint64_t pair_arithmetic_cmp_sgt(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_cmp_sgt(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (s128)a>(s128)b; }
extern uint64_t pair_arithmetic_cmp_sge(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_cmp_sge(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (s128)a>=(s128)b; }
extern uint64_t pair_arithmetic_select(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_select(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (uint64_t)b?a:b; }
extern uint64_t pair_arithmetic_zext_literal(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_zext_literal(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return 64; }
extern uint64_t pair_arithmetic_sext_literal(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_sext_literal(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (u128)(s128)-64; }
extern uint64_t pair_arithmetic_udiv_1(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_udiv_1(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a / (u128)1; }
extern uint64_t pair_arithmetic_udiv_3(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_udiv_3(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a / (u128)3; }
extern uint64_t pair_arithmetic_udiv_1000000000(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_udiv_1000000000(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a / (u128)1000000000; }
extern uint64_t pair_arithmetic_udiv_4294967295(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_udiv_4294967295(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a / (u128)4294967295; }
extern uint64_t pair_arithmetic_urem_1(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_urem_1(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a % (u128)1; }
extern uint64_t pair_arithmetic_urem_3(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_urem_3(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a % (u128)3; }
extern uint64_t pair_arithmetic_urem_1000000000(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_urem_1000000000(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a % (u128)1000000000; }
extern uint64_t pair_arithmetic_urem_4294967295(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_urem_4294967295(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a % (u128)4294967295; }
extern uint64_t pair_arithmetic_sdiv_1(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_sdiv_1(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (u128)((s128)a / (s128)1); }
extern uint64_t pair_arithmetic_sdiv_3(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_sdiv_3(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (u128)((s128)a / (s128)3); }
extern uint64_t pair_arithmetic_sdiv_neg_3(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_sdiv_neg_3(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (u128)((s128)a / (s128)-3); }
extern uint64_t pair_arithmetic_sdiv_1000000000(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_sdiv_1000000000(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (u128)((s128)a / (s128)1000000000); }
extern uint64_t pair_arithmetic_sdiv_neg_1000000000(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_sdiv_neg_1000000000(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (u128)((s128)a / (s128)-1000000000); }
extern uint64_t pair_arithmetic_sdiv_4294967295(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_sdiv_4294967295(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (u128)((s128)a / (s128)4294967295); }
extern uint64_t pair_arithmetic_sdiv_neg_4294967295(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_sdiv_neg_4294967295(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (u128)((s128)a / (s128)-4294967295); }
extern uint64_t pair_arithmetic_srem_1(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_srem_1(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (u128)((s128)a % (s128)1); }
extern uint64_t pair_arithmetic_srem_3(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_srem_3(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (u128)((s128)a % (s128)3); }
extern uint64_t pair_arithmetic_srem_neg_3(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_srem_neg_3(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (u128)((s128)a % (s128)-3); }
extern uint64_t pair_arithmetic_srem_1000000000(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_srem_1000000000(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (u128)((s128)a % (s128)1000000000); }
extern uint64_t pair_arithmetic_srem_neg_1000000000(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_srem_neg_1000000000(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (u128)((s128)a % (s128)-1000000000); }
extern uint64_t pair_arithmetic_srem_4294967295(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_srem_4294967295(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (u128)((s128)a % (s128)4294967295); }
extern uint64_t pair_arithmetic_srem_neg_4294967295(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_srem_neg_4294967295(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (u128)((s128)a % (s128)-4294967295); }
extern uint64_t pair_arithmetic_mul_zero_extended(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_mul_zero_extended(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (u128)(uint64_t)a*(uint64_t)b; }
extern uint64_t pair_arithmetic_mul_after_add(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_mul_after_add(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (a+b)*b; }
extern uint64_t pair_arithmetic_div_after_mul(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_div_after_mul(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return (a*b)/3; }
extern uint64_t pair_arithmetic_project_masked(u128,u128,uint64_t,void *);
static u128 expected_pair_arithmetic_project_masked(u128 a,u128 b) { unsigned n=(unsigned)(b&127); (void)n; return a&127; }
struct Case {const char *name;uint64_t (*run)(u128,u128,uint64_t,void *);u128 (*expected)(u128,u128);};
static const struct Case cases[] = {
{"pair_arithmetic_add",pair_arithmetic_add,expected_pair_arithmetic_add},
{"pair_arithmetic_mul",pair_arithmetic_mul,expected_pair_arithmetic_mul},
{"pair_arithmetic_and",pair_arithmetic_and,expected_pair_arithmetic_and},
{"pair_arithmetic_shl",pair_arithmetic_shl,expected_pair_arithmetic_shl},
{"pair_arithmetic_lshr",pair_arithmetic_lshr,expected_pair_arithmetic_lshr},
{"pair_arithmetic_ashr",pair_arithmetic_ashr,expected_pair_arithmetic_ashr},
{"pair_arithmetic_cmp_eq",pair_arithmetic_cmp_eq,expected_pair_arithmetic_cmp_eq},
{"pair_arithmetic_cmp_ne",pair_arithmetic_cmp_ne,expected_pair_arithmetic_cmp_ne},
{"pair_arithmetic_cmp_ult",pair_arithmetic_cmp_ult,expected_pair_arithmetic_cmp_ult},
{"pair_arithmetic_cmp_ule",pair_arithmetic_cmp_ule,expected_pair_arithmetic_cmp_ule},
{"pair_arithmetic_cmp_ugt",pair_arithmetic_cmp_ugt,expected_pair_arithmetic_cmp_ugt},
{"pair_arithmetic_cmp_uge",pair_arithmetic_cmp_uge,expected_pair_arithmetic_cmp_uge},
{"pair_arithmetic_cmp_slt",pair_arithmetic_cmp_slt,expected_pair_arithmetic_cmp_slt},
{"pair_arithmetic_cmp_sle",pair_arithmetic_cmp_sle,expected_pair_arithmetic_cmp_sle},
{"pair_arithmetic_cmp_sgt",pair_arithmetic_cmp_sgt,expected_pair_arithmetic_cmp_sgt},
{"pair_arithmetic_cmp_sge",pair_arithmetic_cmp_sge,expected_pair_arithmetic_cmp_sge},
{"pair_arithmetic_select",pair_arithmetic_select,expected_pair_arithmetic_select},
{"pair_arithmetic_zext_literal",pair_arithmetic_zext_literal,expected_pair_arithmetic_zext_literal},
{"pair_arithmetic_sext_literal",pair_arithmetic_sext_literal,expected_pair_arithmetic_sext_literal},
{"pair_arithmetic_udiv_1",pair_arithmetic_udiv_1,expected_pair_arithmetic_udiv_1},
{"pair_arithmetic_udiv_3",pair_arithmetic_udiv_3,expected_pair_arithmetic_udiv_3},
{"pair_arithmetic_udiv_1000000000",pair_arithmetic_udiv_1000000000,expected_pair_arithmetic_udiv_1000000000},
{"pair_arithmetic_udiv_4294967295",pair_arithmetic_udiv_4294967295,expected_pair_arithmetic_udiv_4294967295},
{"pair_arithmetic_urem_1",pair_arithmetic_urem_1,expected_pair_arithmetic_urem_1},
{"pair_arithmetic_urem_3",pair_arithmetic_urem_3,expected_pair_arithmetic_urem_3},
{"pair_arithmetic_urem_1000000000",pair_arithmetic_urem_1000000000,expected_pair_arithmetic_urem_1000000000},
{"pair_arithmetic_urem_4294967295",pair_arithmetic_urem_4294967295,expected_pair_arithmetic_urem_4294967295},
{"pair_arithmetic_sdiv_1",pair_arithmetic_sdiv_1,expected_pair_arithmetic_sdiv_1},
{"pair_arithmetic_sdiv_3",pair_arithmetic_sdiv_3,expected_pair_arithmetic_sdiv_3},
{"pair_arithmetic_sdiv_neg_3",pair_arithmetic_sdiv_neg_3,expected_pair_arithmetic_sdiv_neg_3},
{"pair_arithmetic_sdiv_1000000000",pair_arithmetic_sdiv_1000000000,expected_pair_arithmetic_sdiv_1000000000},
{"pair_arithmetic_sdiv_neg_1000000000",pair_arithmetic_sdiv_neg_1000000000,expected_pair_arithmetic_sdiv_neg_1000000000},
{"pair_arithmetic_sdiv_4294967295",pair_arithmetic_sdiv_4294967295,expected_pair_arithmetic_sdiv_4294967295},
{"pair_arithmetic_sdiv_neg_4294967295",pair_arithmetic_sdiv_neg_4294967295,expected_pair_arithmetic_sdiv_neg_4294967295},
{"pair_arithmetic_srem_1",pair_arithmetic_srem_1,expected_pair_arithmetic_srem_1},
{"pair_arithmetic_srem_3",pair_arithmetic_srem_3,expected_pair_arithmetic_srem_3},
{"pair_arithmetic_srem_neg_3",pair_arithmetic_srem_neg_3,expected_pair_arithmetic_srem_neg_3},
{"pair_arithmetic_srem_1000000000",pair_arithmetic_srem_1000000000,expected_pair_arithmetic_srem_1000000000},
{"pair_arithmetic_srem_neg_1000000000",pair_arithmetic_srem_neg_1000000000,expected_pair_arithmetic_srem_neg_1000000000},
{"pair_arithmetic_srem_4294967295",pair_arithmetic_srem_4294967295,expected_pair_arithmetic_srem_4294967295},
{"pair_arithmetic_srem_neg_4294967295",pair_arithmetic_srem_neg_4294967295,expected_pair_arithmetic_srem_neg_4294967295},
{"pair_arithmetic_mul_zero_extended",pair_arithmetic_mul_zero_extended,expected_pair_arithmetic_mul_zero_extended},
{"pair_arithmetic_mul_after_add",pair_arithmetic_mul_after_add,expected_pair_arithmetic_mul_after_add},
{"pair_arithmetic_div_after_mul",pair_arithmetic_div_after_mul,expected_pair_arithmetic_div_after_mul},
{"pair_arithmetic_project_masked",pair_arithmetic_project_masked,expected_pair_arithmetic_project_masked},
};

int main(void) {
 const uint64_t words[]={0,1,2,3,31,32,63,64,65,95,96,127,128,UINT64_C(0x8000000000000000),UINT64_MAX,UINT64_C(0xdeadbeef12345678)};
 unsigned observations=0;
 for(unsigned c=0;c<sizeof(cases)/sizeof(cases[0]);c++) for(unsigned i=0;i<256;i++) {
  u128 a=((u128)words[(i/16)%16]<<64)|words[i%16];
  if(i==255)a=((u128)1<<127)-1;
  u128 b=((u128)words[(i*7+5)%16]<<64)|words[(i*3+2)%16];
  const uint64_t live=UINT64_C(0xa5a55a5a12345678)^i;
  struct {uint64_t before,lo,hi,noise,after;} out={111,0,0,0,222};
  u128 expected=cases[c].expected(a,b);
  uint64_t got=cases[c].run(a,b,live,&out.lo);
  uint64_t lo=(uint64_t)expected,hi=(uint64_t)(expected>>64);
  if(out.lo!=lo||out.hi!=hi||got!=((lo+hi)^live)||out.noise!=(live^UINT64_C(0x13579bdf2468ace0))||out.before!=111||out.after!=222){
   fprintf(stderr,"%s input=%u got=%016" PRIx64 ":%016" PRIx64 " expected=%016" PRIx64 ":%016" PRIx64 "\n",cases[c].name,i,out.hi,out.lo,hi,lo);return 1;
  }
  observations++;
 }
 printf("pair-arithmetic observations=%u products=shifts=division=comparisons=live=guards=preserved\n",observations);return 0;
}
