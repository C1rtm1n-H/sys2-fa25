#include <stdint.h>
#include <private_kdefs.h>
#include <sbi.h>


void clock_set_next_event(void) {
  //uint64_t time;

  // 1. 使用 rdtime 指令读取当前时间
  //asm volatile("rdtime %0" : "=r"(time));

  // 2. 计算下一次中断的时间
  //uint64_t next = time + TIMECLOCK;

  // 3. 调用 sbi_set_timer 设置下一次时钟中断
  // EID = 0x54494D45 (TIME Extension)
  // FID = 0 (sbi_set_timer)
  // arg0 = stime_value (next)
  sbi_ecall(0x54494D45, 0, TIMECLOCK, 0, 0, 0, 0, 0);
}

/*
static uint64_t last_time = 0; // 记录上一次中断时间
void clock_set_next_event() {
    uint64_t time;
    if (last_time == 0) {
        asm volatile("rdtime %0" : "=r"(time)); // 获取当前时间
        last_time = time;
    }
    last_time += TIMECLOCK;       // 下一次 = 上一次 + 间隔
    sbi_ecall(0x54494D45, 0, last_time, 0, 0, 0, 0, 0);
}
*/