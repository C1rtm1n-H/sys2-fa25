#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <limits.h>

// 定义一个结构体来保存 snprintf 的状态
struct snprintf_state {
    FILE f;          // 必须是第一个成员，以便可以强制转换为 FILE*
    char *buf;       // 目标缓冲区
    size_t size;     // 缓冲区大小
    size_t count;    // 已尝试写入的字符总数
};

// 自定义的 write 函数，用于将数据写入缓冲区
static int snprintf_write(FILE *f, const void *buf, size_t len) {
    struct snprintf_state *s = (struct snprintf_state *)f;
    size_t to_copy = len;

    // 如果缓冲区还有空间，则写入数据
    // 注意我们要预留一个字节给 '\0'，所以是 size - 1
    if (s->size > 0) {
        if (s->count < s->size - 1) {
            size_t available = s->size - s->count - 1;
            if (to_copy > available) {
                to_copy = available;
            }
            memcpy(s->buf + s->count, buf, to_copy);
        }
    }

    // 无论是否写入，都增加计数，以符合 snprintf 的返回值定义
    s->count += len;
    return len;
}

int vsnprintf(char *restrict s, size_t n, const char *restrict format, va_list ap) {
    struct snprintf_state state = {
        .f = { .write = snprintf_write },
        .buf = s,
        .size = n,
        .count = 0
    };

    // 调用 vfprintf 进行格式化输出
    vfprintf(&state.f, format, ap);

    // 确保字符串以 null 结尾
    if (state.size > 0) {
        if (state.count < state.size) {
            state.buf[state.count] = '\0';
        } else {
            state.buf[state.size - 1] = '\0';
        }
    }

    return state.count;
}

int snprintf(char *restrict s, size_t n, const char *restrict format, ...) {
    va_list ap;
    va_start(ap, format);
    int ret = vsnprintf(s, n, format, ap);
    va_end(ap);
    return ret;
}

int sprintf(char *restrict s, const char *restrict format, ...) {
    va_list ap;
    va_start(ap, format);
    // sprintf 假设缓冲区足够大，我们传入 INT_MAX 作为限制
    int ret = vsnprintf(s, INT_MAX, format, ap);
    va_end(ap);
    return ret;
}