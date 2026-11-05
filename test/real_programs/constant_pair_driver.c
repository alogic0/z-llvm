#include <stdint.h>
#include <stdio.h>
#include <inttypes.h>
static void clobber(void) { __asm__ volatile ("xor %%eax, %%eax; xor %%ecx, %%ecx; xor %%edx, %%edx; xor %%esi, %%esi; xor %%edi, %%edi; xor %%r8d, %%r8d; xor %%r9d, %%r9d; xor %%r10d, %%r10d; xor %%r11d, %%r11d" ::: "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "cc"); }
uint64_t constant_pair_clobber(uint64_t value) { uint64_t result=value^UINT64_C(0x13579bdf2468ace0); clobber();return result; }
extern uint64_t constant_pair_pi_argument(void *,void **,uint64_t,uint64_t *);
extern uint64_t constant_pair_pi_loaded(void *,void **,uint64_t,uint64_t *);
extern uint64_t constant_pair_pi_frame(void *,void **,uint64_t,uint64_t *);
extern uint64_t constant_pair_ip_argument(void *,void **,uint64_t,uint64_t *);
extern uint64_t constant_pair_ip_loaded(void *,void **,uint64_t,uint64_t *);
extern uint64_t constant_pair_ip_frame(void *,void **,uint64_t,uint64_t *);
extern uint64_t constant_pair_pp_argument(void *,void **,uint64_t,uint64_t *);
extern uint64_t constant_pair_pp_loaded(void *,void **,uint64_t,uint64_t *);
extern uint64_t constant_pair_pp_frame(void *,void **,uint64_t,uint64_t *);
extern uint64_t constant_pair_ii_argument(void *,void **,uint64_t,uint64_t *);
extern uint64_t constant_pair_ii_loaded(void *,void **,uint64_t,uint64_t *);
extern uint64_t constant_pair_ii_frame(void *,void **,uint64_t,uint64_t *);
struct Case { const char *name; uint64_t (*run)(void *,void **,uint64_t,uint64_t *); uint64_t lo,hi; int frame; };
static const struct Case cases[] = {
 {"constant_pair_pi_argument",constant_pair_pi_argument,8,UINT64_MAX,0},
 {"constant_pair_pi_loaded",constant_pair_pi_loaded,8,UINT64_MAX,0},
 {"constant_pair_pi_frame",constant_pair_pi_frame,8,UINT64_MAX,1},
 {"constant_pair_ip_argument",constant_pair_ip_argument,UINT64_C(0xdeadbeef12345678),0,0},
 {"constant_pair_ip_loaded",constant_pair_ip_loaded,UINT64_C(0xdeadbeef12345678),0,0},
 {"constant_pair_ip_frame",constant_pair_ip_frame,UINT64_C(0xdeadbeef12345678),0,1},
 {"constant_pair_pp_argument",constant_pair_pp_argument,0,1,0},
 {"constant_pair_pp_loaded",constant_pair_pp_loaded,0,1,0},
 {"constant_pair_pp_frame",constant_pair_pp_frame,0,1,1},
 {"constant_pair_ii_argument",constant_pair_ii_argument,UINT64_C(0x8000000000000000),UINT64_C(0x100000000),0},
 {"constant_pair_ii_loaded",constant_pair_ii_loaded,UINT64_C(0x8000000000000000),UINT64_C(0x100000000),0},
 {"constant_pair_ii_frame",constant_pair_ii_frame,UINT64_C(0x8000000000000000),UINT64_C(0x100000000),1},
};

int main(void) {
 unsigned observations=0;
 for(unsigned c=0;c<sizeof(cases)/sizeof(cases[0]);c++) for(unsigned i=0;i<64;i++) {
  const struct Case *item=&cases[c];uint64_t live=UINT64_C(0xdeadbeef12345678)^(UINT64_C(0x9e3779b97f4a7c15)*i);
  struct {uint64_t before,data[6],after;} buffer={123,{0},456};
  for(unsigned j=0;j<6;j++)buffer.data[j]=UINT64_C(0xaaaaaaaaaaaaaaaa);
  struct {uint64_t before,value,after;} out={789,0,987};void *slot=buffer.data;
  uint64_t got=item->run(buffer.data,&slot,live,&out.value);
  int bad=got!=((item->lo+item->hi)^live)||buffer.data[0]!=item->lo||buffer.data[1]!=item->hi||out.value!=(live^UINT64_C(0x13579bdf2468ace0))||buffer.before!=123||buffer.after!=456||out.before!=789||out.after!=987||slot!=buffer.data;
  for(unsigned j=2;j<6;j++)bad|=buffer.data[j]!=(item->frame?0:UINT64_C(0xaaaaaaaaaaaaaaaa));
  if(bad){fprintf(stderr,"%s input=%u got=%" PRIx64 " low=%" PRIx64 " high=%" PRIx64 "\n",item->name,i,got,buffer.data[0],buffer.data[1]);return 1;}
  observations++;
 }
 printf("constant-pair observations=%u fields=addresses=frames=live=guards=preserved\n",observations);return 0;
}
