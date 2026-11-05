#include <stdint.h>
#include <stdio.h>
#include <inttypes.h>
static void clobber(void) { __asm__ volatile ("xor %%eax, %%eax; xor %%ecx, %%ecx; xor %%edx, %%edx; xor %%esi, %%esi; xor %%edi, %%edi; xor %%r8d, %%r8d; xor %%r9d, %%r9d; xor %%r10d, %%r10d; xor %%r11d, %%r11d" ::: "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "cc"); }
void *accumulator_store_destination(void **slot) { void *result=*slot; clobber(); return result; }
uint64_t accumulator_store_clobber(uint64_t input) { uint64_t result=input ^ UINT64_C(0x13579bdf2468ace0); clobber(); return result; }
extern uint64_t accumulator_store_i64_load_zero(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_i64_load_ones(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_i64_load_large(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_i64_load_input(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_i64_load_derived(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_i64_load_self(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_i64_call_zero(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_i64_call_ones(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_i64_call_large(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_i64_call_input(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_i64_call_derived(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_i64_call_self(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_ptr_load_zero(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_ptr_load_ones(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_ptr_load_large(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_ptr_load_input(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_ptr_load_derived(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_ptr_load_self(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_ptr_call_zero(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_ptr_call_ones(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_ptr_call_large(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_ptr_call_input(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_ptr_call_derived(void **, uint64_t, uint64_t, uint64_t *);
extern uint64_t accumulator_store_ptr_call_self(void **, uint64_t, uint64_t, uint64_t *);
int main(void) {
 static const uint64_t values[]={0,1,2,255,UINT32_MAX,UINT64_C(0x8000000000000000),UINT64_C(0xdeadbeef01234567),UINT64_MAX};
 unsigned observations=0;
 for (unsigned i=0;i<8;i++) for (unsigned j=0;j<8;j++) {
  uint64_t input=values[i],live=values[j],got,expected;
  struct {uint64_t before,value,after;} data={123,0,456},out={789,0,987}; void *slot=&data.value;
  got=accumulator_store_i64_load_zero(&slot,input,live,&out.value); expected=0;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_i64_load_zero i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_i64_load_ones(&slot,input,live,&out.value); expected=UINT64_MAX;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_i64_load_ones i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_i64_load_large(&slot,input,live,&out.value); expected=UINT64_C(0xdeadbeef12345678);
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_i64_load_large i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_i64_load_input(&slot,input,live,&out.value); expected=input;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_i64_load_input i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_i64_load_derived(&slot,input,live,&out.value); expected=input + 17;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_i64_load_derived i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_i64_load_self(&slot,input,live,&out.value); expected=(uint64_t)(uintptr_t)slot;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_i64_load_self i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_i64_call_zero(&slot,input,live,&out.value); expected=0;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_i64_call_zero i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_i64_call_ones(&slot,input,live,&out.value); expected=UINT64_MAX;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_i64_call_ones i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_i64_call_large(&slot,input,live,&out.value); expected=UINT64_C(0xdeadbeef12345678);
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_i64_call_large i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_i64_call_input(&slot,input,live,&out.value); expected=input;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_i64_call_input i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_i64_call_derived(&slot,input,live,&out.value); expected=input + 17;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_i64_call_derived i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_i64_call_self(&slot,input,live,&out.value); expected=(uint64_t)(uintptr_t)slot;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_i64_call_self i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_ptr_load_zero(&slot,input,live,&out.value); expected=0;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_ptr_load_zero i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_ptr_load_ones(&slot,input,live,&out.value); expected=UINT64_MAX;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_ptr_load_ones i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_ptr_load_large(&slot,input,live,&out.value); expected=UINT64_C(0xdeadbeef12345678);
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_ptr_load_large i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_ptr_load_input(&slot,input,live,&out.value); expected=input;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_ptr_load_input i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_ptr_load_derived(&slot,input,live,&out.value); expected=input + 17;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_ptr_load_derived i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_ptr_load_self(&slot,input,live,&out.value); expected=(uint64_t)(uintptr_t)slot;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_ptr_load_self i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_ptr_call_zero(&slot,input,live,&out.value); expected=0;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_ptr_call_zero i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_ptr_call_ones(&slot,input,live,&out.value); expected=UINT64_MAX;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_ptr_call_ones i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_ptr_call_large(&slot,input,live,&out.value); expected=UINT64_C(0xdeadbeef12345678);
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_ptr_call_large i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_ptr_call_input(&slot,input,live,&out.value); expected=input;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_ptr_call_input i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_ptr_call_derived(&slot,input,live,&out.value); expected=input + 17;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_ptr_call_derived i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
  got=accumulator_store_ptr_call_self(&slot,input,live,&out.value); expected=(uint64_t)(uintptr_t)slot;
  if (data.value!=expected || got!=expected+live || out.value!=(live ^ UINT64_C(0x13579bdf2468ace0)) || data.before!=123 || data.after!=456 || out.before!=789 || out.after!=987 || slot!=&data.value) { fprintf(stderr,"accumulator_store_ptr_call_self i=%u j=%u got=%" PRIx64 " value=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,data.value,expected); return 1; }
  observations++;
 }
 printf("accumulator-store observations=%u pointers=integers=constants=aliases=calls=live=guards=preserved\n",observations);
 return 0;
}
