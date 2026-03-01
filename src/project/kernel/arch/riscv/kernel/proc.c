#include <mm.h>
#include <proc.h>
#include <stdlib.h>
#include <printk.h>
#include <private_kdefs.h>
#include <stddef.h>

// 静态断言检查偏移量是否一致
_Static_assert(TASK_THREAD_OFFSET == offsetof(struct task_struct, thread), "TASK_THREAD_OFFSET error");
_Static_assert(TASK_THREAD_RA == offsetof(struct thread_struct, ra), "TASK_THREAD_RA error");
_Static_assert(TASK_THREAD_SP == offsetof(struct thread_struct, sp), "TASK_THREAD_SP error");
_Static_assert(TASK_THREAD_S0 == offsetof(struct thread_struct, s[0]), "TASK_THREAD_S0 error");

static struct task_struct *task[NR_TASKS]; // 线程数组，所有的线程都保存在此
static struct task_struct *idle;           // idle 线程
struct task_struct *current;               // 当前运行线程

void __dummy(void);
void __switch_to(struct task_struct *prev, struct task_struct *next);

// 在这里添加或实现这些函数：
// - void dummy_task(void);
// - void task_init(void);
// - void do_timer(void);
// - void schedule(void);
// - void switch_to(struct task_struct* next);

void dummy_task(void) {
    unsigned local = 0;
    unsigned prev_cnt = 0;
    while (1) {
        if (current->counter != prev_cnt) {
            if (current->counter == 1) {
            // 若 priority 为 1，则线程可见的 counter 永远为 1（为什么？）
            // 通过设置 counter 为 0，避免信息无法打印的问题
            current->counter = 0;
            }
            prev_cnt = current->counter;
            printk("[P = %" PRIu64 "] %u\n", current->pid, ++local);
        }
    }
}

void task_init(void){
    srand(2025);
    // 1. 调用 alloc_page() 为 idle 分配一个物理页
    idle = (struct task_struct*)alloc_page();

    // 2. 初始化 idle 线程：
    //   - state 为5 TASK_RUNNING
    //   - pid 为 0
    //   - 由于其不参与调度，可以将 priority 和 counter 设为 0
    idle->state = TASK_RUNNING;
    idle->pid = 0;
    idle->priority = 0;
    idle->counter = 0;

    // 3. 将 current 和 task[0] 指向 idle
    current = idle;
    task[0] = idle;

    // 4. 初始化 task[1..NR_TASKS - 1]：
    for(int i=1; i<NR_TASKS; i++){
        // 分配一个物理页
        task[i] = (struct task_struct*)alloc_page();
        // 初始化
        task[i]->state = TASK_RUNNING;
        task[i]->pid = i;
        task[i]->priority = (rand() % (PRIORITY_MAX - PRIORITY_MIN + 1)) + PRIORITY_MIN;
        task[i]->counter = 0;
        // 设置 thread_struct 中的 ra 和 sp：
        // ra 设置为 __dummy 的地址
        task[i]->thread.ra = (uint64_t)__dummy;
        // sp 设置为该线程申请的物理页的高地址
        task[i]->thread.sp = (uint64_t)task[i] + PGSIZE;
    }

    printk("...task_init done!\n");
}

// 全局计时器
static int ticks = 0;

void do_timer(void){
    /*
    if(ticks >= 10){
        ticks = 0;
        printk("Force reset counters due to ticks >= 10\n");
        // 强制重置所有线程的 counter
        for(int i=1; i<NR_TASKS; i++){
             task[i]->counter = task[i]->priority;
             printk("SET [PID = %" PRIu64 ", PRIORITY = %" PRIu64 ", COUNTER = %" PRIu64 "]\n",
                    task[i]->pid, task[i]->priority, task[i]->counter);
        }
        schedule();
    }
    */
    // 1. 如果当前线程时间片耗尽，则直接进行调度
    if(current->counter == 0){
        schedule();
    }
    // 2. 否则将运行剩余时间减 1，若剩余时间仍然大于 0 则直接返回，否则进行调度
    else{
        current->counter--;
        ticks++;
        if(current->counter == 0){
            schedule();
        }
    }
}

// 全局计时器
//static int ticks = 0;

void schedule(void){
    struct task_struct *next = NULL;
    long max_counter = -1;

    /*
    ticks++;
    // 如果调度次数达到 10 次，强制重置所有线程的 counter
    if (ticks >= 10) {
        printk("Force reset counters due to ticks >= 10\n");
        for (int i = 1; i < NR_TASKS; i++) {
            task[i]->counter = task[i]->priority;
            printk("SET [PID = %" PRIu64 ", PRIORITY = %" PRIu64 ", COUNTER = %" PRIu64 "]\n",
                   task[i]->pid, task[i]->priority, task[i]->counter);
        }
        ticks = 0; // 重置计数器
    }
    */

    while(1){
        // 1. 在所有可运行线程中寻找counter最大的线程
        for(int i=1; i<NR_TASKS; i++){
            if(task[i]->state == TASK_RUNNING && (long)task[i]->counter > max_counter){
                max_counter = task[i]->counter;
                next = task[i];
            }
        }

        // 2. 如果所有现成的counter均为0，则将counter设置为priority然后重复第一步
        if(max_counter == 0){
            for(int i=1; i<NR_TASKS; i++){
                task[i]->counter = task[i]->priority;
                printk("S [%" PRIu64 ", %" PRIu64 ", %" PRIu64 "]\n",
                       task[i]->pid, task[i]->priority, task[i]->counter);
            }
            max_counter = -1;
            next = NULL;
        }else{
            break;
        }
    }

    // 3. 调用 switch_to 进行线程切换
    if(next){
        printk("s 2 [%" PRIu64 ", %" PRIu64 ", %" PRIu64 "]\n",
               next->pid, next->priority, next->counter);   
        switch_to(next);
    }
}

void switch_to(struct task_struct *next){
    if(current != next){
        struct task_struct *prev = current;
        current = next;
        __switch_to(prev, next);
    }
}
