#ifndef __PRIVATE_KDEFS_H__
#define __PRIVATE_KDEFS_H__

// QEMU virt 机器的时钟频率为 10 MHz
#define TIMECLOCK 200000

#define PHY_START 0x80000000
#define PHY_SIZE 0x400000 // 4 MiB
#define PHY_END (PHY_START + PHY_SIZE)

#define PGSIZE 0x1000 // 4 KiB
#define PGROUNDDOWN(addr) ((addr) & ~(PGSIZE - 1))
#define PGROUNDUP(addr) PGROUNDDOWN((addr) + PGSIZE - 1)

// 线程结构体偏移量定义
#define TASK_THREAD_RA  0
#define TASK_THREAD_SP  8
#define TASK_THREAD_S0  16
#define TASK_THREAD_S1  24
#define TASK_THREAD_S2  32
#define TASK_THREAD_S3  40
#define TASK_THREAD_S4  48
#define TASK_THREAD_S5  56
#define TASK_THREAD_S6  64
#define TASK_THREAD_S7  72
#define TASK_THREAD_S8  80
#define TASK_THREAD_S9  88
#define TASK_THREAD_S10 96
#define TASK_THREAD_S11 104

#define TASK_THREAD_OFFSET 32

#endif
