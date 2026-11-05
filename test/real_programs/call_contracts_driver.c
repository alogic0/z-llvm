#include <stdint.h>
#include <stdarg.h>
#include <stdio.h>
#include <inttypes.h>
static unsigned calls;
static void clobber_registers(void) {
  __asm__ volatile ("xor %%eax, %%eax; xor %%ecx, %%ecx; xor %%edx, %%edx; xor %%esi, %%esi; xor %%edi, %%edi; xor %%r8d, %%r8d; xor %%r9d, %%r9d; xor %%r10d, %%r10d; xor %%r11d, %%r11d" ::: "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "cc");
}
uint64_t call_contracts_clobber(uint64_t value) { uint64_t result=value ^ UINT64_C(0xdeadbeef12345678); clobber_registers(); return result; }
uint64_t call_contracts_external(uint64_t value) { return value ^ UINT64_C(0x13579bdf2468ace0); }
uint64_t call_contracts_apply(uint64_t (*f)(uint64_t), uint64_t value) { return f(value); }
uint64_t call_contracts_alias(const uint64_t * restrict p, uint64_t * restrict q) { *q=*p ^ UINT64_C(0xabcdef0123456789); uint64_t result=*q; clobber_registers(); return result; }
uint64_t call_contracts_varargs_0_0_sink(void * x0, ...) {
  uint64_t result=0;
  result += (uint64_t)(uintptr_t)x0 * UINT64_C(1);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_0_1_sink(void * x0, ...) {
  uint64_t result=0;
  result += (uint64_t)(uintptr_t)x0 * UINT64_C(1);
  va_list ap; va_start(ap,x0);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(2);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_0_2_sink(void * x0, ...) {
  uint64_t result=0;
  result += (uint64_t)(uintptr_t)x0 * UINT64_C(1);
  va_list ap; va_start(ap,x0);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(2);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(3);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_0_5_sink(void * x0, ...) {
  uint64_t result=0;
  result += (uint64_t)(uintptr_t)x0 * UINT64_C(1);
  va_list ap; va_start(ap,x0);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(2);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(3);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(4);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(5);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(6);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_0_10_sink(void * x0, ...) {
  uint64_t result=0;
  result += (uint64_t)(uintptr_t)x0 * UINT64_C(1);
  va_list ap; va_start(ap,x0);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(2);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(3);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(4);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(5);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(6);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(7);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(8);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(9);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(10);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(11);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_1_0_sink(uint32_t x0, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_1_1_sink(uint32_t x0, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  va_list ap; va_start(ap,x0);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(2);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_1_2_sink(uint32_t x0, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  va_list ap; va_start(ap,x0);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(2);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(3);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_1_5_sink(uint32_t x0, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  va_list ap; va_start(ap,x0);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(2);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(3);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(4);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(5);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(6);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_1_10_sink(uint32_t x0, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  va_list ap; va_start(ap,x0);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(2);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(3);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(4);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(5);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(6);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(7);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(8);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(9);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(10);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(11);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_2_0_sink(uint64_t x0, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_2_1_sink(uint64_t x0, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  va_list ap; va_start(ap,x0);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(2);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_2_2_sink(uint64_t x0, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  va_list ap; va_start(ap,x0);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(2);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(3);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_2_5_sink(uint64_t x0, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  va_list ap; va_start(ap,x0);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(2);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(3);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(4);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(5);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(6);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_2_10_sink(uint64_t x0, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  va_list ap; va_start(ap,x0);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(2);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(3);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(4);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(5);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(6);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(7);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(8);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(9);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(10);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(11);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_3_0_sink(void * x0, uint32_t x1, ...) {
  uint64_t result=0;
  result += (uint64_t)(uintptr_t)x0 * UINT64_C(1);
  result += (uint64_t)x1 * UINT64_C(2);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_3_1_sink(void * x0, uint32_t x1, ...) {
  uint64_t result=0;
  result += (uint64_t)(uintptr_t)x0 * UINT64_C(1);
  result += (uint64_t)x1 * UINT64_C(2);
  va_list ap; va_start(ap,x1);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(3);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_3_2_sink(void * x0, uint32_t x1, ...) {
  uint64_t result=0;
  result += (uint64_t)(uintptr_t)x0 * UINT64_C(1);
  result += (uint64_t)x1 * UINT64_C(2);
  va_list ap; va_start(ap,x1);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(3);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(4);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_3_5_sink(void * x0, uint32_t x1, ...) {
  uint64_t result=0;
  result += (uint64_t)(uintptr_t)x0 * UINT64_C(1);
  result += (uint64_t)x1 * UINT64_C(2);
  va_list ap; va_start(ap,x1);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(3);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(4);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(5);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(6);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(7);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_3_10_sink(void * x0, uint32_t x1, ...) {
  uint64_t result=0;
  result += (uint64_t)(uintptr_t)x0 * UINT64_C(1);
  result += (uint64_t)x1 * UINT64_C(2);
  va_list ap; va_start(ap,x1);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(3);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(4);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(5);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(6);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(7);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(8);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(9);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(10);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(11);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(12);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_4_0_sink(uint32_t x0, void * x1, uint32_t x2, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  result += (uint64_t)(uintptr_t)x1 * UINT64_C(2);
  result += (uint64_t)x2 * UINT64_C(3);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_4_1_sink(uint32_t x0, void * x1, uint32_t x2, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  result += (uint64_t)(uintptr_t)x1 * UINT64_C(2);
  result += (uint64_t)x2 * UINT64_C(3);
  va_list ap; va_start(ap,x2);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(4);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_4_2_sink(uint32_t x0, void * x1, uint32_t x2, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  result += (uint64_t)(uintptr_t)x1 * UINT64_C(2);
  result += (uint64_t)x2 * UINT64_C(3);
  va_list ap; va_start(ap,x2);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(4);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(5);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_4_5_sink(uint32_t x0, void * x1, uint32_t x2, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  result += (uint64_t)(uintptr_t)x1 * UINT64_C(2);
  result += (uint64_t)x2 * UINT64_C(3);
  va_list ap; va_start(ap,x2);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(4);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(5);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(6);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(7);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(8);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_4_10_sink(uint32_t x0, void * x1, uint32_t x2, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  result += (uint64_t)(uintptr_t)x1 * UINT64_C(2);
  result += (uint64_t)x2 * UINT64_C(3);
  va_list ap; va_start(ap,x2);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(4);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(5);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(6);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(7);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(8);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(9);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(10);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(11);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(12);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(13);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_5_0_sink(void * x0, uint64_t x1, uint64_t x2, uint32_t x3, ...) {
  uint64_t result=0;
  result += (uint64_t)(uintptr_t)x0 * UINT64_C(1);
  result += (uint64_t)x1 * UINT64_C(2);
  result += (uint64_t)x2 * UINT64_C(3);
  result += (uint64_t)x3 * UINT64_C(4);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_5_1_sink(void * x0, uint64_t x1, uint64_t x2, uint32_t x3, ...) {
  uint64_t result=0;
  result += (uint64_t)(uintptr_t)x0 * UINT64_C(1);
  result += (uint64_t)x1 * UINT64_C(2);
  result += (uint64_t)x2 * UINT64_C(3);
  result += (uint64_t)x3 * UINT64_C(4);
  va_list ap; va_start(ap,x3);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(5);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_5_2_sink(void * x0, uint64_t x1, uint64_t x2, uint32_t x3, ...) {
  uint64_t result=0;
  result += (uint64_t)(uintptr_t)x0 * UINT64_C(1);
  result += (uint64_t)x1 * UINT64_C(2);
  result += (uint64_t)x2 * UINT64_C(3);
  result += (uint64_t)x3 * UINT64_C(4);
  va_list ap; va_start(ap,x3);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(5);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(6);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_5_5_sink(void * x0, uint64_t x1, uint64_t x2, uint32_t x3, ...) {
  uint64_t result=0;
  result += (uint64_t)(uintptr_t)x0 * UINT64_C(1);
  result += (uint64_t)x1 * UINT64_C(2);
  result += (uint64_t)x2 * UINT64_C(3);
  result += (uint64_t)x3 * UINT64_C(4);
  va_list ap; va_start(ap,x3);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(5);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(6);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(7);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(8);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(9);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_5_10_sink(void * x0, uint64_t x1, uint64_t x2, uint32_t x3, ...) {
  uint64_t result=0;
  result += (uint64_t)(uintptr_t)x0 * UINT64_C(1);
  result += (uint64_t)x1 * UINT64_C(2);
  result += (uint64_t)x2 * UINT64_C(3);
  result += (uint64_t)x3 * UINT64_C(4);
  va_list ap; va_start(ap,x3);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(5);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(6);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(7);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(8);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(9);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(10);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(11);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(12);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(13);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(14);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_6_0_sink(uint64_t x0, void * x1, uint32_t x2, uint64_t x3, uint32_t x4, void * x5, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  result += (uint64_t)(uintptr_t)x1 * UINT64_C(2);
  result += (uint64_t)x2 * UINT64_C(3);
  result += (uint64_t)x3 * UINT64_C(4);
  result += (uint64_t)x4 * UINT64_C(5);
  result += (uint64_t)(uintptr_t)x5 * UINT64_C(6);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_6_1_sink(uint64_t x0, void * x1, uint32_t x2, uint64_t x3, uint32_t x4, void * x5, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  result += (uint64_t)(uintptr_t)x1 * UINT64_C(2);
  result += (uint64_t)x2 * UINT64_C(3);
  result += (uint64_t)x3 * UINT64_C(4);
  result += (uint64_t)x4 * UINT64_C(5);
  result += (uint64_t)(uintptr_t)x5 * UINT64_C(6);
  va_list ap; va_start(ap,x5);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(7);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_6_2_sink(uint64_t x0, void * x1, uint32_t x2, uint64_t x3, uint32_t x4, void * x5, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  result += (uint64_t)(uintptr_t)x1 * UINT64_C(2);
  result += (uint64_t)x2 * UINT64_C(3);
  result += (uint64_t)x3 * UINT64_C(4);
  result += (uint64_t)x4 * UINT64_C(5);
  result += (uint64_t)(uintptr_t)x5 * UINT64_C(6);
  va_list ap; va_start(ap,x5);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(7);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(8);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_6_5_sink(uint64_t x0, void * x1, uint32_t x2, uint64_t x3, uint32_t x4, void * x5, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  result += (uint64_t)(uintptr_t)x1 * UINT64_C(2);
  result += (uint64_t)x2 * UINT64_C(3);
  result += (uint64_t)x3 * UINT64_C(4);
  result += (uint64_t)x4 * UINT64_C(5);
  result += (uint64_t)(uintptr_t)x5 * UINT64_C(6);
  va_list ap; va_start(ap,x5);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(7);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(8);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(9);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(10);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(11);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint64_t call_contracts_varargs_6_10_sink(uint64_t x0, void * x1, uint32_t x2, uint64_t x3, uint32_t x4, void * x5, ...) {
  uint64_t result=0;
  result += (uint64_t)x0 * UINT64_C(1);
  result += (uint64_t)(uintptr_t)x1 * UINT64_C(2);
  result += (uint64_t)x2 * UINT64_C(3);
  result += (uint64_t)x3 * UINT64_C(4);
  result += (uint64_t)x4 * UINT64_C(5);
  result += (uint64_t)(uintptr_t)x5 * UINT64_C(6);
  va_list ap; va_start(ap,x5);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(7);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(8);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(9);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(10);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(11);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(12);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(13);
  result += (uint64_t)va_arg(ap,uint64_t) * UINT64_C(14);
  result += (uint64_t)(uintptr_t)va_arg(ap,void *) * UINT64_C(15);
  result += (uint64_t)va_arg(ap,uint32_t) * UINT64_C(16);
  va_end(ap);
  calls++; clobber_registers(); return result;
}
uint32_t call_contracts_return_i32_sink(uint32_t first, ...) { va_list ap; va_start(ap,first); uint32_t value=va_arg(ap,uint32_t); va_end(ap); calls++; clobber_registers(); return value; }
void * call_contracts_return_ptr_sink(uint32_t first, ...) { va_list ap; va_start(ap,first); void * value=va_arg(ap,void *); va_end(ap); calls++; clobber_registers(); return value; }
void call_contracts_return_void_sink(uint32_t first, ...) { va_list ap; va_start(ap,first); uint64_t value=va_arg(ap,uint64_t); va_end(ap); calls++; clobber_registers(); (void)value; }
extern uint64_t call_contracts_varargs_0_0(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_0_1(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_0_2(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_0_5(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_0_10(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_1_0(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_1_1(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_1_2(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_1_5(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_1_10(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_2_0(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_2_1(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_2_2(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_2_5(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_2_10(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_3_0(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_3_1(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_3_2(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_3_5(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_3_10(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_4_0(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_4_1(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_4_2(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_4_5(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_4_10(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_5_0(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_5_1(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_5_2(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_5_5(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_5_10(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_6_0(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_6_1(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_6_2(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_6_5(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_varargs_6_10(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_return_i32(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_return_ptr(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_return_void(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_advisory_0(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_advisory_1(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_advisory_2(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_address_local(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_address_external(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_address_select(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_address_phi(void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t call_contracts_address_store(void *, uint64_t, uint64_t, uint64_t *);
int main(void) {
  static const uint64_t values[] = {0, 1, 2, 255, UINT32_MAX, UINT64_C(0x8000000000000000), UINT64_C(0xdeadbeef01234567), UINT64_MAX};
  unsigned observations=0;
  for (unsigned i=0;i<8;i++) for (unsigned j=0;j<8;j++) {
    uint64_t a=values[i], b=values[j], input=a ^ b; void *p=&input;
    struct { uint64_t before, value, after; } out={UINT64_C(0x1122334455667788),0,UINT64_C(0x8877665544332211)};
    uint64_t got, expected;
    got=call_contracts_varargs_0_0(p,a,b,&out.value); expected=(((uint64_t)(uintptr_t)p) * UINT64_C(1));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_0_0 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_0_1(p,a,b,&out.value); expected=(((uint64_t)(uintptr_t)p) * UINT64_C(1)) + (((uint32_t)a) * UINT64_C(2));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_0_1 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_0_2(p,a,b,&out.value); expected=(((uint64_t)(uintptr_t)p) * UINT64_C(1)) + (((uint32_t)a) * UINT64_C(2)) + ((b) * UINT64_C(3));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_0_2 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_0_5(p,a,b,&out.value); expected=(((uint64_t)(uintptr_t)p) * UINT64_C(1)) + (((uint32_t)a) * UINT64_C(2)) + ((b) * UINT64_C(3)) + (((uint64_t)(uintptr_t)p) * UINT64_C(4)) + (((uint32_t)a) * UINT64_C(5)) + ((a) * UINT64_C(6));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_0_5 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_0_10(p,a,b,&out.value); expected=(((uint64_t)(uintptr_t)p) * UINT64_C(1)) + (((uint32_t)a) * UINT64_C(2)) + ((b) * UINT64_C(3)) + (((uint64_t)(uintptr_t)p) * UINT64_C(4)) + (((uint32_t)a) * UINT64_C(5)) + ((a) * UINT64_C(6)) + (((uint64_t)(uintptr_t)p) * UINT64_C(7)) + (((uint32_t)a) * UINT64_C(8)) + ((b) * UINT64_C(9)) + (((uint64_t)(uintptr_t)p) * UINT64_C(10)) + (((uint32_t)a) * UINT64_C(11));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_0_10 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_1_0(p,a,b,&out.value); expected=(((uint32_t)a) * UINT64_C(1));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_1_0 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_1_1(p,a,b,&out.value); expected=(((uint32_t)a) * UINT64_C(1)) + (((uint32_t)a) * UINT64_C(2));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_1_1 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_1_2(p,a,b,&out.value); expected=(((uint32_t)a) * UINT64_C(1)) + (((uint32_t)a) * UINT64_C(2)) + ((b) * UINT64_C(3));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_1_2 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_1_5(p,a,b,&out.value); expected=(((uint32_t)a) * UINT64_C(1)) + (((uint32_t)a) * UINT64_C(2)) + ((b) * UINT64_C(3)) + (((uint64_t)(uintptr_t)p) * UINT64_C(4)) + (((uint32_t)a) * UINT64_C(5)) + ((a) * UINT64_C(6));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_1_5 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_1_10(p,a,b,&out.value); expected=(((uint32_t)a) * UINT64_C(1)) + (((uint32_t)a) * UINT64_C(2)) + ((b) * UINT64_C(3)) + (((uint64_t)(uintptr_t)p) * UINT64_C(4)) + (((uint32_t)a) * UINT64_C(5)) + ((a) * UINT64_C(6)) + (((uint64_t)(uintptr_t)p) * UINT64_C(7)) + (((uint32_t)a) * UINT64_C(8)) + ((b) * UINT64_C(9)) + (((uint64_t)(uintptr_t)p) * UINT64_C(10)) + (((uint32_t)a) * UINT64_C(11));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_1_10 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_2_0(p,a,b,&out.value); expected=((b) * UINT64_C(1));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_2_0 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_2_1(p,a,b,&out.value); expected=((b) * UINT64_C(1)) + (((uint32_t)a) * UINT64_C(2));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_2_1 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_2_2(p,a,b,&out.value); expected=((b) * UINT64_C(1)) + (((uint32_t)a) * UINT64_C(2)) + ((b) * UINT64_C(3));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_2_2 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_2_5(p,a,b,&out.value); expected=((b) * UINT64_C(1)) + (((uint32_t)a) * UINT64_C(2)) + ((b) * UINT64_C(3)) + (((uint64_t)(uintptr_t)p) * UINT64_C(4)) + (((uint32_t)a) * UINT64_C(5)) + ((a) * UINT64_C(6));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_2_5 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_2_10(p,a,b,&out.value); expected=((b) * UINT64_C(1)) + (((uint32_t)a) * UINT64_C(2)) + ((b) * UINT64_C(3)) + (((uint64_t)(uintptr_t)p) * UINT64_C(4)) + (((uint32_t)a) * UINT64_C(5)) + ((a) * UINT64_C(6)) + (((uint64_t)(uintptr_t)p) * UINT64_C(7)) + (((uint32_t)a) * UINT64_C(8)) + ((b) * UINT64_C(9)) + (((uint64_t)(uintptr_t)p) * UINT64_C(10)) + (((uint32_t)a) * UINT64_C(11));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_2_10 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_3_0(p,a,b,&out.value); expected=(((uint64_t)(uintptr_t)p) * UINT64_C(1)) + (((uint32_t)a) * UINT64_C(2));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_3_0 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_3_1(p,a,b,&out.value); expected=(((uint64_t)(uintptr_t)p) * UINT64_C(1)) + (((uint32_t)a) * UINT64_C(2)) + (((uint32_t)a) * UINT64_C(3));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_3_1 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_3_2(p,a,b,&out.value); expected=(((uint64_t)(uintptr_t)p) * UINT64_C(1)) + (((uint32_t)a) * UINT64_C(2)) + (((uint32_t)a) * UINT64_C(3)) + ((a) * UINT64_C(4));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_3_2 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_3_5(p,a,b,&out.value); expected=(((uint64_t)(uintptr_t)p) * UINT64_C(1)) + (((uint32_t)a) * UINT64_C(2)) + (((uint32_t)a) * UINT64_C(3)) + ((a) * UINT64_C(4)) + (((uint64_t)(uintptr_t)p) * UINT64_C(5)) + (((uint32_t)a) * UINT64_C(6)) + ((b) * UINT64_C(7));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_3_5 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_3_10(p,a,b,&out.value); expected=(((uint64_t)(uintptr_t)p) * UINT64_C(1)) + (((uint32_t)a) * UINT64_C(2)) + (((uint32_t)a) * UINT64_C(3)) + ((a) * UINT64_C(4)) + (((uint64_t)(uintptr_t)p) * UINT64_C(5)) + (((uint32_t)a) * UINT64_C(6)) + ((b) * UINT64_C(7)) + (((uint64_t)(uintptr_t)p) * UINT64_C(8)) + (((uint32_t)a) * UINT64_C(9)) + ((a) * UINT64_C(10)) + (((uint64_t)(uintptr_t)p) * UINT64_C(11)) + (((uint32_t)a) * UINT64_C(12));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_3_10 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_4_0(p,a,b,&out.value); expected=(((uint32_t)a) * UINT64_C(1)) + (((uint64_t)(uintptr_t)p) * UINT64_C(2)) + (((uint32_t)a) * UINT64_C(3));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_4_0 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_4_1(p,a,b,&out.value); expected=(((uint32_t)a) * UINT64_C(1)) + (((uint64_t)(uintptr_t)p) * UINT64_C(2)) + (((uint32_t)a) * UINT64_C(3)) + (((uint32_t)a) * UINT64_C(4));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_4_1 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_4_2(p,a,b,&out.value); expected=(((uint32_t)a) * UINT64_C(1)) + (((uint64_t)(uintptr_t)p) * UINT64_C(2)) + (((uint32_t)a) * UINT64_C(3)) + (((uint32_t)a) * UINT64_C(4)) + ((b) * UINT64_C(5));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_4_2 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_4_5(p,a,b,&out.value); expected=(((uint32_t)a) * UINT64_C(1)) + (((uint64_t)(uintptr_t)p) * UINT64_C(2)) + (((uint32_t)a) * UINT64_C(3)) + (((uint32_t)a) * UINT64_C(4)) + ((b) * UINT64_C(5)) + (((uint64_t)(uintptr_t)p) * UINT64_C(6)) + (((uint32_t)a) * UINT64_C(7)) + ((a) * UINT64_C(8));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_4_5 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_4_10(p,a,b,&out.value); expected=(((uint32_t)a) * UINT64_C(1)) + (((uint64_t)(uintptr_t)p) * UINT64_C(2)) + (((uint32_t)a) * UINT64_C(3)) + (((uint32_t)a) * UINT64_C(4)) + ((b) * UINT64_C(5)) + (((uint64_t)(uintptr_t)p) * UINT64_C(6)) + (((uint32_t)a) * UINT64_C(7)) + ((a) * UINT64_C(8)) + (((uint64_t)(uintptr_t)p) * UINT64_C(9)) + (((uint32_t)a) * UINT64_C(10)) + ((b) * UINT64_C(11)) + (((uint64_t)(uintptr_t)p) * UINT64_C(12)) + (((uint32_t)a) * UINT64_C(13));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_4_10 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_5_0(p,a,b,&out.value); expected=(((uint64_t)(uintptr_t)p) * UINT64_C(1)) + ((a) * UINT64_C(2)) + ((b) * UINT64_C(3)) + (((uint32_t)a) * UINT64_C(4));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_5_0 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_5_1(p,a,b,&out.value); expected=(((uint64_t)(uintptr_t)p) * UINT64_C(1)) + ((a) * UINT64_C(2)) + ((b) * UINT64_C(3)) + (((uint32_t)a) * UINT64_C(4)) + (((uint32_t)a) * UINT64_C(5));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_5_1 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_5_2(p,a,b,&out.value); expected=(((uint64_t)(uintptr_t)p) * UINT64_C(1)) + ((a) * UINT64_C(2)) + ((b) * UINT64_C(3)) + (((uint32_t)a) * UINT64_C(4)) + (((uint32_t)a) * UINT64_C(5)) + ((a) * UINT64_C(6));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_5_2 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_5_5(p,a,b,&out.value); expected=(((uint64_t)(uintptr_t)p) * UINT64_C(1)) + ((a) * UINT64_C(2)) + ((b) * UINT64_C(3)) + (((uint32_t)a) * UINT64_C(4)) + (((uint32_t)a) * UINT64_C(5)) + ((a) * UINT64_C(6)) + (((uint64_t)(uintptr_t)p) * UINT64_C(7)) + (((uint32_t)a) * UINT64_C(8)) + ((b) * UINT64_C(9));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_5_5 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_5_10(p,a,b,&out.value); expected=(((uint64_t)(uintptr_t)p) * UINT64_C(1)) + ((a) * UINT64_C(2)) + ((b) * UINT64_C(3)) + (((uint32_t)a) * UINT64_C(4)) + (((uint32_t)a) * UINT64_C(5)) + ((a) * UINT64_C(6)) + (((uint64_t)(uintptr_t)p) * UINT64_C(7)) + (((uint32_t)a) * UINT64_C(8)) + ((b) * UINT64_C(9)) + (((uint64_t)(uintptr_t)p) * UINT64_C(10)) + (((uint32_t)a) * UINT64_C(11)) + ((a) * UINT64_C(12)) + (((uint64_t)(uintptr_t)p) * UINT64_C(13)) + (((uint32_t)a) * UINT64_C(14));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_5_10 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_6_0(p,a,b,&out.value); expected=((b) * UINT64_C(1)) + (((uint64_t)(uintptr_t)p) * UINT64_C(2)) + (((uint32_t)a) * UINT64_C(3)) + ((a) * UINT64_C(4)) + (((uint32_t)a) * UINT64_C(5)) + (((uint64_t)(uintptr_t)p) * UINT64_C(6));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_6_0 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_6_1(p,a,b,&out.value); expected=((b) * UINT64_C(1)) + (((uint64_t)(uintptr_t)p) * UINT64_C(2)) + (((uint32_t)a) * UINT64_C(3)) + ((a) * UINT64_C(4)) + (((uint32_t)a) * UINT64_C(5)) + (((uint64_t)(uintptr_t)p) * UINT64_C(6)) + (((uint32_t)a) * UINT64_C(7));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_6_1 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_6_2(p,a,b,&out.value); expected=((b) * UINT64_C(1)) + (((uint64_t)(uintptr_t)p) * UINT64_C(2)) + (((uint32_t)a) * UINT64_C(3)) + ((a) * UINT64_C(4)) + (((uint32_t)a) * UINT64_C(5)) + (((uint64_t)(uintptr_t)p) * UINT64_C(6)) + (((uint32_t)a) * UINT64_C(7)) + ((a) * UINT64_C(8));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_6_2 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_6_5(p,a,b,&out.value); expected=((b) * UINT64_C(1)) + (((uint64_t)(uintptr_t)p) * UINT64_C(2)) + (((uint32_t)a) * UINT64_C(3)) + ((a) * UINT64_C(4)) + (((uint32_t)a) * UINT64_C(5)) + (((uint64_t)(uintptr_t)p) * UINT64_C(6)) + (((uint32_t)a) * UINT64_C(7)) + ((a) * UINT64_C(8)) + (((uint64_t)(uintptr_t)p) * UINT64_C(9)) + (((uint32_t)a) * UINT64_C(10)) + ((b) * UINT64_C(11));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_6_5 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_varargs_6_10(p,a,b,&out.value); expected=((b) * UINT64_C(1)) + (((uint64_t)(uintptr_t)p) * UINT64_C(2)) + (((uint32_t)a) * UINT64_C(3)) + ((a) * UINT64_C(4)) + (((uint32_t)a) * UINT64_C(5)) + (((uint64_t)(uintptr_t)p) * UINT64_C(6)) + (((uint32_t)a) * UINT64_C(7)) + ((a) * UINT64_C(8)) + (((uint64_t)(uintptr_t)p) * UINT64_C(9)) + (((uint32_t)a) * UINT64_C(10)) + ((b) * UINT64_C(11)) + (((uint64_t)(uintptr_t)p) * UINT64_C(12)) + (((uint32_t)a) * UINT64_C(13)) + ((a) * UINT64_C(14)) + (((uint64_t)(uintptr_t)p) * UINT64_C(15)) + (((uint32_t)a) * UINT64_C(16));
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_varargs_6_10 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_return_i32(p,a,b,&out.value); expected=(uint32_t)a;
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_return_i32 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_return_ptr(p,a,b,&out.value); expected=(uint64_t)(uintptr_t)p;
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_return_ptr i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_return_void(p,a,b,&out.value); expected=a;
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_return_void i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_advisory_0(p,a,b,&out.value); expected=input ^ UINT64_C(0xabcdef0123456789);
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_advisory_0 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_advisory_1(p,a,b,&out.value); expected=input ^ UINT64_C(0xabcdef0123456789);
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_advisory_1 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_advisory_2(p,a,b,&out.value); expected=input ^ UINT64_C(0xabcdef0123456789);
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_advisory_2 i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_address_local(p,a,b,&out.value); expected=a + UINT64_C(19);
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_address_local i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_address_external(p,a,b,&out.value); expected=a ^ UINT64_C(0x13579bdf2468ace0);
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_address_external i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_address_select(p,a,b,&out.value); expected=(a & 1) ? a + UINT64_C(19) : a ^ UINT64_C(0x5a5a5a5a5a5a5a5a);
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_address_select i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_address_phi(p,a,b,&out.value); expected=(a & 1) ? a + UINT64_C(19) : a ^ UINT64_C(0x5a5a5a5a5a5a5a5a);
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_address_phi i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
    got=call_contracts_address_store(p,a,b,&out.value); expected=a ^ UINT64_C(0x13579bdf2468ace0);
    if (got!=expected || out.value!=(b ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0x1122334455667788) || out.after!=UINT64_C(0x8877665544332211) || input!=(a^b)) { fprintf(stderr,"call_contracts_address_store i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 "\n",i,j,got,expected); return 1; }
    observations++;
  }
  if (calls != 2432) return 2;
  printf("call-contracts observations=%u varargs=attributes=functions=live=guards=preserved\n",observations);
  return 0;
}
