extern unsigned char atomic_pointer_storage[128];
__attribute__((noinline)) void complete_atomic_snapshot(void *out){memcpy(out,atomic_pointer_storage,128);}
__attribute__((noinline)) void complete_atomic_touch(void *p){if(p!=atomic_pointer_storage+96)abort();__asm__ volatile(""::"r"(p):"memory");}
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected_input,unsigned char *gold){
    (void)expected_input;unsigned op=item->kind/16,success=(item->kind/8)%2,offset=(item->kind/4)%2?64:16,bits=item->bits?item->bits:64;size_t bytes=bits/8;
    uint64_t mask=bits==64?UINT64_MAX:(UINT64_C(1)<<bits)-1,sign=UINT64_C(1)<<(bits-1),edges[]={0,1,sign-1,sign,mask-1,mask,UINT64_C(0xa55a12348765dead),UINT64_MAX};
    uint64_t initial=edges[seed%8]&mask,desired=edges[(seed/8+3)%8]&mask,expected=success?initial:initial^1;
    if(!item->bits){initial=(uintptr_t)(atomic_pointer_storage+(op==9&&!success?112:96));expected=(uintptr_t)(atomic_pointer_storage+96);desired=(uintptr_t)(atomic_pointer_storage+112);}
    memcpy(input,&initial,8);memcpy(input+8,&expected,8);memcpy(input+16,&desired,8);
    memset(atomic_pointer_storage,0xa5,128);memcpy(atomic_pointer_storage+offset,&initial,bytes);memset(gold+24,0xa5,128);uint64_t next=initial,flag=0;
    switch(op){case 0:next=desired;break;case 1:next=initial+desired;break;case 2:next=initial-desired;break;case 3:next=initial&desired;break;case 4:next=initial|desired;break;case 5:next=initial^desired;break;case 6:next=~(initial&desired);break;case 7:next=initial<desired?initial:desired;break;case 8:next=initial>desired?initial:desired;break;case 9:flag=initial==expected;if(flag)next=desired;break;case 10:break;case 11:next=desired;break;default:abort();}
    next&=mask;uint64_t token=clobber_model(salt);memcpy(gold,&initial,8);memcpy(gold+8,&flag,8);memcpy(gold+16,&token,8);memcpy(gold+24+offset,&next,bytes);
    return (struct test_model){24,1,152,SIZE_MAX,255,initial^token};
}
