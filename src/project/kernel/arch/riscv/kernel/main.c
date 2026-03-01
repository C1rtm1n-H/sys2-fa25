#include <printk.h>
#include <sbi.h>
#include <private_kdefs.h>
#include <proc.h>

_Noreturn void start_kernel(void){
  task_init();
  printk("2025 ZJU Computer System II\n");

  // 直接调用schedule
  //schedule();

  // 等待第一次时钟中断
  while(1);
}

