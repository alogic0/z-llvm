#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#define DECLARE(name) extern uint64_t name(const void *,void *)
DECLARE(owned_vector_f16x8); DECLARE(owned_vector_f32x4); DECLARE(owned_vector_f64x2);
DECLARE(owned_vector_f32x3); DECLARE(owned_vector_f32x17);
static uint64_t checksum(const void *p,uint64_t bytes) {
    const unsigned char *data=p;uint64_t result=UINT64_C(0xcbf29ce484222325);
    for(uint64_t i=0;i<bytes;i++) result=(result^data[i])*UINT64_C(0x100000001b3);
    return result;
}
uint64_t owned_vector_touch(const void *p,uint64_t bytes) {
    uint64_t result=checksum(p,bytes);
    __asm__ volatile("movabs $0x1234567887654321, %%rcx\n\tpxor %%xmm0,%%xmm0\n\tpxor %%xmm1,%%xmm1\n\tpxor %%xmm2,%%xmm2\n\tpxor %%xmm3,%%xmm3" : "+a"(result) : : "rcx","xmm0","xmm1","xmm2","xmm3","cc","memory");
    return result;
}
int main(int argc,char **argv) {
    unsigned fault=argc>1 ? (unsigned)strtoul(argv[1],NULL,10):0;size_t observations=0;
#define CHECK(c) do {++observations;if(!(c)){fprintf(stderr,"floating-owned fault=%u observation=%zu\n",fault,observations);return 1;}} while(0)
    uint64_t (*functions[])(const void *,void *)={owned_vector_f16x8,owned_vector_f32x4,owned_vector_f64x2,owned_vector_f32x3,owned_vector_f32x17};
    const unsigned lanes[]={8,4,2,3,17},widths[]={2,4,8,4,4};
    size_t page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *mapping=mmap(NULL,page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(mapping==MAP_FAILED||mprotect(mapping+page,page,PROT_NONE)) return 2;
    for(unsigned f=0;f<5;f++) for(unsigned seed=0;seed<96;seed++) {
        const unsigned bytes=lanes[f]*widths[f];unsigned char saved[128];
        unsigned char *input=mapping+page-bytes;
        struct {unsigned char pre[16],data[128],post[16];} out;memset(&out,0xa5,sizeof out);
        for(unsigned i=0;i<bytes;i++) input[i]=(unsigned char)(seed*71+i*29);
        memcpy(saved,input,bytes);
        uint64_t expected=checksum(input,bytes),got=functions[f](input,out.data);
        if(fault==1) got^=1;if(fault==2) out.pre[0]^=1;if(fault==3) out.post[0]^=1;
        CHECK(got==expected);CHECK(memcmp(input,saved,bytes)==0);
        unsigned prefix=1,tail=1;
        for(unsigned i=0;i<16;i++){prefix&=out.pre[i]==0xa5;tail&=out.post[i]==0xa5;}
        for(unsigned i=bytes;i<128;i++) tail&=out.data[i]==0xa5;
        CHECK(prefix);CHECK(tail);
        for(unsigned i=0;i<bytes;i++) CHECK(out.data[i]==(i%widths[f]==widths[f]-1 ? input[i]&0x7f:input[i]));
    }
    munmap(mapping,page*2);
    printf("floating-owned observations=%zu payloads=owned-storage=call-live=exact-memory=guards=preserved\n",observations);
    return 0;
}
