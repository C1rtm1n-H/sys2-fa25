#include <mm.h>
#include <proc.h>

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
#error Not yet implemented
