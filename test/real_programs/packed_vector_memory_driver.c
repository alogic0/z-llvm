#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#define DECL(N,B) extern uint64_t packed_memory_##N##_##B(const uint8_t*,uint8_t*,uint64_t);
DECL(3,1) DECL(8,3) DECL(7,9) DECL(5,17) DECL(3,33)
static unsigned bit(const uint8_t *p,unsigned n){return(p[n/8]>>(n%8))&1;}
int main(int argc,char **argv) {
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0;
    const unsigned counts[]={3,8,7,5,3},widths[]={1,3,9,17,33};
    uint64_t(*functions[])(const uint8_t*,uint8_t*,uint64_t)={packed_memory_3_1,packed_memory_8_3,packed_memory_7_9,packed_memory_5_17,packed_memory_3_33};
    size_t page=(size_t)sysconf(_SC_PAGESIZE);
    uint8_t *source_pages=mmap(0,2*page,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    uint8_t *output_pages=mmap(0,2*page,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(source_pages==MAP_FAILED||output_pages==MAP_FAILED||mprotect(source_pages+page,page,PROT_NONE)||mprotect(output_pages+page,page,PROT_NONE))return 2;
#define CHECK(C) do{observations++;if(!(C)){fprintf(stderr,"packed-vector-memory fault=%u observation=%zu width=%u count=%u seed=%u guarded=%u\n",fault,observations,bits,count,seed,guarded);return 1;}}while(0)
    for(unsigned w=0;w<5;w++)for(unsigned seed=0;seed<32;seed++)for(unsigned guarded=0;guarded<2;guarded++) {
        unsigned count=counts[w],bits=widths[w],total=count*bits,bytes=(total+7)/8;
        uint8_t source[96],output[96];memset(output,0xa5,sizeof output);
        for(unsigned i=0;i<sizeof source;i++)source[i]=(uint8_t)(seed*73+i*131+255);
        uint8_t *input=guarded?source_pages+page-bytes:source+17,*out=guarded?output_pages+page-bytes:output+17;
        if(guarded){memcpy(input,source+17,bytes);memset(out-16,0xa5,bytes+16);}
        if(total%8)input[bytes-1]&=(1u<<(total%8))-1;uint8_t before[16];memcpy(before,input,bytes);uint64_t minimum=UINT64_MAX;
        for(unsigned lane=0;lane<count;lane++){uint64_t value=0;for(unsigned i=0;i<bits;i++)value|=(uint64_t)bit(input,lane*bits+i)<<i;if(value<minimum)minimum=value;}
        uint64_t live=UINT64_C(0x9e3779b97f4a7c15)*seed,got=functions[w](input,out,live);
        if(fault==1)got^=1;if(fault==2)out[-1]^=1;if(fault==3)out[bytes-1]^=1;
        CHECK(got==(minimum^live));
        for(unsigned byte=0;byte<bytes;byte++){unsigned mask=(byte+1==bytes&&total%8)?(1u<<(total%8))-1:255;CHECK((out[byte]&mask)==((unsigned)(~before[byte])&mask));}
        uint8_t guards[16];memset(guards,0xa5,16);CHECK(memcmp(out-16,guards,16)==0);
        if(!guarded)CHECK(memcmp(out+bytes,guards,16)==0);
        CHECK(memcmp(input,before,bytes)==0);
    }
    munmap(source_pages,2*page);munmap(output_pages,2*page);
    printf("packed-vector-memory observations=%zu odd-widths=exact-tails=guard-pages=canonical-padding=live-values=preserved\n",observations);return 0;
}
