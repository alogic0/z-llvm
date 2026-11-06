#include <stdint.h>
#include <stdio.h>
#include <string.h>
typedef uint32_t V __attribute__((vector_size(16)));
extern V vector_abi_rotate(V);
extern V vector_abi_mix(V,V,uint64_t);
extern V vector_abi_pressure(V,V,V,V,V,V,V,V);
extern void vector_abi_sret(void *,V);
extern void vector_abi_nested(void *,V);
__attribute__((noinline)) V vector_abi_host(V a,V b,uint64_t tag) {
    V result;
    for(unsigned j=0;j<4;++j) result[j]=(a[j]^b[j])+(uint32_t)(tag>>(j*8));
    __asm__ volatile("pxor %%xmm0,%%xmm0; pxor %%xmm1,%%xmm1; pxor %%xmm2,%%xmm2; pxor %%xmm3,%%xmm3; pxor %%xmm4,%%xmm4; pxor %%xmm5,%%xmm5; pxor %%xmm6,%%xmm6; pxor %%xmm7,%%xmm7; xor %%eax,%%eax; xor %%ecx,%%ecx; xor %%edx,%%edx; xor %%edi,%%edi; xor %%esi,%%esi; xor %%r8d,%%r8d; xor %%r9d,%%r9d"
    :::"xmm0","xmm1","xmm2","xmm3","xmm4","xmm5","xmm6","xmm7","rax","rcx","rdx","rdi","rsi","r8","r9","cc");
    return result;
}
static uint64_t next(uint64_t *s) { *s^=*s<<13; *s^=*s>>7; *s^=*s<<17; return *s; }
static int equal(V actual,V expected,unsigned test,unsigned i) {
    for(unsigned j=0;j<4;++j) if(actual[j]!=expected[j]) { fprintf(stderr,"vector ABI test=%u case=%u lane=%u actual=%x expected=%x\n",test,i,j,actual[j],expected[j]); return 0; }
    return 1;
}
int main(void) {
    unsigned observations=0;
    uint64_t state=UINT64_C(0x71f3b9836d5ca209);
    for(unsigned i=0;i<512;++i) {
        V v[8],expected,rotated;
        for(unsigned k=0;k<8;++k) for(unsigned j=0;j<4;++j) v[k][j]=(uint32_t)next(&state);
        if(i<8) for(unsigned j=0;j<4;++j) v[0][j]=(j&1)?0x7ff00000u+i:i;
        uint64_t tag=next(&state);
        for(unsigned j=0;j<4;++j) rotated[j]=(v[0][j]<<7)|(v[0][j]>>25);
        if(!equal(vector_abi_rotate(v[0]),rotated,0,i)) return 1;
        ++observations;
        for(unsigned j=0;j<4;++j) expected[j]=(rotated[j]+(uint32_t)(tag>>(j*8)))+rotated[j];
        if(!equal(vector_abi_mix(v[0],v[1],tag),expected,1,i)) return 2;
        ++observations;
        for(unsigned j=0;j<4;++j) {
            uint32_t x=(v[1][j]^v[0][j])+(uint32_t)(UINT64_C(123)>>(j*8));
            expected[j]=(((((x+v[0][j])^v[2][j])+v[3][j])^v[4][j])+v[5][j])^v[6][j];
            expected[j]+=v[7][j];
        }
        if(!equal(vector_abi_pressure(v[0],v[1],v[2],v[3],v[4],v[5],v[6],v[7]),expected,2,i)) return 3;
        ++observations;
        _Alignas(16) unsigned char output[96],wanted[96];
        V rows[4]; rows[0]=v[0];
        for(unsigned j=0;j<4;++j) { rows[1][j]=v[0][j]+j+1; rows[2][j]=v[0][j]^(uint32_t)(-1-(int)j); rows[3][j]=0u-j-1; }
        memset(wanted,0x5a,sizeof wanted); memcpy(wanted+16,rows,64);
        memset(output,0x5a,sizeof output); vector_abi_sret(output+16,v[0]);
        if(memcmp(output,wanted,sizeof output)) return 4;
        ++observations;
        memset(output,0x5a,sizeof output); vector_abi_nested(output+16,v[0]);
        if(memcmp(output,wanted,sizeof output)) return 5;
        ++observations;
    }
    printf("vector-abi observations=%u xmm=128 arguments=1-8 calls=preserved storage=checked\n",observations);
    return 0;
}
