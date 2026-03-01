#include <print.h>
#include <sbi.h>

void puts(const char *s) {
    // Calculate length
    uint64_t len = 0;
    while(s[len] != '\0') {
        len++;
    }
    // Call SBI ecall to write string
    sbi_ecall(0x4442434e, 0, len, (uint64_t)s, 0, 0, 0, 0);
}

void puti(int i) {
    char buf[32];
    int idx = 0;
    int is_neg = 0;
    long long val = i;

    // i == 0
    if(val == 0){
        puts("0");
        return;
    }

    // i < 0
    if(val < 0){
        is_neg = 1;
        val = -val;
    }

    // Convert to string in reverse order
    while(val > 0){
        buf[idx++] = (val % 10) + '0';
        val /= 10;
    }
    if(is_neg){
        buf[idx++] = '-';
    }

    // Print in correct order
    for(int j = idx - 1; j >= 0; j--){
        sbi_ecall(0x4442434e, 0, 1, (uint64_t)(buf + j), 0, 0, 0, 0);
    }
}