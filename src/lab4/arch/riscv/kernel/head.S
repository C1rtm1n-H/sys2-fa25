    .section .text.init
    .globl _start
_start:
    # 0. 设置 sp 为 _ekernel 之后 4 KiB 的位置
    la sp, _ekernel   # 加载内核结束地址
    li t0, 4096       # 为栈预留 4 KiB 空间
    add sp, sp, t0

    # 1. 跳转到 start_kernel
    call start_kernel # 调用 start_kernel 函数

# 如果 start_kernel 返回，则进入死循环
hang:
    j hang
