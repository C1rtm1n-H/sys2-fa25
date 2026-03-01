#include <string.h>

void *memset(void *restrict dst, int c, size_t n) {
    for(size_t i=0; i<n; i++){
        ((unsigned char *)dst)[i] = (unsigned char)c;
    }

    return dst;
}

size_t strnlen(const char *restrict s, size_t maxlen) {
    size_t len = 0;
    while(len < maxlen && s[len] != '\0'){
        len++;
    }
    return len;
}

void *memcpy(void *restrict dst, const void *restrict src, size_t n) {
    const char *s = src;
    char *d = dst;
    while (n--) {
        *d++ = *s++;
    }
    return dst;
}

size_t strlen(const char *s) {
    const char *sc = s;
    while (*sc++)
        ;
    return sc - s - 1;
}

int strcmp(const char *s1, const char *s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(const unsigned char *)s1 - *(const unsigned char *)s2;
}
