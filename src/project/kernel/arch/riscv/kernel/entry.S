#include "private_kdefs.h"
    .section .text.entry
    .align 4
    .globl _traps
_traps:
    # 1. 将寄存器和 sepc 保存到栈上
    # 分配栈空间：32个通用寄存器 + sepc + sstatus = 34个槽位
    # 34 * 8 = 272 字节，保持 16 字节对齐 -> 272
    addi sp, sp, -272

    # 保存通用寄存器
    sd x1,   0(sp)
    sd x3,   8(sp)   # x2 是 sp，最后保存
    sd x4,  16(sp)
    sd x5,  24(sp)
    sd x6,  32(sp)
    sd x7,  40(sp)
    sd x8,  48(sp)
    sd x9,  56(sp)
    sd x10, 64(sp)
    sd x11, 72(sp)
    sd x12, 80(sp)
    sd x13, 88(sp)
    sd x14, 96(sp)
    sd x15, 104(sp)
    sd x16, 112(sp)
    sd x17, 120(sp)
    sd x18, 128(sp)
    sd x19, 136(sp)
    sd x20, 144(sp)
    sd x21, 152(sp)
    sd x22, 160(sp)
    sd x23, 168(sp)
    sd x24, 176(sp)
    sd x25, 184(sp)
    sd x26, 192(sp)
    sd x27, 200(sp)
    sd x28, 208(sp)
    sd x29, 216(sp)
    sd x30, 224(sp)
    sd x31, 232(sp)

    # 读取并保存CSR
    csrr t0, sepc
    csrr t1, sstatus
    sd t0, 240(sp)   # 保存 sepc
    sd t1, 248(sp)   # 保存 sstatus

    # 2. 调用 trap_handler
    csrr a0, scause
    csrr a1, sepc
    call trap_handler

    # 3. 恢复寄存器和 sepc
    #    特别注意 sp 寄存器的恢复

    # 恢复CSR
    ld t0, 240(sp)   # 恢复 sepc
    ld t1, 248(sp)   # 恢复 sstatus
    csrw sepc, t0
    csrw sstatus, t1

    # 恢复通用寄存器
    ld x1,   0(sp)
    ld x3,   8(sp)   # x2 是 sp，最后恢复
    ld x4,  16(sp)
    ld x5,  24(sp)
    ld x6,  32(sp)
    ld x7,  40(sp)
    ld x8,  48(sp)
    ld x9,  56(sp)
    ld x10, 64(sp)
    ld x11, 72(sp)
    ld x12, 80(sp)
    ld x13, 88(sp)
    ld x14, 96(sp)
    ld x15, 104(sp)
    ld x16, 112(sp)
    ld x17, 120(sp)
    ld x18, 128(sp)
    ld x19, 136(sp)
    ld x20, 144(sp)
    ld x21, 152(sp)
    ld x22, 160(sp)
    ld x23, 168(sp)
    ld x24, 176(sp)
    ld x25, 184(sp)
    ld x26, 192(sp)
    ld x27, 200(sp)
    ld x28, 208(sp)
    ld x29, 216(sp)
    ld x30, 224(sp)
    ld x31, 232(sp)

    # 恢复 sp
    addi sp, sp, 272

    # 4. 返回
    # S-mode特有的返回指令，会将pc设置成sepc，并恢复特权模式
    sret


    .globl __dummy
__dummy:
    # 1. 将 dummy_task 的地址加载到 t0
    la t0, dummy_task

    # 2. 将 t0 的值写入 sepc 寄存器
    csrw sepc, t0

    # 3. 使用sret跳转到 dummy_task
    sret


    .globl __switch_to
__switch_to:
    # a0 = prev task_struct pointer
    # a1 = next task_struct pointer

    # 计算 thread_struct 的基地址
    add t0, a0, TASK_THREAD_OFFSET
    add t1, a1, TASK_THREAD_OFFSET

    # 1. 保存当前线程上下文到 prev->thread
    sd ra, TASK_THREAD_RA(t0)
    sd sp, TASK_THREAD_SP(t0)
    sd s0, TASK_THREAD_S0(t0)
    sd s1, TASK_THREAD_S1(t0)
    sd s2, TASK_THREAD_S2(t0)
    sd s3, TASK_THREAD_S3(t0)
    sd s4, TASK_THREAD_S4(t0)
    sd s5, TASK_THREAD_S5(t0)
    sd s6, TASK_THREAD_S6(t0)
    sd s7, TASK_THREAD_S7(t0)
    sd s8, TASK_THREAD_S8(t0)
    sd s9, TASK_THREAD_S9(t0)
    sd s10, TASK_THREAD_S10(t0)
    sd s11, TASK_THREAD_S11(t0)

    # 2. 从下一个线程上下文恢复 next->thread
    ld ra, TASK_THREAD_RA(t1)
    ld sp, TASK_THREAD_SP(t1)
    ld s0, TASK_THREAD_S0(t1)
    ld s1, TASK_THREAD_S1(t1)
    ld s2, TASK_THREAD_S2(t1)
    ld s3, TASK_THREAD_S3(t1)
    ld s4, TASK_THREAD_S4(t1)
    ld s5, TASK_THREAD_S5(t1)
    ld s6, TASK_THREAD_S6(t1)
    ld s7, TASK_THREAD_S7(t1)
    ld s8, TASK_THREAD_S8(t1)
    ld s9, TASK_THREAD_S9(t1)
    ld s10, TASK_THREAD_S10(t1)
    ld s11, TASK_THREAD_S11(t1)

    ret


