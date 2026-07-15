/* x86_64 SysV ABI probe used by both INBOX-60 executables. */

        .bss
        .p2align 3
probe_expected_rsp:
        .quad 0
probe_pre_status:
        .quad 0

        .text

        .macro PROLOGUE outreg
        pushq %rbp
        pushq %rbx
        pushq %r12
        pushq %r13
        pushq %r14
        pushq %r15
        subq $72, %rsp
        movq \outreg, 16(%rsp)
        movabsq $0x6b5a4938271605f4, %r10
        movq %r10, 0(%rsp)
        movabsq $0xf405162738495a6b, %r10
        movq %r10, 8(%rsp)
        xorq %r10, %r10
        testq $15, %rsp
        jz 9001f
        orq $128, %r10
9001:
        movq %r10, probe_pre_status(%rip)
        movq %rsp, probe_expected_rsp(%rip)
        movabsq $0x1122334455667788, %rbx
        movabsq $0x8877665544332211, %rbp
        movabsq $0x1021324354657687, %r12
        movabsq $0x98a9bacbdcedfe0f, %r13
        movabsq $0x0f1e2d3c4b5a6978, %r14
        movabsq $0x89abcdef01234567, %r15
        cld
        .endm

        .macro POSTCHECK storekind
        xorq %r11, %r11
        movq probe_expected_rsp(%rip), %r10
        cmpq %r10, %rsp
        je 9002f
        orq $64, %r11
        movq %r10, %rsp
9002:
        orq probe_pre_status(%rip), %r11
        movq 16(%rsp), %r10
        .ifc \storekind,u64
        movq %rax, 0(%r10)
        movq %rax, 8(%r10)
        .endif
        .ifc \storekind,u128
        movq %rax, 0(%r10)
        movq %rdx, 8(%r10)
        .endif
        .ifc \storekind,f32
        movd %xmm0, 0(%r10)
        movq $0, 8(%r10)
        .endif
        .ifc \storekind,f64
        movq %xmm0, 0(%r10)
        movq $0, 8(%r10)
        .endif
        movabsq $0x1122334455667788, %r10
        cmpq %r10, %rbx
        je 9003f
        orq $1, %r11
9003:
        movabsq $0x8877665544332211, %r10
        cmpq %r10, %rbp
        je 9004f
        orq $2, %r11
9004:
        movabsq $0x1021324354657687, %r10
        cmpq %r10, %r12
        je 9005f
        orq $4, %r11
9005:
        movabsq $0x98a9bacbdcedfe0f, %r10
        cmpq %r10, %r13
        je 9006f
        orq $8, %r11
9006:
        movabsq $0x0f1e2d3c4b5a6978, %r10
        cmpq %r10, %r14
        je 9007f
        orq $16, %r11
9007:
        movabsq $0x89abcdef01234567, %r10
        cmpq %r10, %r15
        je 9008f
        orq $32, %r11
9008:
        pushfq
        popq %r10
        testq $0x400, %r10
        jz 9009f
        orq $1024, %r11
9009:
        cld
        movabsq $0x6b5a4938271605f4, %r10
        cmpq %r10, 0(%rsp)
        je 9010f
        orq $256, %r11
9010:
        movabsq $0xf405162738495a6b, %r10
        cmpq %r10, 8(%rsp)
        je 9011f
        orq $512, %r11
9011:
        movq %r11, %rax
        addq $72, %rsp
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbx
        popq %rbp
        ret
        .endm

        .macro WRAP1 name, target
        .globl \name
        .type \name,@function
\name:
        PROLOGUE %rsi
        call \target
        POSTCHECK u64
        .size \name,.-\name
        .endm

        WRAP1 probe_neg_u64, abi_neg_u64
        WRAP1 probe_identity_u8, abi_identity_u8
        WRAP1 probe_identity_i16, abi_identity_i16
        WRAP1 probe_load_u32, abi_load_u32
        WRAP1 probe_identity_ptr, abi_identity_ptr

        .globl probe_select_i32
        .type probe_select_i32,@function
probe_select_i32:
        PROLOGUE %rcx
        call abi_select_i32
        POSTCHECK u64
        .size probe_select_i32,.-probe_select_i32

        .globl probe_pointer_load_store
        .type probe_pointer_load_store,@function
probe_pointer_load_store:
        PROLOGUE %rdx
        call abi_pointer_load_store
        POSTCHECK u64
        .size probe_pointer_load_store,.-probe_pointer_load_store

        .globl probe_neg_u128
        .type probe_neg_u128,@function
probe_neg_u128:
        PROLOGUE %rdx
        call abi_neg_u128
        POSTCHECK u128
        .size probe_neg_u128,.-probe_neg_u128

        .globl probe_add_f32
        .type probe_add_f32,@function
probe_add_f32:
        PROLOGUE %rdi
        call abi_add_f32
        POSTCHECK f32
        .size probe_add_f32,.-probe_add_f32

        .globl probe_mul_f64
        .type probe_mul_f64,@function
probe_mul_f64:
        PROLOGUE %rdi
        call abi_mul_f64
        POSTCHECK f64
        .size probe_mul_f64,.-probe_mul_f64

        .globl probe_negative_clobber
        .type probe_negative_clobber,@function
probe_negative_clobber:
        PROLOGUE %rdi
        call abi_negative_clobber
        POSTCHECK u64
        .size probe_negative_clobber,.-probe_negative_clobber

        .globl abi_negative_clobber
        .type abi_negative_clobber,@function
abi_negative_clobber:
        movq $0, %rax
        movq $0, %rbx
        ret
        .size abi_negative_clobber,.-abi_negative_clobber

        .globl abi_negative_write
        .type abi_negative_write,@function
abi_negative_write:
        movb $0, -1(%rdi)
        ret
        .size abi_negative_write,.-abi_negative_write

        .globl abi_negative_timeout
        .type abi_negative_timeout,@function
abi_negative_timeout:
9012:
        pause
        jmp 9012b
        .size abi_negative_timeout,.-abi_negative_timeout

        .section .note.GNU-stack,"",@progbits
