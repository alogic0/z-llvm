#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <inttypes.h>
extern unsigned char address_flow_data[64];
uint64_t address_flow_clobber(uint64_t value) {
  uint64_t result = value ^ UINT64_C(0xdeadbeef12345678);
  __asm__ volatile ("xor %%eax, %%eax; xor %%ecx, %%ecx; xor %%edx, %%edx; xor %%esi, %%esi; xor %%edi, %%edi; xor %%r8d, %%r8d; xor %%r9d, %%r9d; xor %%r10d, %%r10d; xor %%r11d, %%r11d" ::: "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "cc");
  return result;
}
extern uint64_t address_flow_stride_0_dynamic(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_stride_0_constant(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_stride_1_dynamic(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_stride_1_constant(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_stride_4_dynamic(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_stride_4_constant(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_stride_24_dynamic(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_stride_24_constant(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_stride_256_dynamic(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_stride_256_constant(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_stride_257_dynamic(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_stride_257_constant(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_stride_4096_dynamic(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_stride_4096_constant(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_compare_eq_left(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_compare_eq_right(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_compare_ne_left(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_compare_ne_right(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_compare_ult_left(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_compare_ult_right(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_compare_ule_left(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_compare_ule_right(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_compare_ugt_left(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_compare_ugt_right(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_compare_uge_left(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_compare_uge_right(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_frame_8_memset(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_frame_8_memcpy(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_frame_16_memset(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_frame_16_memcpy(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_frame_32_memset(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_frame_32_memcpy(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_frame_64_memset(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_frame_64_memcpy(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_forward(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_forward_loop(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t address_flow_forward_diamond(void *, uint64_t, uint64_t, uint64_t *);
int main(void) {
  static const uint64_t values[] = {0, 1, 2, 255, UINT32_MAX, UINT64_C(0x8000000000000000), UINT64_C(0xdeadbeef01234567), UINT64_MAX};
  unsigned observations=0;
  for (unsigned i=0;i<8;i++) for (unsigned j=0;j<8;j++) {
    uint64_t index=values[i], live=values[j], input=values[i] ^ values[j];
    unsigned char buffer[8]; memcpy(buffer,&input,8); void *p=buffer;
    struct { uint64_t before, value, after; } out={UINT64_C(0x1122334455667788),0,UINT64_C(0x8877665544332211)};
    uint64_t got, expected;
    got=address_flow_stride_0_dynamic(p,index,live,&out.value); expected=(uint64_t)(uintptr_t)p + UINT64_C(0) * index;
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_stride_0_dynamic i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_stride_0_constant(p,index,live,&out.value); expected=(uint64_t)(uintptr_t)p + UINT64_C(0) * UINT64_MAX;
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_stride_0_constant i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_stride_1_dynamic(p,index,live,&out.value); expected=(uint64_t)(uintptr_t)p + UINT64_C(1) * index;
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_stride_1_dynamic i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_stride_1_constant(p,index,live,&out.value); expected=(uint64_t)(uintptr_t)p + UINT64_C(1) * UINT64_MAX;
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_stride_1_constant i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_stride_4_dynamic(p,index,live,&out.value); expected=(uint64_t)(uintptr_t)p + UINT64_C(4) * index;
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_stride_4_dynamic i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_stride_4_constant(p,index,live,&out.value); expected=(uint64_t)(uintptr_t)p + UINT64_C(4) * UINT64_MAX;
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_stride_4_constant i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_stride_24_dynamic(p,index,live,&out.value); expected=(uint64_t)(uintptr_t)p + UINT64_C(24) * index;
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_stride_24_dynamic i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_stride_24_constant(p,index,live,&out.value); expected=(uint64_t)(uintptr_t)p + UINT64_C(24) * UINT64_MAX;
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_stride_24_constant i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_stride_256_dynamic(p,index,live,&out.value); expected=(uint64_t)(uintptr_t)p + UINT64_C(256) * index;
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_stride_256_dynamic i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_stride_256_constant(p,index,live,&out.value); expected=(uint64_t)(uintptr_t)p + UINT64_C(256) * UINT64_MAX;
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_stride_256_constant i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_stride_257_dynamic(p,index,live,&out.value); expected=(uint64_t)(uintptr_t)p + UINT64_C(257) * index;
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_stride_257_dynamic i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_stride_257_constant(p,index,live,&out.value); expected=(uint64_t)(uintptr_t)p + UINT64_C(257) * UINT64_MAX;
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_stride_257_constant i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_stride_4096_dynamic(p,index,live,&out.value); expected=(uint64_t)(uintptr_t)p + UINT64_C(4096) * index;
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_stride_4096_dynamic i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_stride_4096_constant(p,index,live,&out.value); expected=(uint64_t)(uintptr_t)p + UINT64_C(4096) * UINT64_MAX;
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_stride_4096_constant i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_compare_eq_left(p,index,live,&out.value); expected=((uint64_t)(uintptr_t)address_flow_data + 8) == ((uint64_t)(uintptr_t)p);
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_compare_eq_left i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_compare_eq_right(p,index,live,&out.value); expected=((uint64_t)(uintptr_t)p) == ((uint64_t)(uintptr_t)address_flow_data + 8);
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_compare_eq_right i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_compare_ne_left(p,index,live,&out.value); expected=((uint64_t)(uintptr_t)address_flow_data + 8) != ((uint64_t)(uintptr_t)p);
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_compare_ne_left i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_compare_ne_right(p,index,live,&out.value); expected=((uint64_t)(uintptr_t)p) != ((uint64_t)(uintptr_t)address_flow_data + 8);
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_compare_ne_right i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_compare_ult_left(p,index,live,&out.value); expected=((uint64_t)(uintptr_t)address_flow_data + 8) < ((uint64_t)(uintptr_t)p);
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_compare_ult_left i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_compare_ult_right(p,index,live,&out.value); expected=((uint64_t)(uintptr_t)p) < ((uint64_t)(uintptr_t)address_flow_data + 8);
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_compare_ult_right i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_compare_ule_left(p,index,live,&out.value); expected=((uint64_t)(uintptr_t)address_flow_data + 8) <= ((uint64_t)(uintptr_t)p);
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_compare_ule_left i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_compare_ule_right(p,index,live,&out.value); expected=((uint64_t)(uintptr_t)p) <= ((uint64_t)(uintptr_t)address_flow_data + 8);
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_compare_ule_right i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_compare_ugt_left(p,index,live,&out.value); expected=((uint64_t)(uintptr_t)address_flow_data + 8) > ((uint64_t)(uintptr_t)p);
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_compare_ugt_left i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_compare_ugt_right(p,index,live,&out.value); expected=((uint64_t)(uintptr_t)p) > ((uint64_t)(uintptr_t)address_flow_data + 8);
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_compare_ugt_right i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_compare_uge_left(p,index,live,&out.value); expected=((uint64_t)(uintptr_t)address_flow_data + 8) >= ((uint64_t)(uintptr_t)p);
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_compare_uge_left i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_compare_uge_right(p,index,live,&out.value); expected=((uint64_t)(uintptr_t)p) >= ((uint64_t)(uintptr_t)address_flow_data + 8);
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_compare_uge_right i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_frame_8_memset(p,index,live,&out.value); expected=UINT64_C(170);
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_frame_8_memset i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_frame_8_memcpy(p,index,live,&out.value); expected=(input & UINT64_C(255));
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_frame_8_memcpy i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_frame_16_memset(p,index,live,&out.value); expected=UINT64_C(43690);
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_frame_16_memset i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_frame_16_memcpy(p,index,live,&out.value); expected=(input & UINT64_C(65535));
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_frame_16_memcpy i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_frame_32_memset(p,index,live,&out.value); expected=UINT64_C(2863311530);
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_frame_32_memset i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_frame_32_memcpy(p,index,live,&out.value); expected=(input & UINT64_C(4294967295));
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_frame_32_memcpy i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_frame_64_memset(p,index,live,&out.value); expected=UINT64_C(12297829382473034410);
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_frame_64_memset i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_frame_64_memcpy(p,index,live,&out.value); expected=(input & UINT64_C(18446744073709551615));
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_frame_64_memcpy i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_forward(p,index,live,&out.value); expected=index * 3 + live;
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_forward i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_forward_loop(p,index,live,&out.value); expected=(index & 7) * live;
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_forward_loop i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=address_flow_forward_diamond(p,index,live,&out.value); expected=((index & 1) ? (index + live + 7) : (index + live - 3)) ^ (index + live);
    if (got!=expected || out.value!=(live ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211)) { fprintf(stderr,"address_flow_forward_diamond i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
  }
  printf("address-flow observations=%u offsets=constants=frames=ordering=live=guards=preserved\n",observations);
  return 0;
}
