#include <stdint.h>
#include <printk.h>
#include <proc.h>

void clock_set_next_event(void);

void trap_handler(uint64_t scause, uint64_t sepc) {
  // 根据 scause 判断 trap 类型
  // 如果是 Supervisor Timer Interrupt：
  // - 打印输出相关信息
  // - 调用 clock_set_next_event 设置下一次时钟中断
  // 其他类型的 trap 可以直接忽略，推荐打印出来供以后调试

  // 判断是否为中断(0x8000000000000000为最高位掩码)
  int is_interrupt = (scause & 0x8000000000000000UL) ? 1 : 0;
  // 获取exception code(0x7FFFFFFFFFFFFFFF为低63位掩码)
  uint64_t exception_code = scause & 0x7FFFFFFFFFFFFFFF;

  if(is_interrupt){
    // 处理中断
    if(exception_code == 5){
      //printk("[S] Supervisor timer interrupt\n");
      clock_set_next_event();
      do_timer();
    }else{
      // 其他中断
      printk("Unknown interrupt: scause = %lx, sepc = %lx\n", scause, sepc);
    }
  }else{
    // 处理异常
    printk("Unknown exception: scause = %lx, sepc = %lx\n", scause, sepc);
    // 死循环
    while(1);
  }
}
