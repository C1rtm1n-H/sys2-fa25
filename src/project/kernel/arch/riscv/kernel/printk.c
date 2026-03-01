#include <stdio.h>
#include <printk.h>
#include <sbi.h>

static int printk_sbi_write(FILE *restrict fp, const void *restrict buf, size_t len) {
  (void)fp; // unused

  // 调用 SBI 接口输出 buf 中长度为 len 的内容
  // 返回实际输出的字节数
  // Hint：阅读 SBI v2.0 规范！

  // EID = 0x4442434E (sbi_debug_console_write)
  // FID = 0
  // arg0 = number of bytes
  // arg1 = base address low
  // arg2 = base address high
  struct sbiret ret = sbi_ecall(0x4442434E, 0, len, (uint64_t)buf, 0, 0, 0, 0);
  
  if(ret.error != 0){
    return 0;
  }
  // 返回实际写入的字节数
  return (int)ret.value;
}

void printk(const char *fmt, ...) {
  FILE printk_out = {
      .write = printk_sbi_write,
  };

  va_list ap;
  va_start(ap, fmt);
  vfprintf(&printk_out, fmt, ap);
  va_end(ap);
}
