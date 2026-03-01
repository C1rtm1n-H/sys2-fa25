## Homework 1

```asm asembly
# 题干给出的指令
add     x15, x12, x11
ld      x13, 4(x15)
ld      x12, 0(x2)
or      x13, x15, x13
sd      x13, 0(x15)
```
原本的execution diagram如下：
```
Cycle:    1   2   3   4   5   6   7   8   9  10
---------------------------------------------
add      IF  ID  EX  MEM WB
ld           IF  ID  EX  MEM WB
ld               IF  ID  EX  MEM WB
or                   IF  ID  EX  MEM WB
sd                       IF  ID  EX  MEM WB
```

1. If there is no forwarding or hazard detection, insert NOPs to ensure correct execution.

    1. 第二条指令ld在id阶段需要第一条指令add写回的x15，从diagram中可以看出，从ld指令的id阶段C3到add指令的wb阶段de下一个周期C6需要3个cycle，因此需要在ld指令前插入3个nop。

    2. 第四条指令or在id阶段需要第一条指令add写回的x15和第二条指令ld写回的x13，从diagram中可以看到，从or指令的id阶段C5到add的wb的下一个cycle需要一个cycle，到ld的wb的下一个cycle需要2个cycle，因此需要在or前插入2个nop。

    3. 和1同理，需要三个nop

    插入后指令如下：
    ```asm asembly
    add     x15, x12, x11
    nop
    nop
    nop
    ld      x13, 4(x15)
    ld      x12, 0(x2)
    nop
    nop
    or      x13, x15, x13
    nop
    nop
    nop
    sd      x13, 0(x15)
    ```
---
2. If the processor has forwarding, but we forgot to implement the hazard detection unit, what happens when the code executes?

    只依靠forwarding没办法解决load-use hazard，or指令在ex阶段需要x13，而x13要等ld指令在mem阶段结束后才能forward给or指令的ex阶段，因此or指令会用到错误的数据，导致x13计算错误。又因为下一条指令sd需要把x13中的数据存进0(x15)，因此0(x15)也会存入错误的数据。
---
3. If there is forwarding, for the first seven cycles during the execution of this code, specify which signals are asserted in each cycle and show a pipeline execution diagram.

**cycle 4**：
`ex/mem.reg_write == 1(add) && ex\mem.rd(add的x15) == id/ex.rs1(ld的x15)` -> ex hazard detected
forwardA = 10(add的alu_res(x15) -> ld的alu_a(x15)) forwardB = 00

**cycle 5**: 
`id/ex.mem_read == 1(ld) && (id/ex.rd == if/id.rs1 (or的x15)` -> load-use hazard detected -> stall
PCwrite = 0
IF/ID.write = 0

**cycle 6**: stall

**cycle 7**: 
`mem/wb.reg_write == 1(ld) && mem\wb.rd(ld的x13) == id/ex.rs2(or的x13)` -> mem hazard detected
forwardA = 00(or的alu_a(x15)来自add的wb(已经写回寄存器)) forwardB =01(ld的mem_data(x13) -> or的alu_b(x13))

**cycle 8**:
forwardA = 10(or的alu_res(x13) -> sd的alu_a(x13)) forwardB = 00

execution diagram如下：
![execution diagram](./images/hm1.png)