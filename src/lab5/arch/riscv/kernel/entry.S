    .section .text.entry
    .align 4
    .globl _traps
_traps:
    # 1. 将寄存器和 sepc 保存到栈上

    # 2. 调用 trap_handler

    # 3. 恢复寄存器和 sepc
    #    特别注意 sp 寄存器的恢复

    # 4. 返回
#error Not yet implemented
