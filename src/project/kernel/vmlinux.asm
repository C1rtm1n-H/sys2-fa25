
vmlinux:     file format elf64-littleriscv


Disassembly of section .text:

0000000080200000 <_skernel>:

    # 插入特权指令进行测试
    # csrr a0, mstatus  # 读取 mstatus 寄存器

    # 0. 设置 sp 为 _sbss并且调用mm_init初始化内存
    la sp, _sbss      # 加载内核BSS段起始地址
    80200000:	00003117          	auipc	sp,0x3
    80200004:	01813103          	ld	sp,24(sp) # 80203018 <_GLOBAL_OFFSET_TABLE_+0x18>
    call mm_init      # 初始化内存管理子系统
    80200008:	29c000ef          	jal	ra,802002a4 <mm_init>

    # 1. 将stvec设置为_traps
    la t0, _traps     # 加载_traps标签地址
    8020000c:	00003297          	auipc	t0,0x3
    80200010:	01c2b283          	ld	t0,28(t0) # 80203028 <_GLOBAL_OFFSET_TABLE_+0x28>
    csrw stvec, t0    # 设置 stvec 寄存器
    80200014:	10529073          	csrw	stvec,t0

    # 2. 设置sie[STIE] (Supervisor Timer Interrupt Enable)
    li t0, 0x20       # STIE 位于 sie 寄存器的第 5 位 (0x20)
    80200018:	02000293          	li	t0,32
    csrs sie, t0      # 使能定时器中断
    8020001c:	1042a073          	csrs	sie,t0

    # 3. 设置第一次时钟中断的时间
    # rdtime t0         # 读取当前时间
    li t1, TIMECLOCK  # 加载时钟间隔
    80200020:	00031337          	lui	t1,0x31
    80200024:	d403031b          	addiw	t1,t1,-704 # 30d40 <_skernel-0x801cf2c0>
    # add a0, t0, t1    # 计算下一个时钟中断时间
    mv a0, t1        # 直接使用时间间隔作为下一个中断时间
    80200028:	00030513          	mv	a0,t1
    
    # 调用sbi接口设置时钟中断
    # sbi_set_timer
    # sbi_ecall(EID = 0x54494D45, FID = 0, arg0 = a0, ...)
    li a7, 0x54494D45
    8020002c:	544958b7          	lui	a7,0x54495
    80200030:	d458889b          	addiw	a7,a7,-699 # 54494d45 <_skernel-0x2bd6b2bb>
    li a6, 0
    80200034:	00000813          	li	a6,0
    ecall
    80200038:	00000073          	ecall

    # 4. 设置 sstatus[SIE] (Supervisor Interrupt Enable)
    li t0, 0x2        # SIE 位于 sstatus 寄存器的第 1 位 (0x2)
    8020003c:	00200293          	li	t0,2
    csrs sstatus, t0  # 使能S-mode下的trap响应
    80200040:	1002a073          	csrs	sstatus,t0

    # 5. 跳转到 start_kernel
    # li a0, 913       # 传递参数 arg = 913用于测试思考题8
    call start_kernel # 调用 start_kernel 函数
    80200044:	20c000ef          	jal	ra,80200250 <start_kernel>

0000000080200048 <hang>:

# 如果 start_kernel 返回，则进入死循环
hang:
    j hang
    80200048:	0000006f          	j	80200048 <hang>
    8020004c:	0000                	.2byte	0x0
	...

0000000080200050 <_traps>:
    .globl _traps
_traps:
    # 1. 将寄存器和 sepc 保存到栈上
    # 分配栈空间：32个通用寄存器 + sepc + sstatus = 34个槽位
    # 34 * 8 = 272 字节，保持 16 字节对齐 -> 272
    addi sp, sp, -272
    80200050:	ef010113          	addi	sp,sp,-272

    # 保存通用寄存器
    sd x1,   0(sp)
    80200054:	00113023          	sd	ra,0(sp)
    sd x3,   8(sp)   # x2 是 sp，最后保存
    80200058:	00313423          	sd	gp,8(sp)
    sd x4,  16(sp)
    8020005c:	00413823          	sd	tp,16(sp)
    sd x5,  24(sp)
    80200060:	00513c23          	sd	t0,24(sp)
    sd x6,  32(sp)
    80200064:	02613023          	sd	t1,32(sp)
    sd x7,  40(sp)
    80200068:	02713423          	sd	t2,40(sp)
    sd x8,  48(sp)
    8020006c:	02813823          	sd	s0,48(sp)
    sd x9,  56(sp)
    80200070:	02913c23          	sd	s1,56(sp)
    sd x10, 64(sp)
    80200074:	04a13023          	sd	a0,64(sp)
    sd x11, 72(sp)
    80200078:	04b13423          	sd	a1,72(sp)
    sd x12, 80(sp)
    8020007c:	04c13823          	sd	a2,80(sp)
    sd x13, 88(sp)
    80200080:	04d13c23          	sd	a3,88(sp)
    sd x14, 96(sp)
    80200084:	06e13023          	sd	a4,96(sp)
    sd x15, 104(sp)
    80200088:	06f13423          	sd	a5,104(sp)
    sd x16, 112(sp)
    8020008c:	07013823          	sd	a6,112(sp)
    sd x17, 120(sp)
    80200090:	07113c23          	sd	a7,120(sp)
    sd x18, 128(sp)
    80200094:	09213023          	sd	s2,128(sp)
    sd x19, 136(sp)
    80200098:	09313423          	sd	s3,136(sp)
    sd x20, 144(sp)
    8020009c:	09413823          	sd	s4,144(sp)
    sd x21, 152(sp)
    802000a0:	09513c23          	sd	s5,152(sp)
    sd x22, 160(sp)
    802000a4:	0b613023          	sd	s6,160(sp)
    sd x23, 168(sp)
    802000a8:	0b713423          	sd	s7,168(sp)
    sd x24, 176(sp)
    802000ac:	0b813823          	sd	s8,176(sp)
    sd x25, 184(sp)
    802000b0:	0b913c23          	sd	s9,184(sp)
    sd x26, 192(sp)
    802000b4:	0da13023          	sd	s10,192(sp)
    sd x27, 200(sp)
    802000b8:	0db13423          	sd	s11,200(sp)
    sd x28, 208(sp)
    802000bc:	0dc13823          	sd	t3,208(sp)
    sd x29, 216(sp)
    802000c0:	0dd13c23          	sd	t4,216(sp)
    sd x30, 224(sp)
    802000c4:	0fe13023          	sd	t5,224(sp)
    sd x31, 232(sp)
    802000c8:	0ff13423          	sd	t6,232(sp)

    # 读取并保存CSR
    csrr t0, sepc
    802000cc:	141022f3          	csrr	t0,sepc
    csrr t1, sstatus
    802000d0:	10002373          	csrr	t1,sstatus
    sd t0, 240(sp)   # 保存 sepc
    802000d4:	0e513823          	sd	t0,240(sp)
    sd t1, 248(sp)   # 保存 sstatus
    802000d8:	0e613c23          	sd	t1,248(sp)

    # 2. 调用 trap_handler
    csrr a0, scause
    802000dc:	14202573          	csrr	a0,scause
    csrr a1, sepc
    802000e0:	141025f3          	csrr	a1,sepc
    call trap_handler
    802000e4:	5d0000ef          	jal	ra,802006b4 <trap_handler>

    # 3. 恢复寄存器和 sepc
    #    特别注意 sp 寄存器的恢复

    # 恢复CSR
    ld t0, 240(sp)   # 恢复 sepc
    802000e8:	0f013283          	ld	t0,240(sp)
    ld t1, 248(sp)   # 恢复 sstatus
    802000ec:	0f813303          	ld	t1,248(sp)
    csrw sepc, t0
    802000f0:	14129073          	csrw	sepc,t0
    csrw sstatus, t1
    802000f4:	10031073          	csrw	sstatus,t1

    # 恢复通用寄存器
    ld x1,   0(sp)
    802000f8:	00013083          	ld	ra,0(sp)
    ld x3,   8(sp)   # x2 是 sp，最后恢复
    802000fc:	00813183          	ld	gp,8(sp)
    ld x4,  16(sp)
    80200100:	01013203          	ld	tp,16(sp)
    ld x5,  24(sp)
    80200104:	01813283          	ld	t0,24(sp)
    ld x6,  32(sp)
    80200108:	02013303          	ld	t1,32(sp)
    ld x7,  40(sp)
    8020010c:	02813383          	ld	t2,40(sp)
    ld x8,  48(sp)
    80200110:	03013403          	ld	s0,48(sp)
    ld x9,  56(sp)
    80200114:	03813483          	ld	s1,56(sp)
    ld x10, 64(sp)
    80200118:	04013503          	ld	a0,64(sp)
    ld x11, 72(sp)
    8020011c:	04813583          	ld	a1,72(sp)
    ld x12, 80(sp)
    80200120:	05013603          	ld	a2,80(sp)
    ld x13, 88(sp)
    80200124:	05813683          	ld	a3,88(sp)
    ld x14, 96(sp)
    80200128:	06013703          	ld	a4,96(sp)
    ld x15, 104(sp)
    8020012c:	06813783          	ld	a5,104(sp)
    ld x16, 112(sp)
    80200130:	07013803          	ld	a6,112(sp)
    ld x17, 120(sp)
    80200134:	07813883          	ld	a7,120(sp)
    ld x18, 128(sp)
    80200138:	08013903          	ld	s2,128(sp)
    ld x19, 136(sp)
    8020013c:	08813983          	ld	s3,136(sp)
    ld x20, 144(sp)
    80200140:	09013a03          	ld	s4,144(sp)
    ld x21, 152(sp)
    80200144:	09813a83          	ld	s5,152(sp)
    ld x22, 160(sp)
    80200148:	0a013b03          	ld	s6,160(sp)
    ld x23, 168(sp)
    8020014c:	0a813b83          	ld	s7,168(sp)
    ld x24, 176(sp)
    80200150:	0b013c03          	ld	s8,176(sp)
    ld x25, 184(sp)
    80200154:	0b813c83          	ld	s9,184(sp)
    ld x26, 192(sp)
    80200158:	0c013d03          	ld	s10,192(sp)
    ld x27, 200(sp)
    8020015c:	0c813d83          	ld	s11,200(sp)
    ld x28, 208(sp)
    80200160:	0d013e03          	ld	t3,208(sp)
    ld x29, 216(sp)
    80200164:	0d813e83          	ld	t4,216(sp)
    ld x30, 224(sp)
    80200168:	0e013f03          	ld	t5,224(sp)
    ld x31, 232(sp)
    8020016c:	0e813f83          	ld	t6,232(sp)

    # 恢复 sp
    addi sp, sp, 272
    80200170:	11010113          	addi	sp,sp,272

    # 4. 返回
    # S-mode特有的返回指令，会将pc设置成sepc，并恢复特权模式
    sret
    80200174:	10200073          	sret

0000000080200178 <__dummy>:


    .globl __dummy
__dummy:
    # 1. 将 dummy_task 的地址加载到 t0
    la t0, dummy_task
    80200178:	00003297          	auipc	t0,0x3
    8020017c:	e902b283          	ld	t0,-368(t0) # 80203008 <_GLOBAL_OFFSET_TABLE_+0x8>

    # 2. 将 t0 的值写入 sepc 寄存器
    csrw sepc, t0
    80200180:	14129073          	csrw	sepc,t0

    # 3. 使用sret跳转到 dummy_task
    sret
    80200184:	10200073          	sret

0000000080200188 <__switch_to>:
__switch_to:
    # a0 = prev task_struct pointer
    # a1 = next task_struct pointer

    # 计算 thread_struct 的基地址
    add t0, a0, TASK_THREAD_OFFSET
    80200188:	02050293          	addi	t0,a0,32
    add t1, a1, TASK_THREAD_OFFSET
    8020018c:	02058313          	addi	t1,a1,32

    # 1. 保存当前线程上下文到 prev->thread
    sd ra, TASK_THREAD_RA(t0)
    80200190:	0012b023          	sd	ra,0(t0)
    sd sp, TASK_THREAD_SP(t0)
    80200194:	0022b423          	sd	sp,8(t0)
    sd s0, TASK_THREAD_S0(t0)
    80200198:	0082b823          	sd	s0,16(t0)
    sd s1, TASK_THREAD_S1(t0)
    8020019c:	0092bc23          	sd	s1,24(t0)
    sd s2, TASK_THREAD_S2(t0)
    802001a0:	0322b023          	sd	s2,32(t0)
    sd s3, TASK_THREAD_S3(t0)
    802001a4:	0332b423          	sd	s3,40(t0)
    sd s4, TASK_THREAD_S4(t0)
    802001a8:	0342b823          	sd	s4,48(t0)
    sd s5, TASK_THREAD_S5(t0)
    802001ac:	0352bc23          	sd	s5,56(t0)
    sd s6, TASK_THREAD_S6(t0)
    802001b0:	0562b023          	sd	s6,64(t0)
    sd s7, TASK_THREAD_S7(t0)
    802001b4:	0572b423          	sd	s7,72(t0)
    sd s8, TASK_THREAD_S8(t0)
    802001b8:	0582b823          	sd	s8,80(t0)
    sd s9, TASK_THREAD_S9(t0)
    802001bc:	0592bc23          	sd	s9,88(t0)
    sd s10, TASK_THREAD_S10(t0)
    802001c0:	07a2b023          	sd	s10,96(t0)
    sd s11, TASK_THREAD_S11(t0)
    802001c4:	07b2b423          	sd	s11,104(t0)

    # 2. 从下一个线程上下文恢复 next->thread
    ld ra, TASK_THREAD_RA(t1)
    802001c8:	00033083          	ld	ra,0(t1)
    ld sp, TASK_THREAD_SP(t1)
    802001cc:	00833103          	ld	sp,8(t1)
    ld s0, TASK_THREAD_S0(t1)
    802001d0:	01033403          	ld	s0,16(t1)
    ld s1, TASK_THREAD_S1(t1)
    802001d4:	01833483          	ld	s1,24(t1)
    ld s2, TASK_THREAD_S2(t1)
    802001d8:	02033903          	ld	s2,32(t1)
    ld s3, TASK_THREAD_S3(t1)
    802001dc:	02833983          	ld	s3,40(t1)
    ld s4, TASK_THREAD_S4(t1)
    802001e0:	03033a03          	ld	s4,48(t1)
    ld s5, TASK_THREAD_S5(t1)
    802001e4:	03833a83          	ld	s5,56(t1)
    ld s6, TASK_THREAD_S6(t1)
    802001e8:	04033b03          	ld	s6,64(t1)
    ld s7, TASK_THREAD_S7(t1)
    802001ec:	04833b83          	ld	s7,72(t1)
    ld s8, TASK_THREAD_S8(t1)
    802001f0:	05033c03          	ld	s8,80(t1)
    ld s9, TASK_THREAD_S9(t1)
    802001f4:	05833c83          	ld	s9,88(t1)
    ld s10, TASK_THREAD_S10(t1)
    802001f8:	06033d03          	ld	s10,96(t1)
    ld s11, TASK_THREAD_S11(t1)
    802001fc:	06833d83          	ld	s11,104(t1)

    ret
    80200200:	00008067          	ret
	...

0000000080200210 <clock_set_next_event>:
#include <stdint.h>
#include <private_kdefs.h>
#include <sbi.h>


void clock_set_next_event(void) {
    80200210:	ff010113          	addi	sp,sp,-16
    80200214:	00113423          	sd	ra,8(sp)

  // 3. 调用 sbi_set_timer 设置下一次时钟中断
  // EID = 0x54494D45 (TIME Extension)
  // FID = 0 (sbi_set_timer)
  // arg0 = stime_value (next)
  sbi_ecall(0x54494D45, 0, TIMECLOCK, 0, 0, 0, 0, 0);
    80200218:	00000893          	li	a7,0
    8020021c:	00000813          	li	a6,0
    80200220:	00000793          	li	a5,0
    80200224:	00000713          	li	a4,0
    80200228:	00000693          	li	a3,0
    8020022c:	00031637          	lui	a2,0x31
    80200230:	d4060613          	addi	a2,a2,-704 # 30d40 <_skernel-0x801cf2c0>
    80200234:	00000593          	li	a1,0
    80200238:	54495537          	lui	a0,0x54495
    8020023c:	d4550513          	addi	a0,a0,-699 # 54494d45 <_skernel-0x2bd6b2bb>
    80200240:	3fc000ef          	jal	ra,8020063c <sbi_ecall>
}
    80200244:	00813083          	ld	ra,8(sp)
    80200248:	01010113          	addi	sp,sp,16
    8020024c:	00008067          	ret

0000000080200250 <start_kernel>:
#include <printk.h>
#include <sbi.h>
#include <private_kdefs.h>
#include <proc.h>

_Noreturn void start_kernel(void){
    80200250:	ff010113          	addi	sp,sp,-16
    80200254:	00113423          	sd	ra,8(sp)
  task_init();
    80200258:	1b8000ef          	jal	ra,80200410 <task_init>
  printk("2025 ZJU Computer System II\n");
    8020025c:	00002517          	auipc	a0,0x2
    80200260:	da450513          	addi	a0,a0,-604 # 80202000 <_srodata>
    80200264:	0f4000ef          	jal	ra,80200358 <printk>

  // 直接调用schedule
  //schedule();

  // 等待第一次时钟中断
  while(1);
    80200268:	0000006f          	j	80200268 <start_kernel+0x18>

000000008020026c <alloc_page>:
static struct kfreelist {
  struct kfreelist *next;
} *kfreelist;

void *alloc_page(void) {
  struct kfreelist *r = kfreelist;
    8020026c:	00005797          	auipc	a5,0x5
    80200270:	d9478793          	addi	a5,a5,-620 # 80205000 <kfreelist>
    80200274:	0007b503          	ld	a0,0(a5)
  kfreelist = r->next;
    80200278:	00053703          	ld	a4,0(a0)
    8020027c:	00e7b023          	sd	a4,0(a5)
  return r;
}
    80200280:	00008067          	ret

0000000080200284 <free_pages>:

void free_pages(void *addr) {
  struct kfreelist *r = (void *)PGROUNDDOWN((uintptr_t)addr);
    80200284:	fffff7b7          	lui	a5,0xfffff
    80200288:	00f57533          	and	a0,a0,a5
  //memset(r, 0xfa, PGSIZE);
  r->next = kfreelist;
    8020028c:	00005797          	auipc	a5,0x5
    80200290:	d7478793          	addi	a5,a5,-652 # 80205000 <kfreelist>
    80200294:	0007b703          	ld	a4,0(a5)
    80200298:	00e53023          	sd	a4,0(a0)
  kfreelist = r;
    8020029c:	00a7b023          	sd	a0,0(a5)
}
    802002a0:	00008067          	ret

00000000802002a4 <mm_init>:

void mm_init(void) {
    802002a4:	ff010113          	addi	sp,sp,-16
    802002a8:	00113423          	sd	ra,8(sp)
    802002ac:	00813023          	sd	s0,0(sp)
  uint8_t *s = (void *)PGROUNDUP((uintptr_t)_ekernel);
    802002b0:	00003517          	auipc	a0,0x3
    802002b4:	d6053503          	ld	a0,-672(a0) # 80203010 <_GLOBAL_OFFSET_TABLE_+0x10>
    802002b8:	000017b7          	lui	a5,0x1
    802002bc:	fff78793          	addi	a5,a5,-1 # fff <_skernel-0x801ff001>
    802002c0:	00f50533          	add	a0,a0,a5
    802002c4:	fffff7b7          	lui	a5,0xfffff
    802002c8:	00f57533          	and	a0,a0,a5
  const uint8_t *e = (void *)PHY_END;
  for (; s + PGSIZE <= e; s += PGSIZE) {
    802002cc:	00c0006f          	j	802002d8 <mm_init+0x34>
    free_pages(s);
    802002d0:	fb5ff0ef          	jal	ra,80200284 <free_pages>
  for (; s + PGSIZE <= e; s += PGSIZE) {
    802002d4:	00040513          	mv	a0,s0
    802002d8:	00001437          	lui	s0,0x1
    802002dc:	00850433          	add	s0,a0,s0
    802002e0:	20100793          	li	a5,513
    802002e4:	01679793          	slli	a5,a5,0x16
    802002e8:	fe87f4e3          	bgeu	a5,s0,802002d0 <mm_init+0x2c>
  }

  printk("...mm_init done!\n");
    802002ec:	00002517          	auipc	a0,0x2
    802002f0:	d3450513          	addi	a0,a0,-716 # 80202020 <_srodata+0x20>
    802002f4:	064000ef          	jal	ra,80200358 <printk>
}
    802002f8:	00813083          	ld	ra,8(sp)
    802002fc:	00013403          	ld	s0,0(sp)
    80200300:	01010113          	addi	sp,sp,16
    80200304:	00008067          	ret

0000000080200308 <printk_sbi_write>:
#include <stdio.h>
#include <printk.h>
#include <sbi.h>

static int printk_sbi_write(FILE *restrict fp, const void *restrict buf, size_t len) {
    80200308:	fe010113          	addi	sp,sp,-32
    8020030c:	00113c23          	sd	ra,24(sp)
    80200310:	00058693          	mv	a3,a1
  // EID = 0x4442434E (sbi_debug_console_write)
  // FID = 0
  // arg0 = number of bytes
  // arg1 = base address low
  // arg2 = base address high
  struct sbiret ret = sbi_ecall(0x4442434E, 0, len, (uint64_t)buf, 0, 0, 0, 0);
    80200314:	00000893          	li	a7,0
    80200318:	00000813          	li	a6,0
    8020031c:	00000793          	li	a5,0
    80200320:	00000713          	li	a4,0
    80200324:	00000593          	li	a1,0
    80200328:	44424537          	lui	a0,0x44424
    8020032c:	34e50513          	addi	a0,a0,846 # 4442434e <_skernel-0x3bddbcb2>
    80200330:	30c000ef          	jal	ra,8020063c <sbi_ecall>
    80200334:	00a13023          	sd	a0,0(sp)
    80200338:	00b13423          	sd	a1,8(sp)
  
  if(ret.error != 0){
    8020033c:	00051a63          	bnez	a0,80200350 <printk_sbi_write+0x48>
    return 0;
  }
  // 返回实际写入的字节数
  return (int)ret.value;
    80200340:	00812503          	lw	a0,8(sp)
}
    80200344:	01813083          	ld	ra,24(sp)
    80200348:	02010113          	addi	sp,sp,32
    8020034c:	00008067          	ret
    return 0;
    80200350:	00000513          	li	a0,0
    80200354:	ff1ff06f          	j	80200344 <printk_sbi_write+0x3c>

0000000080200358 <printk>:

void printk(const char *fmt, ...) {
    80200358:	fa010113          	addi	sp,sp,-96
    8020035c:	00113c23          	sd	ra,24(sp)
    80200360:	02b13423          	sd	a1,40(sp)
    80200364:	02c13823          	sd	a2,48(sp)
    80200368:	02d13c23          	sd	a3,56(sp)
    8020036c:	04e13023          	sd	a4,64(sp)
    80200370:	04f13423          	sd	a5,72(sp)
    80200374:	05013823          	sd	a6,80(sp)
    80200378:	05113c23          	sd	a7,88(sp)
  FILE printk_out = {
    8020037c:	00000797          	auipc	a5,0x0
    80200380:	f8c78793          	addi	a5,a5,-116 # 80200308 <printk_sbi_write>
    80200384:	00f13423          	sd	a5,8(sp)
      .write = printk_sbi_write,
  };

  va_list ap;
  va_start(ap, fmt);
    80200388:	02810613          	addi	a2,sp,40
    8020038c:	00c13023          	sd	a2,0(sp)
  vfprintf(&printk_out, fmt, ap);
    80200390:	00050593          	mv	a1,a0
    80200394:	00810513          	addi	a0,sp,8
    80200398:	28c010ef          	jal	ra,80201624 <vfprintf>
  va_end(ap);
}
    8020039c:	01813083          	ld	ra,24(sp)
    802003a0:	06010113          	addi	sp,sp,96
    802003a4:	00008067          	ret

00000000802003a8 <dummy_task>:
// - void task_init(void);
// - void do_timer(void);
// - void schedule(void);
// - void switch_to(struct task_struct* next);

void dummy_task(void) {
    802003a8:	fe010113          	addi	sp,sp,-32
    802003ac:	00113c23          	sd	ra,24(sp)
    802003b0:	00813823          	sd	s0,16(sp)
    802003b4:	00913423          	sd	s1,8(sp)
    unsigned local = 0;
    unsigned prev_cnt = 0;
    802003b8:	00000413          	li	s0,0
    unsigned local = 0;
    802003bc:	00000493          	li	s1,0
    802003c0:	0200006f          	j	802003e0 <dummy_task+0x38>
            if (current->counter == 1) {
            // 若 priority 为 1，则线程可见的 counter 永远为 1（为什么？）
            // 通过设置 counter 为 0，避免信息无法打印的问题
            current->counter = 0;
            }
            prev_cnt = current->counter;
    802003c4:	0187a403          	lw	s0,24(a5)
            printk("[P = %" PRIu64 "] %u\n", current->pid, ++local);
    802003c8:	0014849b          	addiw	s1,s1,1
    802003cc:	00048613          	mv	a2,s1
    802003d0:	0007b583          	ld	a1,0(a5)
    802003d4:	00002517          	auipc	a0,0x2
    802003d8:	c6450513          	addi	a0,a0,-924 # 80202038 <_srodata+0x38>
    802003dc:	f7dff0ef          	jal	ra,80200358 <printk>
        if (current->counter != prev_cnt) {
    802003e0:	00005797          	auipc	a5,0x5
    802003e4:	c287b783          	ld	a5,-984(a5) # 80205008 <current>
    802003e8:	0187b703          	ld	a4,24(a5)
    802003ec:	02041693          	slli	a3,s0,0x20
    802003f0:	0206d693          	srli	a3,a3,0x20
    802003f4:	0004849b          	sext.w	s1,s1
    802003f8:	0004041b          	sext.w	s0,s0
    802003fc:	fed702e3          	beq	a4,a3,802003e0 <dummy_task+0x38>
            if (current->counter == 1) {
    80200400:	00100693          	li	a3,1
    80200404:	fcd710e3          	bne	a4,a3,802003c4 <dummy_task+0x1c>
            current->counter = 0;
    80200408:	0007bc23          	sd	zero,24(a5)
    8020040c:	fb9ff06f          	j	802003c4 <dummy_task+0x1c>

0000000080200410 <task_init>:
        }
    }
}

void task_init(void){
    80200410:	fe010113          	addi	sp,sp,-32
    80200414:	00113c23          	sd	ra,24(sp)
    80200418:	00813823          	sd	s0,16(sp)
    8020041c:	00913423          	sd	s1,8(sp)
    srand(2025);
    80200420:	7e900513          	li	a0,2025
    80200424:	414000ef          	jal	ra,80200838 <srand>
    // 1. 调用 alloc_page() 为 idle 分配一个物理页
    idle = (struct task_struct*)alloc_page();
    80200428:	e45ff0ef          	jal	ra,8020026c <alloc_page>
    8020042c:	00005797          	auipc	a5,0x5
    80200430:	bea7b223          	sd	a0,-1052(a5) # 80205010 <idle>

    // 2. 初始化 idle 线程：
    //   - state 为5 TASK_RUNNING
    //   - pid 为 0
    //   - 由于其不参与调度，可以将 priority 和 counter 设为 0
    idle->state = TASK_RUNNING;
    80200434:	00053423          	sd	zero,8(a0)
    idle->pid = 0;
    80200438:	00053023          	sd	zero,0(a0)
    idle->priority = 0;
    8020043c:	00053823          	sd	zero,16(a0)
    idle->counter = 0;
    80200440:	00053c23          	sd	zero,24(a0)

    // 3. 将 current 和 task[0] 指向 idle
    current = idle;
    80200444:	00005797          	auipc	a5,0x5
    80200448:	bca7b223          	sd	a0,-1084(a5) # 80205008 <current>
    task[0] = idle;
    8020044c:	00005797          	auipc	a5,0x5
    80200450:	bca7b623          	sd	a0,-1076(a5) # 80205018 <task>

    // 4. 初始化 task[1..NR_TASKS - 1]：
    for(int i=1; i<NR_TASKS; i++){
    80200454:	00100413          	li	s0,1
    80200458:	05c0006f          	j	802004b4 <task_init+0xa4>
        // 分配一个物理页
        task[i] = (struct task_struct*)alloc_page();
    8020045c:	e11ff0ef          	jal	ra,8020026c <alloc_page>
    80200460:	00341793          	slli	a5,s0,0x3
    80200464:	00005497          	auipc	s1,0x5
    80200468:	bb448493          	addi	s1,s1,-1100 # 80205018 <task>
    8020046c:	00f484b3          	add	s1,s1,a5
    80200470:	00a4b023          	sd	a0,0(s1)
        // 初始化
        task[i]->state = TASK_RUNNING;
    80200474:	00053423          	sd	zero,8(a0)
        task[i]->pid = i;
    80200478:	00853023          	sd	s0,0(a0)
        task[i]->priority = (rand() % (PRIORITY_MAX - PRIORITY_MIN + 1)) + PRIORITY_MIN;
    8020047c:	3d4000ef          	jal	ra,80200850 <rand>
    80200480:	00a00593          	li	a1,10
    80200484:	354000ef          	jal	ra,802007d8 <__moddi3>
    80200488:	0004b783          	ld	a5,0(s1)
    8020048c:	0015051b          	addiw	a0,a0,1
    80200490:	00a7b823          	sd	a0,16(a5)
        task[i]->counter = 0;
    80200494:	0007bc23          	sd	zero,24(a5)
        // 设置 thread_struct 中的 ra 和 sp：
        // ra 设置为 __dummy 的地址
        task[i]->thread.ra = (uint64_t)__dummy;
    80200498:	00003717          	auipc	a4,0x3
    8020049c:	b8873703          	ld	a4,-1144(a4) # 80203020 <_GLOBAL_OFFSET_TABLE_+0x20>
    802004a0:	02e7b023          	sd	a4,32(a5)
        // sp 设置为该线程申请的物理页的高地址
        task[i]->thread.sp = (uint64_t)task[i] + PGSIZE;
    802004a4:	00001737          	lui	a4,0x1
    802004a8:	00e78733          	add	a4,a5,a4
    802004ac:	02e7b423          	sd	a4,40(a5)
    for(int i=1; i<NR_TASKS; i++){
    802004b0:	0014041b          	addiw	s0,s0,1 # 1001 <_skernel-0x801fefff>
    802004b4:	00400793          	li	a5,4
    802004b8:	fa87d2e3          	bge	a5,s0,8020045c <task_init+0x4c>
    }

    printk("...task_init done!\n");
    802004bc:	00002517          	auipc	a0,0x2
    802004c0:	b8c50513          	addi	a0,a0,-1140 # 80202048 <_srodata+0x48>
    802004c4:	e95ff0ef          	jal	ra,80200358 <printk>
}
    802004c8:	01813083          	ld	ra,24(sp)
    802004cc:	01013403          	ld	s0,16(sp)
    802004d0:	00813483          	ld	s1,8(sp)
    802004d4:	02010113          	addi	sp,sp,32
    802004d8:	00008067          	ret

00000000802004dc <switch_to>:
               next->pid, next->priority, next->counter);   
        switch_to(next);
    }
}

void switch_to(struct task_struct *next){
    802004dc:	00050593          	mv	a1,a0
    if(current != next){
    802004e0:	00005517          	auipc	a0,0x5
    802004e4:	b2853503          	ld	a0,-1240(a0) # 80205008 <current>
    802004e8:	02b50263          	beq	a0,a1,8020050c <switch_to+0x30>
void switch_to(struct task_struct *next){
    802004ec:	ff010113          	addi	sp,sp,-16
    802004f0:	00113423          	sd	ra,8(sp)
        struct task_struct *prev = current;
        current = next;
    802004f4:	00005797          	auipc	a5,0x5
    802004f8:	b0b7ba23          	sd	a1,-1260(a5) # 80205008 <current>
        __switch_to(prev, next);
    802004fc:	c8dff0ef          	jal	ra,80200188 <__switch_to>
    }
}
    80200500:	00813083          	ld	ra,8(sp)
    80200504:	01010113          	addi	sp,sp,16
    80200508:	00008067          	ret
    8020050c:	00008067          	ret

0000000080200510 <schedule>:
void schedule(void){
    80200510:	ff010113          	addi	sp,sp,-16
    80200514:	00113423          	sd	ra,8(sp)
    80200518:	00813023          	sd	s0,0(sp)
    8020051c:	0880006f          	j	802005a4 <schedule+0x94>
        for(int i=1; i<NR_TASKS; i++){
    80200520:	0017879b          	addiw	a5,a5,1
    80200524:	00400713          	li	a4,4
    80200528:	02f74a63          	blt	a4,a5,8020055c <schedule+0x4c>
            if(task[i]->state == TASK_RUNNING && (long)task[i]->counter > max_counter){
    8020052c:	00379693          	slli	a3,a5,0x3
    80200530:	00005717          	auipc	a4,0x5
    80200534:	ae870713          	addi	a4,a4,-1304 # 80205018 <task>
    80200538:	00d70733          	add	a4,a4,a3
    8020053c:	00073703          	ld	a4,0(a4)
    80200540:	00873683          	ld	a3,8(a4)
    80200544:	fc069ee3          	bnez	a3,80200520 <schedule+0x10>
    80200548:	01873683          	ld	a3,24(a4)
    8020054c:	fcd65ae3          	bge	a2,a3,80200520 <schedule+0x10>
                max_counter = task[i]->counter;
    80200550:	00068613          	mv	a2,a3
                next = task[i];
    80200554:	00070413          	mv	s0,a4
    80200558:	fc9ff06f          	j	80200520 <schedule+0x10>
        if(max_counter == 0){
    8020055c:	04061c63          	bnez	a2,802005b4 <schedule+0xa4>
            for(int i=1; i<NR_TASKS; i++){
    80200560:	00100413          	li	s0,1
    80200564:	0380006f          	j	8020059c <schedule+0x8c>
                task[i]->counter = task[i]->priority;
    80200568:	00341713          	slli	a4,s0,0x3
    8020056c:	00005797          	auipc	a5,0x5
    80200570:	aac78793          	addi	a5,a5,-1364 # 80205018 <task>
    80200574:	00e787b3          	add	a5,a5,a4
    80200578:	0007b783          	ld	a5,0(a5)
    8020057c:	0107b603          	ld	a2,16(a5)
    80200580:	00c7bc23          	sd	a2,24(a5)
                printk("S [%" PRIu64 ", %" PRIu64 ", %" PRIu64 "]\n",
    80200584:	00060693          	mv	a3,a2
    80200588:	0007b583          	ld	a1,0(a5)
    8020058c:	00002517          	auipc	a0,0x2
    80200590:	ad450513          	addi	a0,a0,-1324 # 80202060 <_srodata+0x60>
    80200594:	dc5ff0ef          	jal	ra,80200358 <printk>
            for(int i=1; i<NR_TASKS; i++){
    80200598:	0014041b          	addiw	s0,s0,1
    8020059c:	00400793          	li	a5,4
    802005a0:	fc87d4e3          	bge	a5,s0,80200568 <schedule+0x58>
        for(int i=1; i<NR_TASKS; i++){
    802005a4:	00100793          	li	a5,1
    802005a8:	fff00613          	li	a2,-1
    802005ac:	00000413          	li	s0,0
    802005b0:	f75ff06f          	j	80200524 <schedule+0x14>
    if(next){
    802005b4:	02040263          	beqz	s0,802005d8 <schedule+0xc8>
        printk("s 2 [%" PRIu64 ", %" PRIu64 ", %" PRIu64 "]\n",
    802005b8:	01843683          	ld	a3,24(s0)
    802005bc:	01043603          	ld	a2,16(s0)
    802005c0:	00043583          	ld	a1,0(s0)
    802005c4:	00002517          	auipc	a0,0x2
    802005c8:	ab450513          	addi	a0,a0,-1356 # 80202078 <_srodata+0x78>
    802005cc:	d8dff0ef          	jal	ra,80200358 <printk>
        switch_to(next);
    802005d0:	00040513          	mv	a0,s0
    802005d4:	f09ff0ef          	jal	ra,802004dc <switch_to>
}
    802005d8:	00813083          	ld	ra,8(sp)
    802005dc:	00013403          	ld	s0,0(sp)
    802005e0:	01010113          	addi	sp,sp,16
    802005e4:	00008067          	ret

00000000802005e8 <do_timer>:
void do_timer(void){
    802005e8:	ff010113          	addi	sp,sp,-16
    802005ec:	00113423          	sd	ra,8(sp)
    if(current->counter == 0){
    802005f0:	00005717          	auipc	a4,0x5
    802005f4:	a1873703          	ld	a4,-1512(a4) # 80205008 <current>
    802005f8:	01873783          	ld	a5,24(a4)
    802005fc:	02078863          	beqz	a5,8020062c <do_timer+0x44>
        current->counter--;
    80200600:	fff78793          	addi	a5,a5,-1
    80200604:	00f73c23          	sd	a5,24(a4)
        ticks++;
    80200608:	00005697          	auipc	a3,0x5
    8020060c:	a3868693          	addi	a3,a3,-1480 # 80205040 <ticks>
    80200610:	0006a703          	lw	a4,0(a3)
    80200614:	0017071b          	addiw	a4,a4,1
    80200618:	00e6a023          	sw	a4,0(a3)
        if(current->counter == 0){
    8020061c:	00078c63          	beqz	a5,80200634 <do_timer+0x4c>
}
    80200620:	00813083          	ld	ra,8(sp)
    80200624:	01010113          	addi	sp,sp,16
    80200628:	00008067          	ret
        schedule();
    8020062c:	ee5ff0ef          	jal	ra,80200510 <schedule>
    80200630:	ff1ff06f          	j	80200620 <do_timer+0x38>
            schedule();
    80200634:	eddff0ef          	jal	ra,80200510 <schedule>
}
    80200638:	fe9ff06f          	j	80200620 <do_timer+0x38>

000000008020063c <sbi_ecall>:
#include <stdint.h>
#include <sbi.h>

struct sbiret sbi_ecall(uint64_t eid, uint64_t fid,
                        uint64_t arg0, uint64_t arg1, uint64_t arg2,
                        uint64_t arg3, uint64_t arg4, uint64_t arg5) {
    8020063c:	fd010113          	addi	sp,sp,-48
    80200640:	02813423          	sd	s0,40(sp)
    80200644:	00050e13          	mv	t3,a0
    80200648:	00058313          	mv	t1,a1
    8020064c:	00060e93          	mv	t4,a2
    80200650:	00068f13          	mv	t5,a3
    80200654:	00070f93          	mv	t6,a4
    80200658:	00078293          	mv	t0,a5
    8020065c:	00080393          	mv	t2,a6
    80200660:	00088413          	mv	s0,a7
    // Return value
    struct sbiret ret;
    // Inline assembly to perform the ecall
    asm volatile(
    80200664:	000e0893          	mv	a7,t3
    80200668:	00030813          	mv	a6,t1
    8020066c:	000e8513          	mv	a0,t4
    80200670:	000f0593          	mv	a1,t5
    80200674:	000f8613          	mv	a2,t6
    80200678:	00028693          	mv	a3,t0
    8020067c:	00038713          	mv	a4,t2
    80200680:	00040793          	mv	a5,s0
    80200684:	00000073          	ecall
    80200688:	00050e13          	mv	t3,a0
    8020068c:	00058313          	mv	t1,a1
    80200690:	01c13023          	sd	t3,0(sp)
    80200694:	00613423          	sd	t1,8(sp)
          [arg4] "r"(arg4),
          [arg5] "r"(arg5)
        // Clobbered registers
        : "a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7", "memory"
    );
    return ret;
    80200698:	01c13823          	sd	t3,16(sp)
    8020069c:	00613c23          	sd	t1,24(sp)
}
    802006a0:	000e0513          	mv	a0,t3
    802006a4:	00030593          	mv	a1,t1
    802006a8:	02813403          	ld	s0,40(sp)
    802006ac:	03010113          	addi	sp,sp,48
    802006b0:	00008067          	ret

00000000802006b4 <trap_handler>:
#include <printk.h>
#include <proc.h>

void clock_set_next_event(void);

void trap_handler(uint64_t scause, uint64_t sepc) {
    802006b4:	ff010113          	addi	sp,sp,-16
    802006b8:	00113423          	sd	ra,8(sp)
    802006bc:	00058613          	mv	a2,a1
  // 其他类型的 trap 可以直接忽略，推荐打印出来供以后调试

  // 判断是否为中断(0x8000000000000000为最高位掩码)
  int is_interrupt = (scause & 0x8000000000000000UL) ? 1 : 0;
  // 获取exception code(0x7FFFFFFFFFFFFFFF为低63位掩码)
  uint64_t exception_code = scause & 0x7FFFFFFFFFFFFFFF;
    802006c0:	fff00793          	li	a5,-1
    802006c4:	0017d793          	srli	a5,a5,0x1
    802006c8:	00f577b3          	and	a5,a0,a5

  if(is_interrupt){
    802006cc:	02055a63          	bgez	a0,80200700 <trap_handler+0x4c>
    // 处理中断
    if(exception_code == 5){
    802006d0:	00500713          	li	a4,5
    802006d4:	02e78063          	beq	a5,a4,802006f4 <trap_handler+0x40>
      //printk("[S] Supervisor timer interrupt\n");
      clock_set_next_event();
      do_timer();
    }else{
      // 其他中断
      printk("Unknown interrupt: scause = %lx, sepc = %lx\n", scause, sepc);
    802006d8:	00050593          	mv	a1,a0
    802006dc:	00002517          	auipc	a0,0x2
    802006e0:	9b450513          	addi	a0,a0,-1612 # 80202090 <_srodata+0x90>
    802006e4:	c75ff0ef          	jal	ra,80200358 <printk>
    // 处理异常
    printk("Unknown exception: scause = %lx, sepc = %lx\n", scause, sepc);
    // 死循环
    while(1);
  }
}
    802006e8:	00813083          	ld	ra,8(sp)
    802006ec:	01010113          	addi	sp,sp,16
    802006f0:	00008067          	ret
      clock_set_next_event();
    802006f4:	b1dff0ef          	jal	ra,80200210 <clock_set_next_event>
      do_timer();
    802006f8:	ef1ff0ef          	jal	ra,802005e8 <do_timer>
    802006fc:	fedff06f          	j	802006e8 <trap_handler+0x34>
    printk("Unknown exception: scause = %lx, sepc = %lx\n", scause, sepc);
    80200700:	00050593          	mv	a1,a0
    80200704:	00002517          	auipc	a0,0x2
    80200708:	9bc50513          	addi	a0,a0,-1604 # 802020c0 <_srodata+0xc0>
    8020070c:	c4dff0ef          	jal	ra,80200358 <printk>
    while(1);
    80200710:	0000006f          	j	80200710 <trap_handler+0x5c>

0000000080200714 <__udivsi3>:
# define __divdi3 __divsi3
# define __moddi3 __modsi3
#else
FUNC_BEGIN (__udivsi3)
  /* Compute __udivdi3(a0 << 32, a1 << 32); cast result to uint32_t.  */
  sll    a0, a0, 32
    80200714:	02051513          	slli	a0,a0,0x20
  sll    a1, a1, 32
    80200718:	02059593          	slli	a1,a1,0x20
  move   t0, ra
    8020071c:	00008293          	mv	t0,ra
  jal    HIDDEN_JUMPTARGET(__udivdi3)
    80200720:	03c000ef          	jal	ra,8020075c <__hidden___udivdi3>
  sext.w a0, a0
    80200724:	0005051b          	sext.w	a0,a0
  jr     t0
    80200728:	00028067          	jr	t0

000000008020072c <__umodsi3>:
FUNC_END (__udivsi3)

FUNC_BEGIN (__umodsi3)
  /* Compute __udivdi3((uint32_t)a0, (uint32_t)a1); cast a1 to uint32_t.  */
  sll    a0, a0, 32
    8020072c:	02051513          	slli	a0,a0,0x20
  sll    a1, a1, 32
    80200730:	02059593          	slli	a1,a1,0x20
  srl    a0, a0, 32
    80200734:	02055513          	srli	a0,a0,0x20
  srl    a1, a1, 32
    80200738:	0205d593          	srli	a1,a1,0x20
  move   t0, ra
    8020073c:	00008293          	mv	t0,ra
  jal    HIDDEN_JUMPTARGET(__udivdi3)
    80200740:	01c000ef          	jal	ra,8020075c <__hidden___udivdi3>
  sext.w a0, a1
    80200744:	0005851b          	sext.w	a0,a1
  jr     t0
    80200748:	00028067          	jr	t0

000000008020074c <__divsi3>:

FUNC_ALIAS (__modsi3, __moddi3)

FUNC_BEGIN( __divsi3)
  /* Check for special case of INT_MIN/-1. Otherwise, fall into __divdi3.  */
  li    t0, -1
    8020074c:	fff00293          	li	t0,-1
  beq   a1, t0, .L20
    80200750:	0a558c63          	beq	a1,t0,80200808 <__moddi3+0x30>

0000000080200754 <__divdi3>:
#endif

FUNC_BEGIN (__divdi3)
  bltz  a0, .L10
    80200754:	06054063          	bltz	a0,802007b4 <__umoddi3+0x10>
  bltz  a1, .L11
    80200758:	0605c663          	bltz	a1,802007c4 <__umoddi3+0x20>

000000008020075c <__hidden___udivdi3>:
  /* Since the quotient is positive, fall into __udivdi3.  */

FUNC_BEGIN (__udivdi3)
  mv    a2, a1
    8020075c:	00058613          	mv	a2,a1
  mv    a1, a0
    80200760:	00050593          	mv	a1,a0
  li    a0, -1
    80200764:	fff00513          	li	a0,-1
  beqz  a2, .L5
    80200768:	02060c63          	beqz	a2,802007a0 <__hidden___udivdi3+0x44>
  li    a3, 1
    8020076c:	00100693          	li	a3,1
  bgeu  a2, a1, .L2
    80200770:	00b67a63          	bgeu	a2,a1,80200784 <__hidden___udivdi3+0x28>
.L1:
  blez  a2, .L2
    80200774:	00c05863          	blez	a2,80200784 <__hidden___udivdi3+0x28>
  slli  a2, a2, 1
    80200778:	00161613          	slli	a2,a2,0x1
  slli  a3, a3, 1
    8020077c:	00169693          	slli	a3,a3,0x1
  bgtu  a1, a2, .L1
    80200780:	feb66ae3          	bltu	a2,a1,80200774 <__hidden___udivdi3+0x18>
.L2:
  li    a0, 0
    80200784:	00000513          	li	a0,0
.L3:
  bltu  a1, a2, .L4
    80200788:	00c5e663          	bltu	a1,a2,80200794 <__hidden___udivdi3+0x38>
  sub   a1, a1, a2
    8020078c:	40c585b3          	sub	a1,a1,a2
  or    a0, a0, a3
    80200790:	00d56533          	or	a0,a0,a3
.L4:
  srli  a3, a3, 1
    80200794:	0016d693          	srli	a3,a3,0x1
  srli  a2, a2, 1
    80200798:	00165613          	srli	a2,a2,0x1
  bnez  a3, .L3
    8020079c:	fe0696e3          	bnez	a3,80200788 <__hidden___udivdi3+0x2c>
.L5:
  ret
    802007a0:	00008067          	ret

00000000802007a4 <__umoddi3>:
FUNC_END (__udivdi3)
HIDDEN_DEF (__udivdi3)

FUNC_BEGIN (__umoddi3)
  /* Call __udivdi3(a0, a1), then return the remainder, which is in a1.  */
  move  t0, ra
    802007a4:	00008293          	mv	t0,ra
  jal   HIDDEN_JUMPTARGET(__udivdi3)
    802007a8:	fb5ff0ef          	jal	ra,8020075c <__hidden___udivdi3>
  move  a0, a1
    802007ac:	00058513          	mv	a0,a1
  jr    t0
    802007b0:	00028067          	jr	t0
FUNC_END (__umoddi3)

  /* Handle negative arguments to __divdi3.  */
.L10:
  neg   a0, a0
    802007b4:	40a00533          	neg	a0,a0
  /* Zero is handled as a negative so that the result will not be inverted.  */
  bgtz  a1, .L12     /* Compute __udivdi3(-a0, a1), then negate the result.  */
    802007b8:	00b04863          	bgtz	a1,802007c8 <__umoddi3+0x24>

  neg   a1, a1
    802007bc:	40b005b3          	neg	a1,a1
  j     HIDDEN_JUMPTARGET(__udivdi3)     /* Compute __udivdi3(-a0, -a1).  */
    802007c0:	f9dff06f          	j	8020075c <__hidden___udivdi3>
.L11:                /* Compute __udivdi3(a0, -a1), then negate the result.  */
  neg   a1, a1
    802007c4:	40b005b3          	neg	a1,a1
.L12:
  move  t0, ra
    802007c8:	00008293          	mv	t0,ra
  jal   HIDDEN_JUMPTARGET(__udivdi3)
    802007cc:	f91ff0ef          	jal	ra,8020075c <__hidden___udivdi3>
  neg   a0, a0
    802007d0:	40a00533          	neg	a0,a0
  jr    t0
    802007d4:	00028067          	jr	t0

00000000802007d8 <__moddi3>:
FUNC_END (__divdi3)

FUNC_BEGIN (__moddi3)
  move   t0, ra
    802007d8:	00008293          	mv	t0,ra
  bltz   a1, .L31
    802007dc:	0005ca63          	bltz	a1,802007f0 <__moddi3+0x18>
  bltz   a0, .L32
    802007e0:	00054c63          	bltz	a0,802007f8 <__moddi3+0x20>
.L30:
  jal    HIDDEN_JUMPTARGET(__udivdi3)    /* The dividend is not negative.  */
    802007e4:	f79ff0ef          	jal	ra,8020075c <__hidden___udivdi3>
  move   a0, a1
    802007e8:	00058513          	mv	a0,a1
  jr     t0
    802007ec:	00028067          	jr	t0
.L31:
  neg    a1, a1
    802007f0:	40b005b3          	neg	a1,a1
  bgez   a0, .L30
    802007f4:	fe0558e3          	bgez	a0,802007e4 <__moddi3+0xc>
.L32:
  neg    a0, a0
    802007f8:	40a00533          	neg	a0,a0
  jal    HIDDEN_JUMPTARGET(__udivdi3)    /* The dividend is hella negative.  */
    802007fc:	f61ff0ef          	jal	ra,8020075c <__hidden___udivdi3>
  neg    a0, a1
    80200800:	40b00533          	neg	a0,a1
  jr     t0
    80200804:	00028067          	jr	t0
FUNC_END (__moddi3)

#if __riscv_xlen == 64
  /* continuation of __divsi3 */
.L20:
  sll   t0, t0, 31
    80200808:	01f29293          	slli	t0,t0,0x1f
  bne   a0, t0, __divdi3
    8020080c:	f45514e3          	bne	a0,t0,80200754 <__divdi3>
  ret
    80200810:	00008067          	ret

0000000080200814 <__muldi3>:
/* Our RV64 64-bit routine is equivalent to our RV32 32-bit routine.  */
# define __muldi3 __mulsi3
#endif

FUNC_BEGIN (__muldi3)
  mv     a2, a0
    80200814:	00050613          	mv	a2,a0
  li     a0, 0
    80200818:	00000513          	li	a0,0
.L1:
  andi   a3, a1, 1
    8020081c:	0015f693          	andi	a3,a1,1
  beqz   a3, .L2
    80200820:	00068463          	beqz	a3,80200828 <__muldi3+0x14>
  add    a0, a0, a2
    80200824:	00c50533          	add	a0,a0,a2
.L2:
  srli   a1, a1, 1
    80200828:	0015d593          	srli	a1,a1,0x1
  slli   a2, a2, 1
    8020082c:	00161613          	slli	a2,a2,0x1
  bnez   a1, .L1
    80200830:	fe0596e3          	bnez	a1,8020081c <__muldi3+0x8>
  ret
    80200834:	00008067          	ret

0000000080200838 <srand>:
#include <stdint.h>

static uint64_t seed;

void srand(unsigned s) {
  seed = s - 1;
    80200838:	fff5051b          	addiw	a0,a0,-1
    8020083c:	02051513          	slli	a0,a0,0x20
    80200840:	02055513          	srli	a0,a0,0x20
    80200844:	00005797          	auipc	a5,0x5
    80200848:	80a7b223          	sd	a0,-2044(a5) # 80205048 <seed>
}
    8020084c:	00008067          	ret

0000000080200850 <rand>:

int rand(void) {
  seed = 6364136223846793005ULL * seed + 1;
    80200850:	00004617          	auipc	a2,0x4
    80200854:	7f860613          	addi	a2,a2,2040 # 80205048 <seed>
    80200858:	00063783          	ld	a5,0(a2)
    8020085c:	00479693          	slli	a3,a5,0x4
    80200860:	40f686b3          	sub	a3,a3,a5
    80200864:	00669713          	slli	a4,a3,0x6
    80200868:	40d70733          	sub	a4,a4,a3
    8020086c:	00771693          	slli	a3,a4,0x7
    80200870:	00d70733          	add	a4,a4,a3
    80200874:	00271693          	slli	a3,a4,0x2
    80200878:	00f68733          	add	a4,a3,a5
    8020087c:	00671693          	slli	a3,a4,0x6
    80200880:	40e68733          	sub	a4,a3,a4
    80200884:	00771693          	slli	a3,a4,0x7
    80200888:	00f686b3          	add	a3,a3,a5
    8020088c:	00269713          	slli	a4,a3,0x2
    80200890:	00f70733          	add	a4,a4,a5
    80200894:	00371693          	slli	a3,a4,0x3
    80200898:	40e686b3          	sub	a3,a3,a4
    8020089c:	00369713          	slli	a4,a3,0x3
    802008a0:	40d70733          	sub	a4,a4,a3
    802008a4:	00671693          	slli	a3,a4,0x6
    802008a8:	40e686b3          	sub	a3,a3,a4
    802008ac:	00269713          	slli	a4,a3,0x2
    802008b0:	40f70733          	sub	a4,a4,a5
    802008b4:	00771693          	slli	a3,a4,0x7
    802008b8:	40f686b3          	sub	a3,a3,a5
    802008bc:	00269713          	slli	a4,a3,0x2
    802008c0:	00f70733          	add	a4,a4,a5
    802008c4:	00271693          	slli	a3,a4,0x2
    802008c8:	40f686b3          	sub	a3,a3,a5
    802008cc:	00269713          	slli	a4,a3,0x2
    802008d0:	40f70733          	sub	a4,a4,a5
    802008d4:	00271513          	slli	a0,a4,0x2
    802008d8:	00f50533          	add	a0,a0,a5
    802008dc:	00150513          	addi	a0,a0,1
    802008e0:	00a63023          	sd	a0,0(a2)
  return seed >> 33;
}
    802008e4:	02155513          	srli	a0,a0,0x21
    802008e8:	00008067          	ret

00000000802008ec <memset>:
#include <string.h>

void *memset(void *restrict dst, int c, size_t n) {
    for(size_t i=0; i<n; i++){
    802008ec:	00000793          	li	a5,0
    802008f0:	0100006f          	j	80200900 <memset+0x14>
        ((unsigned char *)dst)[i] = (unsigned char)c;
    802008f4:	00f50733          	add	a4,a0,a5
    802008f8:	00b70023          	sb	a1,0(a4)
    for(size_t i=0; i<n; i++){
    802008fc:	00178793          	addi	a5,a5,1
    80200900:	fec7eae3          	bltu	a5,a2,802008f4 <memset+0x8>
    }

    return dst;
}
    80200904:	00008067          	ret

0000000080200908 <strnlen>:

size_t strnlen(const char *restrict s, size_t maxlen) {
    80200908:	00050713          	mv	a4,a0
    size_t len = 0;
    8020090c:	00000513          	li	a0,0
    while(len < maxlen && s[len] != '\0'){
    80200910:	0080006f          	j	80200918 <strnlen+0x10>
        len++;
    80200914:	00150513          	addi	a0,a0,1
    while(len < maxlen && s[len] != '\0'){
    80200918:	00b57863          	bgeu	a0,a1,80200928 <strnlen+0x20>
    8020091c:	00a707b3          	add	a5,a4,a0
    80200920:	0007c783          	lbu	a5,0(a5)
    80200924:	fe0798e3          	bnez	a5,80200914 <strnlen+0xc>
    }
    return len;
}
    80200928:	00008067          	ret

000000008020092c <memcpy>:

void *memcpy(void *restrict dst, const void *restrict src, size_t n) {
    const char *s = src;
    char *d = dst;
    8020092c:	00050793          	mv	a5,a0
    while (n--) {
    80200930:	0180006f          	j	80200948 <memcpy+0x1c>
        *d++ = *s++;
    80200934:	0005c683          	lbu	a3,0(a1)
    80200938:	00d78023          	sb	a3,0(a5)
    8020093c:	00178793          	addi	a5,a5,1
    80200940:	00158593          	addi	a1,a1,1
    while (n--) {
    80200944:	00070613          	mv	a2,a4
    80200948:	fff60713          	addi	a4,a2,-1
    8020094c:	fe0614e3          	bnez	a2,80200934 <memcpy+0x8>
    }
    return dst;
}
    80200950:	00008067          	ret

0000000080200954 <strlen>:

size_t strlen(const char *s) {
    const char *sc = s;
    80200954:	00050713          	mv	a4,a0
    while (*sc++)
    80200958:	00074783          	lbu	a5,0(a4)
    8020095c:	00170713          	addi	a4,a4,1
    80200960:	fe079ce3          	bnez	a5,80200958 <strlen+0x4>
        ;
    return sc - s - 1;
    80200964:	40a70533          	sub	a0,a4,a0
}
    80200968:	fff50513          	addi	a0,a0,-1
    8020096c:	00008067          	ret

0000000080200970 <strcmp>:

int strcmp(const char *s1, const char *s2) {
    while (*s1 && (*s1 == *s2)) {
    80200970:	00c0006f          	j	8020097c <strcmp+0xc>
        s1++;
    80200974:	00150513          	addi	a0,a0,1
        s2++;
    80200978:	00158593          	addi	a1,a1,1
    while (*s1 && (*s1 == *s2)) {
    8020097c:	00054783          	lbu	a5,0(a0)
    80200980:	00078663          	beqz	a5,8020098c <strcmp+0x1c>
    80200984:	0005c703          	lbu	a4,0(a1)
    80200988:	fee786e3          	beq	a5,a4,80200974 <strcmp+0x4>
    }
    return *(const unsigned char *)s1 - *(const unsigned char *)s2;
    8020098c:	0005c503          	lbu	a0,0(a1)
}
    80200990:	40a7853b          	subw	a0,a5,a0
    80200994:	00008067          	ret

0000000080200998 <pop_arg>:
  // long double f;
  void *p;
};

static void pop_arg(union arg *arg, int type, va_list *ap) {
  switch (type) {
    80200998:	ff85859b          	addiw	a1,a1,-8
    8020099c:	0005871b          	sext.w	a4,a1
    802009a0:	00f00793          	li	a5,15
    802009a4:	1ae7e063          	bltu	a5,a4,80200b44 <pop_arg+0x1ac>
    802009a8:	02059793          	slli	a5,a1,0x20
    802009ac:	01e7d593          	srli	a1,a5,0x1e
    802009b0:	00001717          	auipc	a4,0x1
    802009b4:	74070713          	addi	a4,a4,1856 # 802020f0 <_srodata+0xf0>
    802009b8:	00e585b3          	add	a1,a1,a4
    802009bc:	0005a783          	lw	a5,0(a1)
    802009c0:	00e787b3          	add	a5,a5,a4
    802009c4:	00078067          	jr	a5
    case PTR:
      arg->p = va_arg(*ap, void *);
    802009c8:	00063783          	ld	a5,0(a2)
    802009cc:	00878713          	addi	a4,a5,8
    802009d0:	00e63023          	sd	a4,0(a2)
    802009d4:	0007b783          	ld	a5,0(a5)
    802009d8:	00f53023          	sd	a5,0(a0)
      break;
    802009dc:	00008067          	ret
    case INT:
      arg->i = va_arg(*ap, int);
    802009e0:	00063783          	ld	a5,0(a2)
    802009e4:	00878713          	addi	a4,a5,8
    802009e8:	00e63023          	sd	a4,0(a2)
    802009ec:	0007a783          	lw	a5,0(a5)
    802009f0:	00f53023          	sd	a5,0(a0)
      break;
    802009f4:	00008067          	ret
    case UINT:
      arg->i = va_arg(*ap, unsigned int);
    802009f8:	00063783          	ld	a5,0(a2)
    802009fc:	00878713          	addi	a4,a5,8
    80200a00:	00e63023          	sd	a4,0(a2)
    80200a04:	0007e783          	lwu	a5,0(a5)
    80200a08:	00f53023          	sd	a5,0(a0)
      break;
    80200a0c:	00008067          	ret
    case LONG:
      arg->i = va_arg(*ap, long);
    80200a10:	00063783          	ld	a5,0(a2)
    80200a14:	00878713          	addi	a4,a5,8
    80200a18:	00e63023          	sd	a4,0(a2)
    80200a1c:	0007b783          	ld	a5,0(a5)
    80200a20:	00f53023          	sd	a5,0(a0)
      break;
    80200a24:	00008067          	ret
    case ULONG:
      arg->i = va_arg(*ap, unsigned long);
    80200a28:	00063783          	ld	a5,0(a2)
    80200a2c:	00878713          	addi	a4,a5,8
    80200a30:	00e63023          	sd	a4,0(a2)
    80200a34:	0007b783          	ld	a5,0(a5)
    80200a38:	00f53023          	sd	a5,0(a0)
      break;
    80200a3c:	00008067          	ret
    case ULLONG:
      arg->i = va_arg(*ap, unsigned long long);
    80200a40:	00063783          	ld	a5,0(a2)
    80200a44:	00878713          	addi	a4,a5,8
    80200a48:	00e63023          	sd	a4,0(a2)
    80200a4c:	0007b783          	ld	a5,0(a5)
    80200a50:	00f53023          	sd	a5,0(a0)
      break;
    80200a54:	00008067          	ret
    case SHORT:
      arg->i = (short)va_arg(*ap, int);
    80200a58:	00063783          	ld	a5,0(a2)
    80200a5c:	00878713          	addi	a4,a5,8
    80200a60:	00e63023          	sd	a4,0(a2)
    80200a64:	00079783          	lh	a5,0(a5)
    80200a68:	00f53023          	sd	a5,0(a0)
      break;
    80200a6c:	00008067          	ret
    case USHORT:
      arg->i = (unsigned short)va_arg(*ap, int);
    80200a70:	00063783          	ld	a5,0(a2)
    80200a74:	00878713          	addi	a4,a5,8
    80200a78:	00e63023          	sd	a4,0(a2)
    80200a7c:	0007d783          	lhu	a5,0(a5)
    80200a80:	00f53023          	sd	a5,0(a0)
      break;
    80200a84:	00008067          	ret
    case CHAR:
      arg->i = (signed char)va_arg(*ap, int);
    80200a88:	00063783          	ld	a5,0(a2)
    80200a8c:	00878713          	addi	a4,a5,8
    80200a90:	00e63023          	sd	a4,0(a2)
    80200a94:	00078783          	lb	a5,0(a5)
    80200a98:	00f53023          	sd	a5,0(a0)
      break;
    80200a9c:	00008067          	ret
    case UCHAR:
      arg->i = (unsigned char)va_arg(*ap, int);
    80200aa0:	00063783          	ld	a5,0(a2)
    80200aa4:	00878713          	addi	a4,a5,8
    80200aa8:	00e63023          	sd	a4,0(a2)
    80200aac:	0007c783          	lbu	a5,0(a5)
    80200ab0:	00f53023          	sd	a5,0(a0)
      break;
    80200ab4:	00008067          	ret
    case LLONG:
      arg->i = va_arg(*ap, long long);
    80200ab8:	00063783          	ld	a5,0(a2)
    80200abc:	00878713          	addi	a4,a5,8
    80200ac0:	00e63023          	sd	a4,0(a2)
    80200ac4:	0007b783          	ld	a5,0(a5)
    80200ac8:	00f53023          	sd	a5,0(a0)
      break;
    80200acc:	00008067          	ret
    case SIZET:
      arg->i = va_arg(*ap, size_t);
    80200ad0:	00063783          	ld	a5,0(a2)
    80200ad4:	00878713          	addi	a4,a5,8
    80200ad8:	00e63023          	sd	a4,0(a2)
    80200adc:	0007b783          	ld	a5,0(a5)
    80200ae0:	00f53023          	sd	a5,0(a0)
      break;
    80200ae4:	00008067          	ret
    case IMAX:
      arg->i = va_arg(*ap, intmax_t);
    80200ae8:	00063783          	ld	a5,0(a2)
    80200aec:	00878713          	addi	a4,a5,8
    80200af0:	00e63023          	sd	a4,0(a2)
    80200af4:	0007b783          	ld	a5,0(a5)
    80200af8:	00f53023          	sd	a5,0(a0)
      break;
    80200afc:	00008067          	ret
    case UMAX:
      arg->i = va_arg(*ap, uintmax_t);
    80200b00:	00063783          	ld	a5,0(a2)
    80200b04:	00878713          	addi	a4,a5,8
    80200b08:	00e63023          	sd	a4,0(a2)
    80200b0c:	0007b783          	ld	a5,0(a5)
    80200b10:	00f53023          	sd	a5,0(a0)
      break;
    80200b14:	00008067          	ret
    case PDIFF:
      arg->i = va_arg(*ap, ptrdiff_t);
    80200b18:	00063783          	ld	a5,0(a2)
    80200b1c:	00878713          	addi	a4,a5,8
    80200b20:	00e63023          	sd	a4,0(a2)
    80200b24:	0007b783          	ld	a5,0(a5)
    80200b28:	00f53023          	sd	a5,0(a0)
      break;
    80200b2c:	00008067          	ret
    case UIPTR:
      arg->i = (uintptr_t)va_arg(*ap, void *);
    80200b30:	00063783          	ld	a5,0(a2)
    80200b34:	00878713          	addi	a4,a5,8
    80200b38:	00e63023          	sd	a4,0(a2)
    80200b3c:	0007b783          	ld	a5,0(a5)
    80200b40:	00f53023          	sd	a5,0(a0)
      //   arg->f = va_arg(*ap, double);
      //   break;
      // case LDBL:
      //   arg->f = va_arg(*ap, long double);
  }
}
    80200b44:	00008067          	ret

0000000080200b48 <out>:

static void out(FILE *f, const char *s, size_t l) {
    80200b48:	ff010113          	addi	sp,sp,-16
    80200b4c:	00113423          	sd	ra,8(sp)
  f->write(f, s, l);
    80200b50:	00053783          	ld	a5,0(a0)
    80200b54:	000780e7          	jalr	a5
}
    80200b58:	00813083          	ld	ra,8(sp)
    80200b5c:	01010113          	addi	sp,sp,16
    80200b60:	00008067          	ret

0000000080200b64 <fmt_x>:
  out(f, pad, l);
}

static const char xdigits[16] = {"0123456789ABCDEF"};

static char *fmt_x(uintmax_t x, char *s, int lower) {
    80200b64:	00050793          	mv	a5,a0
    80200b68:	00058513          	mv	a0,a1
  for (; x; x >>= 4)
    80200b6c:	0280006f          	j	80200b94 <fmt_x+0x30>
    *--s = xdigits[(x & 15)] | lower;
    80200b70:	00f7f693          	andi	a3,a5,15
    80200b74:	00002717          	auipc	a4,0x2
    80200b78:	80c70713          	addi	a4,a4,-2036 # 80202380 <xdigits>
    80200b7c:	00d70733          	add	a4,a4,a3
    80200b80:	00074703          	lbu	a4,0(a4)
    80200b84:	fff50513          	addi	a0,a0,-1
    80200b88:	00c76733          	or	a4,a4,a2
    80200b8c:	00e50023          	sb	a4,0(a0)
  for (; x; x >>= 4)
    80200b90:	0047d793          	srli	a5,a5,0x4
    80200b94:	fc079ee3          	bnez	a5,80200b70 <fmt_x+0xc>
  return s;
}
    80200b98:	00008067          	ret

0000000080200b9c <fmt_o>:

static char *fmt_o(uintmax_t x, char *s) {
    80200b9c:	00050793          	mv	a5,a0
    80200ba0:	00058513          	mv	a0,a1
  for (; x; x >>= 3)
    80200ba4:	0180006f          	j	80200bbc <fmt_o+0x20>
    *--s = '0' + (x & 7);
    80200ba8:	0077f713          	andi	a4,a5,7
    80200bac:	fff50513          	addi	a0,a0,-1
    80200bb0:	03070713          	addi	a4,a4,48
    80200bb4:	00e50023          	sb	a4,0(a0)
  for (; x; x >>= 3)
    80200bb8:	0037d793          	srli	a5,a5,0x3
    80200bbc:	fe0796e3          	bnez	a5,80200ba8 <fmt_o+0xc>
  return s;
}
    80200bc0:	00008067          	ret

0000000080200bc4 <fmt_u>:

static char *fmt_u(uintmax_t x, char *s) {
    80200bc4:	fe010113          	addi	sp,sp,-32
    80200bc8:	00113c23          	sd	ra,24(sp)
    80200bcc:	00813823          	sd	s0,16(sp)
    80200bd0:	00913423          	sd	s1,8(sp)
    80200bd4:	00050413          	mv	s0,a0
    80200bd8:	00058493          	mv	s1,a1
  unsigned long y;
  for (; x > ULONG_MAX; x /= 10)
    *--s = '0' + x % 10;
  for (y = x; y; y /= 10)
    80200bdc:	02c0006f          	j	80200c08 <fmt_u+0x44>
    *--s = '0' + y % 10;
    80200be0:	00a00593          	li	a1,10
    80200be4:	00040513          	mv	a0,s0
    80200be8:	bbdff0ef          	jal	ra,802007a4 <__umoddi3>
    80200bec:	fff48493          	addi	s1,s1,-1
    80200bf0:	0305051b          	addiw	a0,a0,48
    80200bf4:	00a48023          	sb	a0,0(s1)
  for (y = x; y; y /= 10)
    80200bf8:	00a00593          	li	a1,10
    80200bfc:	00040513          	mv	a0,s0
    80200c00:	b5dff0ef          	jal	ra,8020075c <__hidden___udivdi3>
    80200c04:	00050413          	mv	s0,a0
    80200c08:	fc041ce3          	bnez	s0,80200be0 <fmt_u+0x1c>
  return s;
}
    80200c0c:	00048513          	mv	a0,s1
    80200c10:	01813083          	ld	ra,24(sp)
    80200c14:	01013403          	ld	s0,16(sp)
    80200c18:	00813483          	ld	s1,8(sp)
    80200c1c:	02010113          	addi	sp,sp,32
    80200c20:	00008067          	ret

0000000080200c24 <getint>:

static int getint(char **s) {
    80200c24:	00050813          	mv	a6,a0
  int i;
  for (i = 0; isdigit(**s); (*s)++) {
    80200c28:	00000513          	li	a0,0
    80200c2c:	0100006f          	j	80200c3c <getint+0x18>
    if (i > INT_MAX / 10 || **s - '0' > INT_MAX - 10 * i)
      i = -1;
    80200c30:	fff00513          	li	a0,-1
  for (i = 0; isdigit(**s); (*s)++) {
    80200c34:	00170713          	addi	a4,a4,1
    80200c38:	00e83023          	sd	a4,0(a6)
    80200c3c:	00083703          	ld	a4,0(a6)
    80200c40:	00074783          	lbu	a5,0(a4)
    80200c44:	0007869b          	sext.w	a3,a5
static inline int iscntrl(int c) {
  return (c >= 0 && c <= 0x1f) || c == 0x7f;
}

static inline int isdigit(int c) {
  return c >= '0' && c <= '9';
    80200c48:	fd07879b          	addiw	a5,a5,-48
    80200c4c:	00900613          	li	a2,9
    80200c50:	04f66463          	bltu	a2,a5,80200c98 <getint+0x74>
    if (i > INT_MAX / 10 || **s - '0' > INT_MAX - 10 * i)
    80200c54:	0cccd7b7          	lui	a5,0xcccd
    80200c58:	ccc78793          	addi	a5,a5,-820 # ccccccc <_skernel-0x73533334>
    80200c5c:	fca7cae3          	blt	a5,a0,80200c30 <getint+0xc>
    80200c60:	fd06859b          	addiw	a1,a3,-48
    80200c64:	0005889b          	sext.w	a7,a1
    80200c68:	0025169b          	slliw	a3,a0,0x2
    80200c6c:	00a686bb          	addw	a3,a3,a0
    80200c70:	0016969b          	slliw	a3,a3,0x1
    80200c74:	40d007bb          	negw	a5,a3
    80200c78:	80000637          	lui	a2,0x80000
    80200c7c:	fff64613          	not	a2,a2
    80200c80:	40d606bb          	subw	a3,a2,a3
    80200c84:	0116c663          	blt	a3,a7,80200c90 <getint+0x6c>
    else
      i = 10 * i + (**s - '0');
    80200c88:	40f5853b          	subw	a0,a1,a5
    80200c8c:	fa9ff06f          	j	80200c34 <getint+0x10>
      i = -1;
    80200c90:	fff00513          	li	a0,-1
    80200c94:	fa1ff06f          	j	80200c34 <getint+0x10>
  }
  return i;
}
    80200c98:	00008067          	ret

0000000080200c9c <pad>:
  if (fl & (LEFT_ADJ | ZERO_PAD) || l >= w)
    80200c9c:	000127b7          	lui	a5,0x12
    80200ca0:	00f77733          	and	a4,a4,a5
    80200ca4:	0007071b          	sext.w	a4,a4
    80200ca8:	08071063          	bnez	a4,80200d28 <pad+0x8c>
static void pad(FILE *f, char c, size_t w, size_t l, int fl) {
    80200cac:	ee010113          	addi	sp,sp,-288
    80200cb0:	10113c23          	sd	ra,280(sp)
    80200cb4:	10813823          	sd	s0,272(sp)
    80200cb8:	10913423          	sd	s1,264(sp)
    80200cbc:	00050493          	mv	s1,a0
  if (fl & (LEFT_ADJ | ZERO_PAD) || l >= w)
    80200cc0:	00c6ec63          	bltu	a3,a2,80200cd8 <pad+0x3c>
}
    80200cc4:	11813083          	ld	ra,280(sp)
    80200cc8:	11013403          	ld	s0,272(sp)
    80200ccc:	10813483          	ld	s1,264(sp)
    80200cd0:	12010113          	addi	sp,sp,288
    80200cd4:	00008067          	ret
  l = w - l;
    80200cd8:	40d60433          	sub	s0,a2,a3
  memset(pad, c, l > sizeof pad ? sizeof pad : l);
    80200cdc:	00040613          	mv	a2,s0
    80200ce0:	10000793          	li	a5,256
    80200ce4:	0087f463          	bgeu	a5,s0,80200cec <pad+0x50>
    80200ce8:	10000613          	li	a2,256
    80200cec:	00010513          	mv	a0,sp
    80200cf0:	bfdff0ef          	jal	ra,802008ec <memset>
  for (; l >= sizeof pad; l -= sizeof pad)
    80200cf4:	0180006f          	j	80200d0c <pad+0x70>
    out(f, pad, sizeof pad);
    80200cf8:	10000613          	li	a2,256
    80200cfc:	00010593          	mv	a1,sp
    80200d00:	00048513          	mv	a0,s1
    80200d04:	e45ff0ef          	jal	ra,80200b48 <out>
  for (; l >= sizeof pad; l -= sizeof pad)
    80200d08:	f0040413          	addi	s0,s0,-256
    80200d0c:	0ff00793          	li	a5,255
    80200d10:	fe87e4e3          	bltu	a5,s0,80200cf8 <pad+0x5c>
  out(f, pad, l);
    80200d14:	00040613          	mv	a2,s0
    80200d18:	00010593          	mv	a1,sp
    80200d1c:	00048513          	mv	a0,s1
    80200d20:	e29ff0ef          	jal	ra,80200b48 <out>
    80200d24:	fa1ff06f          	j	80200cc4 <pad+0x28>
    80200d28:	00008067          	ret

0000000080200d2c <printf_core>:

// theoretically you can implement all other *printf functions using this one...
static int printf_core(FILE *f, const char *fmt, va_list *ap, union arg *nl_arg, int *nl_type) {
    80200d2c:	f4010113          	addi	sp,sp,-192
    80200d30:	0a113c23          	sd	ra,184(sp)
    80200d34:	0a813823          	sd	s0,176(sp)
    80200d38:	0a913423          	sd	s1,168(sp)
    80200d3c:	0b213023          	sd	s2,160(sp)
    80200d40:	09313c23          	sd	s3,152(sp)
    80200d44:	09413823          	sd	s4,144(sp)
    80200d48:	09513423          	sd	s5,136(sp)
    80200d4c:	09613023          	sd	s6,128(sp)
    80200d50:	07713c23          	sd	s7,120(sp)
    80200d54:	07813823          	sd	s8,112(sp)
    80200d58:	07913423          	sd	s9,104(sp)
    80200d5c:	07a13023          	sd	s10,96(sp)
    80200d60:	05b13c23          	sd	s11,88(sp)
    80200d64:	00050b13          	mv	s6,a0
    80200d68:	00060d93          	mv	s11,a2
    80200d6c:	00d13823          	sd	a3,16(sp)
    80200d70:	00e13c23          	sd	a4,24(sp)
  char *a, *z, *s = (char *)fmt;
    80200d74:	04b13423          	sd	a1,72(sp)
  unsigned l10n = 0, fl;
  int w, p, xp;
  union arg arg;
  int argpos;
  unsigned st, ps;
  int cnt = 0, l = 0;
    80200d78:	00000413          	li	s0,0
    80200d7c:	00000a93          	li	s5,0
  unsigned l10n = 0, fl;
    80200d80:	00013023          	sd	zero,0(sp)
    80200d84:	0780006f          	j	80200dfc <printf_core+0xd0>
    cnt += l;
    if (!*s)
      break;

    /* Handle literal text and %% format specifiers */
    for (a = s; *s && *s != '%'; s++)
    80200d88:	00140413          	addi	s0,s0,1
    80200d8c:	04813423          	sd	s0,72(sp)
    80200d90:	04813403          	ld	s0,72(sp)
    80200d94:	00044783          	lbu	a5,0(s0)
    80200d98:	00078e63          	beqz	a5,80200db4 <printf_core+0x88>
    80200d9c:	02500713          	li	a4,37
    80200da0:	fee794e3          	bne	a5,a4,80200d88 <printf_core+0x5c>
    80200da4:	0100006f          	j	80200db4 <printf_core+0x88>
      ;
    for (z = s; s[0] == '%' && s[1] == '%'; z++, s += 2)
    80200da8:	00140413          	addi	s0,s0,1
    80200dac:	00278793          	addi	a5,a5,2 # 12002 <_skernel-0x801edffe>
    80200db0:	04f13423          	sd	a5,72(sp)
    80200db4:	04813783          	ld	a5,72(sp)
    80200db8:	0007c683          	lbu	a3,0(a5)
    80200dbc:	02500713          	li	a4,37
    80200dc0:	00e69663          	bne	a3,a4,80200dcc <printf_core+0xa0>
    80200dc4:	0017c683          	lbu	a3,1(a5)
    80200dc8:	fee680e3          	beq	a3,a4,80200da8 <printf_core+0x7c>
      ;
    if (z - a > INT_MAX - cnt)
    80200dcc:	41440433          	sub	s0,s0,s4
    80200dd0:	800009b7          	lui	s3,0x80000
    80200dd4:	fff9c993          	not	s3,s3
    80200dd8:	417989bb          	subw	s3,s3,s7
    80200ddc:	7a89c263          	blt	s3,s0,80201580 <printf_core+0x854>
      goto overflow;
    l = z - a;
    80200de0:	0004041b          	sext.w	s0,s0
    if (f)
    80200de4:	000b0a63          	beqz	s6,80200df8 <printf_core+0xcc>
      out(f, a, l);
    80200de8:	00040613          	mv	a2,s0
    80200dec:	000a0593          	mv	a1,s4
    80200df0:	000b0513          	mv	a0,s6
    80200df4:	d55ff0ef          	jal	ra,80200b48 <out>
    if (l)
    80200df8:	02040e63          	beqz	s0,80200e34 <printf_core+0x108>
    if (l > INT_MAX - cnt)
    80200dfc:	800007b7          	lui	a5,0x80000
    80200e00:	fff7c793          	not	a5,a5
    80200e04:	415787bb          	subw	a5,a5,s5
    80200e08:	7687c863          	blt	a5,s0,80201578 <printf_core+0x84c>
    cnt += l;
    80200e0c:	008a8bbb          	addw	s7,s5,s0
    80200e10:	000b8a9b          	sext.w	s5,s7
    if (!*s)
    80200e14:	04813a03          	ld	s4,72(sp)
    80200e18:	000a4783          	lbu	a5,0(s4)
    80200e1c:	f6079ae3          	bnez	a5,80200d90 <printf_core+0x64>
    pad(f, ' ', w, pl + p, fl ^ LEFT_ADJ);

    l = w;
  }

  if (f)
    80200e20:	780b1263          	bnez	s6,802015a4 <printf_core+0x878>
    return cnt;
  if (!l10n)
    80200e24:	00013783          	ld	a5,0(sp)
    80200e28:	7e078663          	beqz	a5,80201614 <printf_core+0x8e8>
    return 0;

  for (i = 1; i <= NL_ARGMAX && nl_type[i]; i++)
    80200e2c:	00100413          	li	s0,1
    80200e30:	6f80006f          	j	80201528 <printf_core+0x7fc>
    if (isdigit(s[1]) && s[2] == '$') {
    80200e34:	04813783          	ld	a5,72(sp)
    80200e38:	0017c703          	lbu	a4,1(a5) # ffffffff80000001 <_ekernel+0xfffffffeffdfa001>
    80200e3c:	00070d1b          	sext.w	s10,a4
    80200e40:	fd07071b          	addiw	a4,a4,-48
    80200e44:	00900693          	li	a3,9
    80200e48:	00e6e863          	bltu	a3,a4,80200e58 <printf_core+0x12c>
    80200e4c:	0027c683          	lbu	a3,2(a5)
    80200e50:	02400713          	li	a4,36
    80200e54:	04e68e63          	beq	a3,a4,80200eb0 <printf_core+0x184>
      s++;
    80200e58:	00178793          	addi	a5,a5,1
    80200e5c:	04f13423          	sd	a5,72(sp)
      argpos = -1;
    80200e60:	fff00d13          	li	s10,-1
    for (fl = 0; (unsigned)(*s - ' ') < 32 && (FLAGMASK & (1U << (*s - ' '))); s++)
    80200e64:	00000493          	li	s1,0
    80200e68:	04813703          	ld	a4,72(sp)
    80200e6c:	00074603          	lbu	a2,0(a4)
    80200e70:	fe06079b          	addiw	a5,a2,-32 # 7fffffe0 <_skernel-0x200020>
    80200e74:	0007869b          	sext.w	a3,a5
    80200e78:	01f00593          	li	a1,31
    80200e7c:	04d5e663          	bltu	a1,a3,80200ec8 <printf_core+0x19c>
    80200e80:	000137b7          	lui	a5,0x13
    80200e84:	8097879b          	addiw	a5,a5,-2039 # 12809 <_skernel-0x801ed7f7>
    80200e88:	00d7d7bb          	srlw	a5,a5,a3
    80200e8c:	0017f793          	andi	a5,a5,1
    80200e90:	02078c63          	beqz	a5,80200ec8 <printf_core+0x19c>
      fl |= 1U << (*s - ' ');
    80200e94:	00100793          	li	a5,1
    80200e98:	00d797bb          	sllw	a5,a5,a3
    80200e9c:	00f4e7b3          	or	a5,s1,a5
    80200ea0:	0007849b          	sext.w	s1,a5
    for (fl = 0; (unsigned)(*s - ' ') < 32 && (FLAGMASK & (1U << (*s - ' '))); s++)
    80200ea4:	00170713          	addi	a4,a4,1
    80200ea8:	04e13423          	sd	a4,72(sp)
    80200eac:	fbdff06f          	j	80200e68 <printf_core+0x13c>
      argpos = s[1] - '0';
    80200eb0:	fd0d0d1b          	addiw	s10,s10,-48
      s += 3;
    80200eb4:	00378793          	addi	a5,a5,3
    80200eb8:	04f13423          	sd	a5,72(sp)
      l10n = 1;
    80200ebc:	00100793          	li	a5,1
    80200ec0:	00f13023          	sd	a5,0(sp)
      s += 3;
    80200ec4:	fa1ff06f          	j	80200e64 <printf_core+0x138>
    if (*s == '*') {
    80200ec8:	02a00793          	li	a5,42
    80200ecc:	0af61c63          	bne	a2,a5,80200f84 <printf_core+0x258>
      if (isdigit(s[1]) && s[2] == '$') {
    80200ed0:	00174783          	lbu	a5,1(a4)
    80200ed4:	fd07861b          	addiw	a2,a5,-48
    80200ed8:	00900693          	li	a3,9
    80200edc:	00c6e863          	bltu	a3,a2,80200eec <printf_core+0x1c0>
    80200ee0:	00274683          	lbu	a3,2(a4)
    80200ee4:	02400713          	li	a4,36
    80200ee8:	04e68263          	beq	a3,a4,80200f2c <printf_core+0x200>
      } else if (!l10n) {
    80200eec:	00013783          	ld	a5,0(sp)
    80200ef0:	68079c63          	bnez	a5,80201588 <printf_core+0x85c>
        w = f ? va_arg(*ap, int) : 0;
    80200ef4:	080b0463          	beqz	s6,80200f7c <printf_core+0x250>
    80200ef8:	000db783          	ld	a5,0(s11)
    80200efc:	00878713          	addi	a4,a5,8
    80200f00:	00edb023          	sd	a4,0(s11)
    80200f04:	0007ac03          	lw	s8,0(a5)
        s++;
    80200f08:	04813783          	ld	a5,72(sp)
    80200f0c:	00178793          	addi	a5,a5,1
    80200f10:	04f13423          	sd	a5,72(sp)
      if (w < 0)
    80200f14:	080c5063          	bgez	s8,80200f94 <printf_core+0x268>
        fl |= LEFT_ADJ, w = -w;
    80200f18:	000027b7          	lui	a5,0x2
    80200f1c:	00f4e7b3          	or	a5,s1,a5
    80200f20:	0007849b          	sext.w	s1,a5
    80200f24:	41800c3b          	negw	s8,s8
    80200f28:	06c0006f          	j	80200f94 <printf_core+0x268>
        if (!f)
    80200f2c:	020b0863          	beqz	s6,80200f5c <printf_core+0x230>
          w = nl_arg[s[1] - '0'].i;
    80200f30:	00379793          	slli	a5,a5,0x3
    80200f34:	e8078793          	addi	a5,a5,-384 # 1e80 <_skernel-0x801fe180>
    80200f38:	01013703          	ld	a4,16(sp)
    80200f3c:	00f707b3          	add	a5,a4,a5
    80200f40:	0007ac03          	lw	s8,0(a5)
        s += 3;
    80200f44:	04813783          	ld	a5,72(sp)
    80200f48:	00378793          	addi	a5,a5,3
    80200f4c:	04f13423          	sd	a5,72(sp)
        l10n = 1;
    80200f50:	00100793          	li	a5,1
    80200f54:	00f13023          	sd	a5,0(sp)
        s += 3;
    80200f58:	fbdff06f          	j	80200f14 <printf_core+0x1e8>
          nl_type[s[1] - '0'] = INT, w = 0;
    80200f5c:	00279793          	slli	a5,a5,0x2
    80200f60:	f4078793          	addi	a5,a5,-192
    80200f64:	01813703          	ld	a4,24(sp)
    80200f68:	00f707b3          	add	a5,a4,a5
    80200f6c:	00900713          	li	a4,9
    80200f70:	00e7a023          	sw	a4,0(a5)
    80200f74:	00040c13          	mv	s8,s0
    80200f78:	fcdff06f          	j	80200f44 <printf_core+0x218>
        w = f ? va_arg(*ap, int) : 0;
    80200f7c:	00040c13          	mv	s8,s0
    80200f80:	f89ff06f          	j	80200f08 <printf_core+0x1dc>
    } else if ((w = getint(&s)) < 0)
    80200f84:	04810513          	addi	a0,sp,72
    80200f88:	c9dff0ef          	jal	ra,80200c24 <getint>
    80200f8c:	00050c13          	mv	s8,a0
    80200f90:	60054063          	bltz	a0,80201590 <printf_core+0x864>
    if (*s == '.' && s[1] == '*') {
    80200f94:	04813783          	ld	a5,72(sp)
    80200f98:	0007c703          	lbu	a4,0(a5)
    80200f9c:	02e00693          	li	a3,46
    80200fa0:	0ad71a63          	bne	a4,a3,80201054 <printf_core+0x328>
    80200fa4:	0017c603          	lbu	a2,1(a5)
    80200fa8:	02a00693          	li	a3,42
    80200fac:	0ad61463          	bne	a2,a3,80201054 <printf_core+0x328>
      if (isdigit(s[2]) && s[3] == '$') {
    80200fb0:	0027c703          	lbu	a4,2(a5)
    80200fb4:	fd07061b          	addiw	a2,a4,-48
    80200fb8:	00900693          	li	a3,9
    80200fbc:	00c6e863          	bltu	a3,a2,80200fcc <printf_core+0x2a0>
    80200fc0:	0037c683          	lbu	a3,3(a5)
    80200fc4:	02400793          	li	a5,36
    80200fc8:	02f68e63          	beq	a3,a5,80201004 <printf_core+0x2d8>
      } else if (!l10n) {
    80200fcc:	00013783          	ld	a5,0(sp)
    80200fd0:	5c079463          	bnez	a5,80201598 <printf_core+0x86c>
        p = f ? va_arg(*ap, int) : 0;
    80200fd4:	060b0c63          	beqz	s6,8020104c <printf_core+0x320>
    80200fd8:	000db783          	ld	a5,0(s11)
    80200fdc:	00878713          	addi	a4,a5,8
    80200fe0:	00edb023          	sd	a4,0(s11)
    80200fe4:	0007ac83          	lw	s9,0(a5)
        s += 2;
    80200fe8:	04813783          	ld	a5,72(sp)
    80200fec:	00278793          	addi	a5,a5,2
    80200ff0:	04f13423          	sd	a5,72(sp)
      xp = (p >= 0);
    80200ff4:	fffcc793          	not	a5,s9
    80200ff8:	01f7d79b          	srliw	a5,a5,0x1f
    80200ffc:	00f13423          	sd	a5,8(sp)
    80201000:	0640006f          	j	80201064 <printf_core+0x338>
        if (!f)
    80201004:	020b0463          	beqz	s6,8020102c <printf_core+0x300>
          p = nl_arg[s[2] - '0'].i;
    80201008:	00371793          	slli	a5,a4,0x3
    8020100c:	e8078793          	addi	a5,a5,-384
    80201010:	01013703          	ld	a4,16(sp)
    80201014:	00f707b3          	add	a5,a4,a5
    80201018:	0007ac83          	lw	s9,0(a5)
        s += 4;
    8020101c:	04813783          	ld	a5,72(sp)
    80201020:	00478793          	addi	a5,a5,4
    80201024:	04f13423          	sd	a5,72(sp)
    80201028:	fcdff06f          	j	80200ff4 <printf_core+0x2c8>
          nl_type[s[2] - '0'] = INT, p = 0;
    8020102c:	00271793          	slli	a5,a4,0x2
    80201030:	f4078793          	addi	a5,a5,-192
    80201034:	01813703          	ld	a4,24(sp)
    80201038:	00f707b3          	add	a5,a4,a5
    8020103c:	00900713          	li	a4,9
    80201040:	00e7a023          	sw	a4,0(a5)
    80201044:	00040c93          	mv	s9,s0
    80201048:	fd5ff06f          	j	8020101c <printf_core+0x2f0>
        p = f ? va_arg(*ap, int) : 0;
    8020104c:	00040c93          	mv	s9,s0
    80201050:	f99ff06f          	j	80200fe8 <printf_core+0x2bc>
    } else if (*s == '.') {
    80201054:	02e00693          	li	a3,46
    80201058:	00d70a63          	beq	a4,a3,8020106c <printf_core+0x340>
      xp = 0;
    8020105c:	00813423          	sd	s0,8(sp)
      p = -1;
    80201060:	fff00c93          	li	s9,-1
    st = 0;
    80201064:	00000913          	li	s2,0
    80201068:	0280006f          	j	80201090 <printf_core+0x364>
      s++;
    8020106c:	00178793          	addi	a5,a5,1
    80201070:	04f13423          	sd	a5,72(sp)
      p = getint(&s);
    80201074:	04810513          	addi	a0,sp,72
    80201078:	badff0ef          	jal	ra,80200c24 <getint>
    8020107c:	00050c93          	mv	s9,a0
      xp = 1;
    80201080:	00100793          	li	a5,1
    80201084:	00f13423          	sd	a5,8(sp)
    80201088:	fddff06f          	j	80201064 <printf_core+0x338>
      st = states[st] S(*s++);
    8020108c:	00078913          	mv	s2,a5
      if (OOB(*s))
    80201090:	04813703          	ld	a4,72(sp)
    80201094:	00074783          	lbu	a5,0(a4)
    80201098:	fbf7879b          	addiw	a5,a5,-65
    8020109c:	03900693          	li	a3,57
    802010a0:	50f6e063          	bltu	a3,a5,802015a0 <printf_core+0x874>
      st = states[st] S(*s++);
    802010a4:	00170793          	addi	a5,a4,1
    802010a8:	04f13423          	sd	a5,72(sp)
    802010ac:	00074683          	lbu	a3,0(a4)
    802010b0:	fbf6869b          	addiw	a3,a3,-65
    802010b4:	02091713          	slli	a4,s2,0x20
    802010b8:	02075713          	srli	a4,a4,0x20
    802010bc:	00371793          	slli	a5,a4,0x3
    802010c0:	40e787b3          	sub	a5,a5,a4
    802010c4:	00279793          	slli	a5,a5,0x2
    802010c8:	00e787b3          	add	a5,a5,a4
    802010cc:	00179793          	slli	a5,a5,0x1
    802010d0:	00001717          	auipc	a4,0x1
    802010d4:	11870713          	addi	a4,a4,280 # 802021e8 <states>
    802010d8:	00f707b3          	add	a5,a4,a5
    802010dc:	00d787b3          	add	a5,a5,a3
    802010e0:	0007c583          	lbu	a1,0(a5)
    802010e4:	0005879b          	sext.w	a5,a1
    } while (st - 1 < STOP);
    802010e8:	fff5869b          	addiw	a3,a1,-1
    802010ec:	00600713          	li	a4,6
    802010f0:	f8d77ee3          	bgeu	a4,a3,8020108c <printf_core+0x360>
    if (!st)
    802010f4:	4e078863          	beqz	a5,802015e4 <printf_core+0x8b8>
    if (st == NOARG) {
    802010f8:	01800713          	li	a4,24
    802010fc:	02e78263          	beq	a5,a4,80201120 <printf_core+0x3f4>
      if (argpos >= 0) {
    80201100:	080d4863          	bltz	s10,80201190 <printf_core+0x464>
        if (!f)
    80201104:	060b0c63          	beqz	s6,8020117c <printf_core+0x450>
          arg = nl_arg[argpos];
    80201108:	003d1793          	slli	a5,s10,0x3
    8020110c:	01013703          	ld	a4,16(sp)
    80201110:	00f707b3          	add	a5,a4,a5
    80201114:	0007b783          	ld	a5,0(a5)
    80201118:	04f13023          	sd	a5,64(sp)
    8020111c:	0080006f          	j	80201124 <printf_core+0x3f8>
      if (argpos >= 0)
    80201120:	4c0d5663          	bgez	s10,802015ec <printf_core+0x8c0>
    if (!f)
    80201124:	cc0b0ce3          	beqz	s6,80200dfc <printf_core+0xd0>
    t = s[-1];
    80201128:	04813783          	ld	a5,72(sp)
    8020112c:	fff7c783          	lbu	a5,-1(a5)
    80201130:	00078d1b          	sext.w	s10,a5
    if (fl & LEFT_ADJ)
    80201134:	00002737          	lui	a4,0x2
    80201138:	00e4f733          	and	a4,s1,a4
    8020113c:	0007071b          	sext.w	a4,a4
    80201140:	00070863          	beqz	a4,80201150 <printf_core+0x424>
      fl &= ~ZERO_PAD;
    80201144:	ffff0737          	lui	a4,0xffff0
    80201148:	fff70713          	addi	a4,a4,-1 # fffffffffffeffff <_ekernel+0xffffffff7fde9fff>
    8020114c:	00e4f4b3          	and	s1,s1,a4
    switch (t) {
    80201150:	fa87879b          	addiw	a5,a5,-88
    80201154:	0ff7f693          	zext.b	a3,a5
    80201158:	02000713          	li	a4,32
    8020115c:	2cd76c63          	bltu	a4,a3,80201434 <printf_core+0x708>
    80201160:	00269793          	slli	a5,a3,0x2
    80201164:	00001717          	auipc	a4,0x1
    80201168:	fe470713          	addi	a4,a4,-28 # 80202148 <_srodata+0x148>
    8020116c:	00e787b3          	add	a5,a5,a4
    80201170:	0007a783          	lw	a5,0(a5)
    80201174:	00e787b3          	add	a5,a5,a4
    80201178:	00078067          	jr	a5
          nl_type[argpos] = st;
    8020117c:	002d1793          	slli	a5,s10,0x2
    80201180:	01813703          	ld	a4,24(sp)
    80201184:	00f707b3          	add	a5,a4,a5
    80201188:	00b7a023          	sw	a1,0(a5)
    8020118c:	f99ff06f          	j	80201124 <printf_core+0x3f8>
      } else if (f)
    80201190:	460b0263          	beqz	s6,802015f4 <printf_core+0x8c8>
        pop_arg(&arg, st, ap);
    80201194:	000d8613          	mv	a2,s11
    80201198:	04010513          	addi	a0,sp,64
    8020119c:	ffcff0ef          	jal	ra,80200998 <pop_arg>
    802011a0:	f85ff06f          	j	80201124 <printf_core+0x3f8>
        switch (ps) {
    802011a4:	00600793          	li	a5,6
    802011a8:	c527eae3          	bltu	a5,s2,80200dfc <printf_core+0xd0>
    802011ac:	00291793          	slli	a5,s2,0x2
    802011b0:	00001717          	auipc	a4,0x1
    802011b4:	01c70713          	addi	a4,a4,28 # 802021cc <_srodata+0x1cc>
    802011b8:	00e787b3          	add	a5,a5,a4
    802011bc:	0007a783          	lw	a5,0(a5)
    802011c0:	00e787b3          	add	a5,a5,a4
    802011c4:	00078067          	jr	a5
            *(int *)arg.p = cnt;
    802011c8:	04013783          	ld	a5,64(sp)
    802011cc:	0177a023          	sw	s7,0(a5)
            break;
    802011d0:	c2dff06f          	j	80200dfc <printf_core+0xd0>
            *(long *)arg.p = cnt;
    802011d4:	04013783          	ld	a5,64(sp)
    802011d8:	0157b023          	sd	s5,0(a5)
            break;
    802011dc:	c21ff06f          	j	80200dfc <printf_core+0xd0>
            *(long long *)arg.p = cnt;
    802011e0:	04013783          	ld	a5,64(sp)
    802011e4:	0157b023          	sd	s5,0(a5)
            break;
    802011e8:	c15ff06f          	j	80200dfc <printf_core+0xd0>
            *(unsigned short *)arg.p = cnt;
    802011ec:	04013783          	ld	a5,64(sp)
    802011f0:	01579023          	sh	s5,0(a5)
            break;
    802011f4:	c09ff06f          	j	80200dfc <printf_core+0xd0>
            *(unsigned char *)arg.p = cnt;
    802011f8:	04013783          	ld	a5,64(sp)
    802011fc:	01578023          	sb	s5,0(a5)
            break;
    80201200:	bfdff06f          	j	80200dfc <printf_core+0xd0>
            *(size_t *)arg.p = cnt;
    80201204:	04013783          	ld	a5,64(sp)
    80201208:	0157b023          	sd	s5,0(a5)
            break;
    8020120c:	bf1ff06f          	j	80200dfc <printf_core+0xd0>
            *(uintmax_t *)arg.p = cnt;
    80201210:	04013783          	ld	a5,64(sp)
    80201214:	0157b023          	sd	s5,0(a5)
        continue;
    80201218:	be5ff06f          	j	80200dfc <printf_core+0xd0>
        p = MAX((size_t)p, 2 * sizeof(void *));
    8020121c:	01000793          	li	a5,16
    80201220:	00fcf463          	bgeu	s9,a5,80201228 <printf_core+0x4fc>
    80201224:	01000c93          	li	s9,16
    80201228:	000c8c9b          	sext.w	s9,s9
        fl |= ALT_FORM;
    8020122c:	0084e493          	ori	s1,s1,8
        t = 'x';
    80201230:	07800d13          	li	s10,120
        a = fmt_x(arg.i, z, t & 32);
    80201234:	020d7613          	andi	a2,s10,32
    80201238:	04010593          	addi	a1,sp,64
    8020123c:	04013503          	ld	a0,64(sp)
    80201240:	925ff0ef          	jal	ra,80200b64 <fmt_x>
    80201244:	00050a13          	mv	s4,a0
        if (arg.i && (fl & ALT_FORM))
    80201248:	04013783          	ld	a5,64(sp)
    8020124c:	12078263          	beqz	a5,80201370 <printf_core+0x644>
    80201250:	0084f793          	andi	a5,s1,8
    80201254:	12078463          	beqz	a5,8020137c <printf_core+0x650>
          prefix += (t >> 4), pl = 2;
    80201258:	004d5d13          	srli	s10,s10,0x4
    8020125c:	00001797          	auipc	a5,0x1
    80201260:	ed478793          	addi	a5,a5,-300 # 80202130 <_srodata+0x130>
    80201264:	00fd0d33          	add	s10,s10,a5
    80201268:	00200413          	li	s0,2
    8020126c:	0980006f          	j	80201304 <printf_core+0x5d8>
            a = fmt_o(arg.i, z);
    80201270:	04010593          	addi	a1,sp,64
    80201274:	04013503          	ld	a0,64(sp)
    80201278:	925ff0ef          	jal	ra,80200b9c <fmt_o>
    8020127c:	00050a13          	mv	s4,a0
            if ((fl & ALT_FORM) && p < z - a + 1)
    80201280:	0084f793          	andi	a5,s1,8
    80201284:	10078263          	beqz	a5,80201388 <printf_core+0x65c>
    80201288:	04010793          	addi	a5,sp,64
    8020128c:	40a787b3          	sub	a5,a5,a0
    80201290:	1197c263          	blt	a5,s9,80201394 <printf_core+0x668>
              p = z - a + 1;
    80201294:	00178c9b          	addiw	s9,a5,1
    prefix = "-+   0X0x";
    80201298:	00001d17          	auipc	s10,0x1
    8020129c:	e98d0d13          	addi	s10,s10,-360 # 80202130 <_srodata+0x130>
    802012a0:	0640006f          	j	80201304 <printf_core+0x5d8>
            if (arg.i > INTMAX_MAX) {
    802012a4:	04013783          	ld	a5,64(sp)
    802012a8:	0207c663          	bltz	a5,802012d4 <printf_core+0x5a8>
            } else if (fl & MARK_POS) {
    802012ac:	000017b7          	lui	a5,0x1
    802012b0:	80078793          	addi	a5,a5,-2048 # 800 <_skernel-0x801ff800>
    802012b4:	00f4f7b3          	and	a5,s1,a5
    802012b8:	08079e63          	bnez	a5,80201354 <printf_core+0x628>
            } else if (fl & PAD_POS) {
    802012bc:	0014f793          	andi	a5,s1,1
    802012c0:	0a078263          	beqz	a5,80201364 <printf_core+0x638>
            pl = 1;
    802012c4:	00100413          	li	s0,1
              prefix += 2;
    802012c8:	00001d17          	auipc	s10,0x1
    802012cc:	e6ad0d13          	addi	s10,s10,-406 # 80202132 <_srodata+0x132>
    802012d0:	0240006f          	j	802012f4 <printf_core+0x5c8>
              arg.i = -arg.i;
    802012d4:	40f007b3          	neg	a5,a5
    802012d8:	04f13023          	sd	a5,64(sp)
            pl = 1;
    802012dc:	00100413          	li	s0,1
    prefix = "-+   0X0x";
    802012e0:	00001d17          	auipc	s10,0x1
    802012e4:	e50d0d13          	addi	s10,s10,-432 # 80202130 <_srodata+0x130>
    802012e8:	00c0006f          	j	802012f4 <printf_core+0x5c8>
    switch (t) {
    802012ec:	00001d17          	auipc	s10,0x1
    802012f0:	e44d0d13          	addi	s10,s10,-444 # 80202130 <_srodata+0x130>
            a = fmt_u(arg.i, z);
    802012f4:	04010593          	addi	a1,sp,64
    802012f8:	04013503          	ld	a0,64(sp)
    802012fc:	8c9ff0ef          	jal	ra,80200bc4 <fmt_u>
    80201300:	00050a13          	mv	s4,a0
        if (xp && p < 0)
    80201304:	00813783          	ld	a5,8(sp)
    80201308:	00078463          	beqz	a5,80201310 <printf_core+0x5e4>
    8020130c:	2e0cc863          	bltz	s9,802015fc <printf_core+0x8d0>
        if (xp)
    80201310:	00813783          	ld	a5,8(sp)
    80201314:	00078863          	beqz	a5,80201324 <printf_core+0x5f8>
          fl &= ~ZERO_PAD;
    80201318:	ffff07b7          	lui	a5,0xffff0
    8020131c:	fff78793          	addi	a5,a5,-1 # fffffffffffeffff <_ekernel+0xffffffff7fde9fff>
    80201320:	00f4f4b3          	and	s1,s1,a5
        if (!arg.i && !p) {
    80201324:	04013703          	ld	a4,64(sp)
    80201328:	00071463          	bnez	a4,80201330 <printf_core+0x604>
    8020132c:	1c0c8c63          	beqz	s9,80201504 <printf_core+0x7d8>
        p = MAX(p, z - a + !arg.i);
    80201330:	04010793          	addi	a5,sp,64
    80201334:	414787b3          	sub	a5,a5,s4
    80201338:	00173713          	seqz	a4,a4
    8020133c:	00e787b3          	add	a5,a5,a4
    80201340:	00fcd463          	bge	s9,a5,80201348 <printf_core+0x61c>
    80201344:	00078c93          	mv	s9,a5
    80201348:	000c8c9b          	sext.w	s9,s9
    z = buf + sizeof(buf);
    8020134c:	04010913          	addi	s2,sp,64
        break;
    80201350:	0f00006f          	j	80201440 <printf_core+0x714>
            pl = 1;
    80201354:	00100413          	li	s0,1
              prefix++;
    80201358:	00001d17          	auipc	s10,0x1
    8020135c:	dd9d0d13          	addi	s10,s10,-551 # 80202131 <_srodata+0x131>
    80201360:	f95ff06f          	j	802012f4 <printf_core+0x5c8>
    prefix = "-+   0X0x";
    80201364:	00001d17          	auipc	s10,0x1
    80201368:	dccd0d13          	addi	s10,s10,-564 # 80202130 <_srodata+0x130>
    8020136c:	f89ff06f          	j	802012f4 <printf_core+0x5c8>
    80201370:	00001d17          	auipc	s10,0x1
    80201374:	dc0d0d13          	addi	s10,s10,-576 # 80202130 <_srodata+0x130>
    80201378:	f8dff06f          	j	80201304 <printf_core+0x5d8>
    8020137c:	00001d17          	auipc	s10,0x1
    80201380:	db4d0d13          	addi	s10,s10,-588 # 80202130 <_srodata+0x130>
    80201384:	f81ff06f          	j	80201304 <printf_core+0x5d8>
    80201388:	00001d17          	auipc	s10,0x1
    8020138c:	da8d0d13          	addi	s10,s10,-600 # 80202130 <_srodata+0x130>
    80201390:	f75ff06f          	j	80201304 <printf_core+0x5d8>
    80201394:	00001d17          	auipc	s10,0x1
    80201398:	d9cd0d13          	addi	s10,s10,-612 # 80202130 <_srodata+0x130>
    8020139c:	f69ff06f          	j	80201304 <printf_core+0x5d8>
        *(a = z - (p = 1)) = arg.i;
    802013a0:	04013783          	ld	a5,64(sp)
    802013a4:	02f10fa3          	sb	a5,63(sp)
        fl &= ~ZERO_PAD;
    802013a8:	ffff07b7          	lui	a5,0xffff0
    802013ac:	fff78793          	addi	a5,a5,-1 # fffffffffffeffff <_ekernel+0xffffffff7fde9fff>
    802013b0:	00f4f4b3          	and	s1,s1,a5
    prefix = "-+   0X0x";
    802013b4:	00001d17          	auipc	s10,0x1
    802013b8:	d7cd0d13          	addi	s10,s10,-644 # 80202130 <_srodata+0x130>
        *(a = z - (p = 1)) = arg.i;
    802013bc:	00100c93          	li	s9,1
    z = buf + sizeof(buf);
    802013c0:	04010913          	addi	s2,sp,64
        *(a = z - (p = 1)) = arg.i;
    802013c4:	03f10a13          	addi	s4,sp,63
        break;
    802013c8:	0780006f          	j	80201440 <printf_core+0x714>
        a = arg.p ? arg.p : "(null)";
    802013cc:	04013a03          	ld	s4,64(sp)
    802013d0:	020a0e63          	beqz	s4,8020140c <printf_core+0x6e0>
        z = a + strnlen(a, p < 0 ? INT_MAX : p);
    802013d4:	040cc263          	bltz	s9,80201418 <printf_core+0x6ec>
    802013d8:	000c8593          	mv	a1,s9
    802013dc:	000a0513          	mv	a0,s4
    802013e0:	d28ff0ef          	jal	ra,80200908 <strnlen>
    802013e4:	00050793          	mv	a5,a0
    802013e8:	00aa0933          	add	s2,s4,a0
        if (p < 0 && *z)
    802013ec:	020ccc63          	bltz	s9,80201424 <printf_core+0x6f8>
        p = z - a;
    802013f0:	00078c9b          	sext.w	s9,a5
        fl &= ~ZERO_PAD;
    802013f4:	ffff07b7          	lui	a5,0xffff0
    802013f8:	fff78793          	addi	a5,a5,-1 # fffffffffffeffff <_ekernel+0xffffffff7fde9fff>
    802013fc:	00f4f4b3          	and	s1,s1,a5
    prefix = "-+   0X0x";
    80201400:	00001d17          	auipc	s10,0x1
    80201404:	d30d0d13          	addi	s10,s10,-720 # 80202130 <_srodata+0x130>
        break;
    80201408:	0380006f          	j	80201440 <printf_core+0x714>
        a = arg.p ? arg.p : "(null)";
    8020140c:	00001a17          	auipc	s4,0x1
    80201410:	d34a0a13          	addi	s4,s4,-716 # 80202140 <_srodata+0x140>
    80201414:	fc1ff06f          	j	802013d4 <printf_core+0x6a8>
        z = a + strnlen(a, p < 0 ? INT_MAX : p);
    80201418:	800005b7          	lui	a1,0x80000
    8020141c:	fff5c593          	not	a1,a1
    80201420:	fbdff06f          	j	802013dc <printf_core+0x6b0>
        if (p < 0 && *z)
    80201424:	00094703          	lbu	a4,0(s2)
    80201428:	fc0704e3          	beqz	a4,802013f0 <printf_core+0x6c4>
inval:
  // errno = EINVAL;
  // return -1;
overflow:
  // errno = EOVERFLOW;
  return -1;
    8020142c:	fff00a93          	li	s5,-1
    80201430:	1740006f          	j	802015a4 <printf_core+0x878>
    switch (t) {
    80201434:	00001d17          	auipc	s10,0x1
    80201438:	cfcd0d13          	addi	s10,s10,-772 # 80202130 <_srodata+0x130>
    8020143c:	04010913          	addi	s2,sp,64
    if (p < z - a)
    80201440:	41490933          	sub	s2,s2,s4
    80201444:	012cd463          	bge	s9,s2,8020144c <printf_core+0x720>
      p = z - a;
    80201448:	00090c9b          	sext.w	s9,s2
    if (p > INT_MAX - pl)
    8020144c:	800007b7          	lui	a5,0x80000
    80201450:	fff7c793          	not	a5,a5
    80201454:	408787bb          	subw	a5,a5,s0
    80201458:	1b97c663          	blt	a5,s9,80201604 <printf_core+0x8d8>
    if (w < pl + p)
    8020145c:	008c8bbb          	addw	s7,s9,s0
    80201460:	017c5463          	bge	s8,s7,80201468 <printf_core+0x73c>
      w = pl + p;
    80201464:	000b8c13          	mv	s8,s7
    if (w > INT_MAX - cnt)
    80201468:	1b89c263          	blt	s3,s8,8020160c <printf_core+0x8e0>
    pad(f, ' ', w, pl + p, fl);
    8020146c:	00048713          	mv	a4,s1
    80201470:	000b8693          	mv	a3,s7
    80201474:	000c0613          	mv	a2,s8
    80201478:	02000593          	li	a1,32
    8020147c:	000b0513          	mv	a0,s6
    80201480:	81dff0ef          	jal	ra,80200c9c <pad>
    out(f, prefix, pl);
    80201484:	00040613          	mv	a2,s0
    80201488:	000d0593          	mv	a1,s10
    8020148c:	000b0513          	mv	a0,s6
    80201490:	eb8ff0ef          	jal	ra,80200b48 <out>
    pad(f, '0', w, pl + p, fl ^ ZERO_PAD);
    80201494:	00010737          	lui	a4,0x10
    80201498:	00e4c733          	xor	a4,s1,a4
    8020149c:	0007071b          	sext.w	a4,a4
    802014a0:	000b8693          	mv	a3,s7
    802014a4:	000c0613          	mv	a2,s8
    802014a8:	03000593          	li	a1,48
    802014ac:	000b0513          	mv	a0,s6
    802014b0:	fecff0ef          	jal	ra,80200c9c <pad>
    pad(f, '0', p, z - a, 0);
    802014b4:	00000713          	li	a4,0
    802014b8:	00090693          	mv	a3,s2
    802014bc:	000c8613          	mv	a2,s9
    802014c0:	03000593          	li	a1,48
    802014c4:	000b0513          	mv	a0,s6
    802014c8:	fd4ff0ef          	jal	ra,80200c9c <pad>
    out(f, a, z - a);
    802014cc:	00090613          	mv	a2,s2
    802014d0:	000a0593          	mv	a1,s4
    802014d4:	000b0513          	mv	a0,s6
    802014d8:	e70ff0ef          	jal	ra,80200b48 <out>
    pad(f, ' ', w, pl + p, fl ^ LEFT_ADJ);
    802014dc:	000027b7          	lui	a5,0x2
    802014e0:	00f4c733          	xor	a4,s1,a5
    802014e4:	0007071b          	sext.w	a4,a4
    802014e8:	000b8693          	mv	a3,s7
    802014ec:	000c0613          	mv	a2,s8
    802014f0:	02000593          	li	a1,32
    802014f4:	000b0513          	mv	a0,s6
    802014f8:	fa4ff0ef          	jal	ra,80200c9c <pad>
    l = w;
    802014fc:	000c0413          	mv	s0,s8
    80201500:	8fdff06f          	j	80200dfc <printf_core+0xd0>
    z = buf + sizeof(buf);
    80201504:	04010913          	addi	s2,sp,64
          a = z;
    80201508:	00090a13          	mv	s4,s2
    8020150c:	f35ff06f          	j	80201440 <printf_core+0x714>
    pop_arg(nl_arg + i, nl_type[i], ap);
    80201510:	00341513          	slli	a0,s0,0x3
    80201514:	000d8613          	mv	a2,s11
    80201518:	01013783          	ld	a5,16(sp)
    8020151c:	00a78533          	add	a0,a5,a0
    80201520:	c78ff0ef          	jal	ra,80200998 <pop_arg>
  for (i = 1; i <= NL_ARGMAX && nl_type[i]; i++)
    80201524:	00140413          	addi	s0,s0,1
    80201528:	00900793          	li	a5,9
    8020152c:	0287e063          	bltu	a5,s0,8020154c <printf_core+0x820>
    80201530:	00241793          	slli	a5,s0,0x2
    80201534:	01813703          	ld	a4,24(sp)
    80201538:	00f707b3          	add	a5,a4,a5
    8020153c:	0007a583          	lw	a1,0(a5) # 2000 <_skernel-0x801fe000>
    80201540:	fc0598e3          	bnez	a1,80201510 <printf_core+0x7e4>
    80201544:	0080006f          	j	8020154c <printf_core+0x820>
  for (; i <= NL_ARGMAX && !nl_type[i]; i++)
    80201548:	00140413          	addi	s0,s0,1
    8020154c:	00900793          	li	a5,9
    80201550:	0087ec63          	bltu	a5,s0,80201568 <printf_core+0x83c>
    80201554:	00241793          	slli	a5,s0,0x2
    80201558:	01813703          	ld	a4,24(sp)
    8020155c:	00f707b3          	add	a5,a4,a5
    80201560:	0007a783          	lw	a5,0(a5)
    80201564:	fe0782e3          	beqz	a5,80201548 <printf_core+0x81c>
  if (i <= NL_ARGMAX)
    80201568:	00900793          	li	a5,9
    8020156c:	0a87f863          	bgeu	a5,s0,8020161c <printf_core+0x8f0>
  return 1;
    80201570:	00100a93          	li	s5,1
    80201574:	0300006f          	j	802015a4 <printf_core+0x878>
  return -1;
    80201578:	fff00a93          	li	s5,-1
    8020157c:	0280006f          	j	802015a4 <printf_core+0x878>
    80201580:	fff00a93          	li	s5,-1
    80201584:	0200006f          	j	802015a4 <printf_core+0x878>
    80201588:	fff00a93          	li	s5,-1
    8020158c:	0180006f          	j	802015a4 <printf_core+0x878>
    80201590:	fff00a93          	li	s5,-1
    80201594:	0100006f          	j	802015a4 <printf_core+0x878>
    80201598:	fff00a93          	li	s5,-1
    8020159c:	0080006f          	j	802015a4 <printf_core+0x878>
    802015a0:	fff00a93          	li	s5,-1
}
    802015a4:	000a8513          	mv	a0,s5
    802015a8:	0b813083          	ld	ra,184(sp)
    802015ac:	0b013403          	ld	s0,176(sp)
    802015b0:	0a813483          	ld	s1,168(sp)
    802015b4:	0a013903          	ld	s2,160(sp)
    802015b8:	09813983          	ld	s3,152(sp)
    802015bc:	09013a03          	ld	s4,144(sp)
    802015c0:	08813a83          	ld	s5,136(sp)
    802015c4:	08013b03          	ld	s6,128(sp)
    802015c8:	07813b83          	ld	s7,120(sp)
    802015cc:	07013c03          	ld	s8,112(sp)
    802015d0:	06813c83          	ld	s9,104(sp)
    802015d4:	06013d03          	ld	s10,96(sp)
    802015d8:	05813d83          	ld	s11,88(sp)
    802015dc:	0c010113          	addi	sp,sp,192
    802015e0:	00008067          	ret
  return -1;
    802015e4:	fff00a93          	li	s5,-1
    802015e8:	fbdff06f          	j	802015a4 <printf_core+0x878>
    802015ec:	fff00a93          	li	s5,-1
    802015f0:	fb5ff06f          	j	802015a4 <printf_core+0x878>
        return 0;
    802015f4:	00040a93          	mv	s5,s0
    802015f8:	fadff06f          	j	802015a4 <printf_core+0x878>
  return -1;
    802015fc:	fff00a93          	li	s5,-1
    80201600:	fa5ff06f          	j	802015a4 <printf_core+0x878>
    80201604:	fff00a93          	li	s5,-1
    80201608:	f9dff06f          	j	802015a4 <printf_core+0x878>
    8020160c:	fff00a93          	li	s5,-1
    80201610:	f95ff06f          	j	802015a4 <printf_core+0x878>
    return 0;
    80201614:	00000a93          	li	s5,0
    80201618:	f8dff06f          	j	802015a4 <printf_core+0x878>
  return -1;
    8020161c:	fff00a93          	li	s5,-1
    80201620:	f85ff06f          	j	802015a4 <printf_core+0x878>

0000000080201624 <vfprintf>:
  return ret;
}

#else

int vfprintf(FILE *restrict f, const char *restrict fmt, va_list ap) {
    80201624:	f5010113          	addi	sp,sp,-176
    80201628:	0a113423          	sd	ra,168(sp)
    8020162c:	0a813023          	sd	s0,160(sp)
    80201630:	08913c23          	sd	s1,152(sp)
    80201634:	00050413          	mv	s0,a0
    80201638:	00058493          	mv	s1,a1
    8020163c:	00c13423          	sd	a2,8(sp)
  int nl_type[NL_ARGMAX + 1] = {0};
    80201640:	06013423          	sd	zero,104(sp)
    80201644:	06013823          	sd	zero,112(sp)
    80201648:	06013c23          	sd	zero,120(sp)
    8020164c:	08013023          	sd	zero,128(sp)
    80201650:	08013423          	sd	zero,136(sp)
  union arg nl_arg[NL_ARGMAX + 1];

  // preprocess nl arguments
  va_list ap2;
  va_copy(ap2, ap);
    80201654:	00c13823          	sd	a2,16(sp)
  int ret = printf_core(0, fmt, &ap2, nl_arg, nl_type);
    80201658:	06810713          	addi	a4,sp,104
    8020165c:	01810693          	addi	a3,sp,24
    80201660:	01010613          	addi	a2,sp,16
    80201664:	00000513          	li	a0,0
    80201668:	ec4ff0ef          	jal	ra,80200d2c <printf_core>
  va_end(ap2);

  if (ret < 0) {
    8020166c:	00054e63          	bltz	a0,80201688 <vfprintf+0x64>
    return ret;
  }
  return printf_core(f, fmt, &ap, nl_arg, nl_type);
    80201670:	06810713          	addi	a4,sp,104
    80201674:	01810693          	addi	a3,sp,24
    80201678:	00810613          	addi	a2,sp,8
    8020167c:	00048593          	mv	a1,s1
    80201680:	00040513          	mv	a0,s0
    80201684:	ea8ff0ef          	jal	ra,80200d2c <printf_core>
}
    80201688:	0a813083          	ld	ra,168(sp)
    8020168c:	0a013403          	ld	s0,160(sp)
    80201690:	09813483          	ld	s1,152(sp)
    80201694:	0b010113          	addi	sp,sp,176
    80201698:	00008067          	ret

000000008020169c <snprintf_write>:
    size_t size;     // 缓冲区大小
    size_t count;    // 已尝试写入的字符总数
};

// 自定义的 write 函数，用于将数据写入缓冲区
static int snprintf_write(FILE *f, const void *buf, size_t len) {
    8020169c:	fe010113          	addi	sp,sp,-32
    802016a0:	00113c23          	sd	ra,24(sp)
    802016a4:	00813823          	sd	s0,16(sp)
    802016a8:	00913423          	sd	s1,8(sp)
    802016ac:	00050413          	mv	s0,a0
    802016b0:	00060493          	mv	s1,a2
    struct snprintf_state *s = (struct snprintf_state *)f;
    size_t to_copy = len;

    // 如果缓冲区还有空间，则写入数据
    // 注意我们要预留一个字节给 '\0'，所以是 size - 1
    if (s->size > 0) {
    802016b4:	01053603          	ld	a2,16(a0)
    802016b8:	02060663          	beqz	a2,802016e4 <snprintf_write+0x48>
        if (s->count < s->size - 1) {
    802016bc:	01853783          	ld	a5,24(a0)
    802016c0:	fff60713          	addi	a4,a2,-1
    802016c4:	02e7f063          	bgeu	a5,a4,802016e4 <snprintf_write+0x48>
            size_t available = s->size - s->count - 1;
    802016c8:	40f60633          	sub	a2,a2,a5
    802016cc:	fff60613          	addi	a2,a2,-1
            if (to_copy > available) {
    802016d0:	00966463          	bltu	a2,s1,802016d8 <snprintf_write+0x3c>
    size_t to_copy = len;
    802016d4:	00048613          	mv	a2,s1
                to_copy = available;
            }
            memcpy(s->buf + s->count, buf, to_copy);
    802016d8:	00843503          	ld	a0,8(s0)
    802016dc:	00f50533          	add	a0,a0,a5
    802016e0:	a4cff0ef          	jal	ra,8020092c <memcpy>
        }
    }

    // 无论是否写入，都增加计数，以符合 snprintf 的返回值定义
    s->count += len;
    802016e4:	01843783          	ld	a5,24(s0)
    802016e8:	009787b3          	add	a5,a5,s1
    802016ec:	00f43c23          	sd	a5,24(s0)
    return len;
}
    802016f0:	0004851b          	sext.w	a0,s1
    802016f4:	01813083          	ld	ra,24(sp)
    802016f8:	01013403          	ld	s0,16(sp)
    802016fc:	00813483          	ld	s1,8(sp)
    80201700:	02010113          	addi	sp,sp,32
    80201704:	00008067          	ret

0000000080201708 <vsnprintf>:

int vsnprintf(char *restrict s, size_t n, const char *restrict format, va_list ap) {
    80201708:	fd010113          	addi	sp,sp,-48
    8020170c:	02113423          	sd	ra,40(sp)
    80201710:	00060793          	mv	a5,a2
    struct snprintf_state state = {
    80201714:	00000717          	auipc	a4,0x0
    80201718:	f8870713          	addi	a4,a4,-120 # 8020169c <snprintf_write>
    8020171c:	00e13023          	sd	a4,0(sp)
    80201720:	00a13423          	sd	a0,8(sp)
    80201724:	00b13823          	sd	a1,16(sp)
    80201728:	00013c23          	sd	zero,24(sp)
        .size = n,
        .count = 0
    };

    // 调用 vfprintf 进行格式化输出
    vfprintf(&state.f, format, ap);
    8020172c:	00068613          	mv	a2,a3
    80201730:	00078593          	mv	a1,a5
    80201734:	00010513          	mv	a0,sp
    80201738:	eedff0ef          	jal	ra,80201624 <vfprintf>

    // 确保字符串以 null 结尾
    if (state.size > 0) {
    8020173c:	01013783          	ld	a5,16(sp)
    80201740:	00078c63          	beqz	a5,80201758 <vsnprintf+0x50>
        if (state.count < state.size) {
    80201744:	01813703          	ld	a4,24(sp)
    80201748:	02f77063          	bgeu	a4,a5,80201768 <vsnprintf+0x60>
            state.buf[state.count] = '\0';
    8020174c:	00813783          	ld	a5,8(sp)
    80201750:	00e787b3          	add	a5,a5,a4
    80201754:	00078023          	sb	zero,0(a5)
            state.buf[state.size - 1] = '\0';
        }
    }

    return state.count;
}
    80201758:	01812503          	lw	a0,24(sp)
    8020175c:	02813083          	ld	ra,40(sp)
    80201760:	03010113          	addi	sp,sp,48
    80201764:	00008067          	ret
            state.buf[state.size - 1] = '\0';
    80201768:	fff78793          	addi	a5,a5,-1
    8020176c:	00813703          	ld	a4,8(sp)
    80201770:	00f707b3          	add	a5,a4,a5
    80201774:	00078023          	sb	zero,0(a5)
    80201778:	fe1ff06f          	j	80201758 <vsnprintf+0x50>

000000008020177c <snprintf>:

int snprintf(char *restrict s, size_t n, const char *restrict format, ...) {
    8020177c:	fb010113          	addi	sp,sp,-80
    80201780:	00113c23          	sd	ra,24(sp)
    80201784:	02d13423          	sd	a3,40(sp)
    80201788:	02e13823          	sd	a4,48(sp)
    8020178c:	02f13c23          	sd	a5,56(sp)
    80201790:	05013023          	sd	a6,64(sp)
    80201794:	05113423          	sd	a7,72(sp)
    va_list ap;
    va_start(ap, format);
    80201798:	02810693          	addi	a3,sp,40
    8020179c:	00d13423          	sd	a3,8(sp)
    int ret = vsnprintf(s, n, format, ap);
    802017a0:	f69ff0ef          	jal	ra,80201708 <vsnprintf>
    va_end(ap);
    return ret;
}
    802017a4:	01813083          	ld	ra,24(sp)
    802017a8:	05010113          	addi	sp,sp,80
    802017ac:	00008067          	ret

00000000802017b0 <sprintf>:

int sprintf(char *restrict s, const char *restrict format, ...) {
    802017b0:	fb010113          	addi	sp,sp,-80
    802017b4:	00113c23          	sd	ra,24(sp)
    802017b8:	02c13023          	sd	a2,32(sp)
    802017bc:	02d13423          	sd	a3,40(sp)
    802017c0:	02e13823          	sd	a4,48(sp)
    802017c4:	02f13c23          	sd	a5,56(sp)
    802017c8:	05013023          	sd	a6,64(sp)
    802017cc:	05113423          	sd	a7,72(sp)
    va_list ap;
    va_start(ap, format);
    802017d0:	02010693          	addi	a3,sp,32
    802017d4:	00d13423          	sd	a3,8(sp)
    // sprintf 假设缓冲区足够大，我们传入 INT_MAX 作为限制
    int ret = vsnprintf(s, INT_MAX, format, ap);
    802017d8:	00058613          	mv	a2,a1
    802017dc:	800005b7          	lui	a1,0x80000
    802017e0:	fff5c593          	not	a1,a1
    802017e4:	f25ff0ef          	jal	ra,80201708 <vsnprintf>
    va_end(ap);
    return ret;
    802017e8:	01813083          	ld	ra,24(sp)
    802017ec:	05010113          	addi	sp,sp,80
    802017f0:	00008067          	ret
