#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#define DECLARE(r,l) extern uint64_t prefetch_data_##r##_##l(uint64_t,void *,const void *,const void *)
DECLARE(0,0);DECLARE(0,1);DECLARE(0,2);DECLARE(0,3);DECLARE(1,0);DECLARE(1,1);DECLARE(1,2);DECLARE(1,3);
int main(int argc,char **argv) {
    unsigned fault=argc>1 ? (unsigned)strtoul(argv[1],NULL,10):0;size_t observations=0;
#define CHECK(c) do {++observations;if(!(c)){fprintf(stderr,"prefetch-hints fault=%u observation=%zu\n",fault,observations);return 1;}} while(0)
    uint64_t (*functions[])(uint64_t,void *,const void *,const void *)={prefetch_data_0_0,prefetch_data_0_1,prefetch_data_0_2,prefetch_data_0_3,prefetch_data_1_0,prefetch_data_1_1,prefetch_data_1_2,prefetch_data_1_3};
    size_t page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *bad=mmap(NULL,page,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(bad==MAP_FAILED) return 2;
    const uint64_t values[]={0,1,UINT64_MAX,UINT64_C(0x8000000000000000),UINT64_C(0x123456789abcdef0),17,63,65535};
    for(unsigned f=0;f<8;f++) for(unsigned seed=0;seed<8;seed++) for(unsigned kind=0;kind<4;kind++) {
        unsigned char input[32],out[32];memset(input,0x5a,sizeof input);memset(out,0xa5,sizeof out);
        const void *address=kind==0 ? input+1:kind==1 ? NULL:kind==2 ? bad:bad+128;
        uint64_t got=functions[f](values[seed],out+9,address,bad),stored;
        memcpy(&stored,out+9,8);
        if(fault==1) got^=1;if(fault==2) out[0]^=1;if(fault==3) out[31]^=1;
        CHECK(got==(values[seed]^UINT64_C(19088743)));CHECK(stored==values[seed]+17);
        unsigned prefix=1,tail=1,unchanged=1;
        for(unsigned i=0;i<9;i++) prefix&=out[i]==0xa5;
        for(unsigned i=17;i<32;i++) tail&=out[i]==0xa5;
        for(unsigned i=0;i<32;i++) unchanged&=input[i]==0x5a;
        CHECK(prefix);CHECK(tail);CHECK(unchanged);
    }
    munmap(bad,page);
    printf("prefetch-hints observations=%zu live-values=exact-stores=nonfaulting-addresses=guards=preserved\n",observations);return 0;
}
