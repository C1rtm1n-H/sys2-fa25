#include "conv.h"

typedef unsigned long long int size_t;
uint64_t* CONV_BASE = (uint64_t*)0x10001000L;
const size_t CONV_KERNEL_OFFSET = 0;
const size_t CONV_DATA_OFFSET = 1;
const size_t CONV_RESULT_LO_OFFSET = 0;
const size_t CONV_RESULT_HI_OFFSET = 1;
const size_t CONV_STATE_OFFSET = 2;
const unsigned char READY_MASK = 0b01;
const size_t CONV_ELEMENT_LEN = 4;

uint64_t* MISC_BASE = (uint64_t*)0x10002000L;
const size_t MISC_TIME_OFFSET = 0;

uint64_t get_time(void){
    return MISC_BASE[MISC_TIME_OFFSET];
}

static void conv_kernel_init(const uint64_t* kernel_array, size_t kernel_len){
    for(size_t i=0; i<kernel_len; i++){
        CONV_BASE[CONV_KERNEL_OFFSET] = kernel_array[i];
    }
}

static void conv_compute_one_byte(uint64_t data, size_t kernel_len, uint64_t* dest_lo, uint64_t* dest_hi){
    CONV_BASE[CONV_DATA_OFFSET] = data;
    // Start computation
    CONV_BASE[CONV_STATE_OFFSET] = 0b10; // Set to BUSY
    // Wait for completion
    while((CONV_BASE[CONV_STATE_OFFSET] & READY_MASK) == 0){
        // busy wait
    }
    // Read result
    *dest_lo = CONV_BASE[CONV_RESULT_LO_OFFSET];
    *dest_hi = CONV_BASE[CONV_RESULT_HI_OFFSET];
}

void conv_compute(const uint64_t* data_array, size_t data_len, const uint64_t* kernel_array, size_t kernel_len, uint64_t* dest){
    // Initialize kernel
    conv_kernel_init(kernel_array, kernel_len);

    const size_t total_inputs = data_len + 2*(kernel_len - 1);
    const size_t total_computations = data_len + kernel_len - 1;
    // Compute each byte
    for(size_t i = 0; i < total_inputs; i++){
        long long data_idx = (long long)i - (long long)(kernel_len - 1);
        uint64_t input_data = 0;
        // zero padding
        if (data_idx >= 0 && data_idx < data_len) {
            input_data = data_array[data_idx];
        }
        uint64_t dest_lo, dest_hi;
        conv_compute_one_byte(input_data, kernel_len, &dest_lo, &dest_hi);

        //dest[i<<1]       = dest_hi;
        //dest[(i<<1) + 1] = dest_lo;
        if (i >= kernel_len - 1) {
            size_t dest_idx = i - (kernel_len - 1);
            if (dest_idx < total_computations) {
                dest[dest_idx << 1]       = dest_hi;
                dest[(dest_idx << 1) + 1] = dest_lo;
            }
        }
    }
    
}

/*
// Calculate a + b
static void add_64to128(uint64_t a_hi, uint64_t a_lo, uint64_t b_hi, uint64_t b_lo, uint64_t* res_hi, uint64_t* res_lo){
    uint64_t lo = a_lo + b_lo;
    uint64_t carry = (lo < a_lo) ? 1 : 0; // check overflow
    uint64_t hi = a_hi + b_hi + carry;

    *res_hi = hi;
    *res_lo = lo;
}

// Calculate a * b without using *
static void multiply_64to128(uint64_t a, uint64_t b, uint64_t* res_hi, uint64_t* res_lo){
    uint64_t hi = 0, lo = 0;

    for(int i = 0; i < 64; i++){
        if((b >> i) & 1){
            // Add (a << i) to the result
            uint64_t add_lo = a << i;
            uint64_t add_hi = (i==0) ? 0 : (a >> (64 - i)); // upper bits that overflow

            uint64_t new_lo = lo + add_lo;
            uint64_t carry = (new_lo < lo) ? 1 : 0; // check overflow
            uint64_t new_hi = hi + add_hi + carry;

            lo = new_lo;
            hi = new_hi;
        }
    }

    *res_hi = hi;
    *res_lo = lo;
}
*/

void mul_compute(const uint64_t* data_array, size_t data_len, const uint64_t* kernel_array, size_t kernel_len, uint64_t* dest){
    const size_t total_computations = data_len + kernel_len - 1;

    for(size_t i = 0; i < total_computations; i++){ // convolution kernel slide
        uint64_t res_lo = 0, res_hi = 0;

        for(size_t j = 0; j < kernel_len; j++){ // traverse kernel
            long long data_idx = (long long)i - (long long)j;

            if(data_idx >= 0 && data_idx < data_len){
                uint64_t data = data_array[data_idx];
                uint64_t kernel = kernel_array[kernel_len - 1 - j];

                uint64_t mul_hi = 0, mul_lo = 0;
                //multiply_64to128(data, kernel, &mul_hi, &mul_lo);
                for(int k = 0; k < 64; k++){
                    if((kernel >> k) & 1){
                        // Add (a << i) to the result
                        uint64_t add_lo = data << k;
                        uint64_t add_hi = (k==0) ? 0 : (data >> (64 - k)); // upper bits that overflow

                        uint64_t new_lo = mul_lo + add_lo;
                        uint64_t carry = (new_lo < mul_lo) ? 1 : 0; // check overflow
                        uint64_t new_hi = mul_hi + add_hi + carry;

                        mul_lo = new_lo;
                        mul_hi = new_hi;
                    }
                }
                //add_64to128(res_hi, res_lo, mul_hi, mul_lo, &res_hi, &res_lo);
                uint64_t new_lo = res_lo + mul_lo;
                uint64_t carry = (new_lo < res_lo) ? 1 : 0; // check overflow
                uint64_t new_hi = res_hi + mul_hi + carry;

                res_lo = new_lo;
                res_hi = new_hi;
            }
        }
        dest[i<<1]       = res_hi;
        dest[(i<<1) + 1] = res_lo;
    }
}
