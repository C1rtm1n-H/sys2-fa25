#include "private_kdefs.h"

    .section .text.init
    .globl _start
_start:

    # 插入特权指令进行测试
    # csrr a0, mstatus  # 读取 mstatus 寄存器

    # 0. 设置 sp 为 _sbss并且调用mm_init初始化内存
    la sp, _sbss      # 加载内核BSS段起始地址
    call mm_init      # 初始化内存管理子系统

    # 1. 将stvec设置为_traps
    la t0, _traps     # 加载_traps标签地址
    csrw stvec, t0    # 设置 stvec 寄存器

    # 2. 设置sie[STIE] (Supervisor Timer Interrupt Enable)
    li t0, 0x20       # STIE 位于 sie 寄存器的第 5 位 (0x20)
    csrs sie, t0      # 使能定时器中断

    # 3. 设置第一次时钟中断的时间
    # rdtime t0         # 读取当前时间
    li t1, TIMECLOCK  # 加载时钟间隔
    # add a0, t0, t1    # 计算下一个时钟中断时间
    mv a0, t1        # 直接使用时间间隔作为下一个中断时间
    
    # 调用sbi接口设置时钟中断
    # sbi_set_timer
    # sbi_ecall(EID = 0x54494D45, FID = 0, arg0 = a0, ...)
    li a7, 0x54494D45
    li a6, 0
    ecall

    # 4. 设置 sstatus[SIE] (Supervisor Interrupt Enable)
    li t0, 0x2        # SIE 位于 sstatus 寄存器的第 1 位 (0x2)
    csrs sstatus, t0  # 使能S-mode下的trap响应

    # 5. 跳转到 start_kernel
    # li a0, 913       # 传递参数 arg = 913用于测试思考题8
    call start_kernel # 调用 start_kernel 函数

# 如果 start_kernel 返回，则进入死循环
hang:
    j hang

    # 在末尾添加 .bss.stack 段定义
    .section .bss.stack
    .space PGSIZE
