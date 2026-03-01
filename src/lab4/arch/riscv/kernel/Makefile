# Risc-V toolchain prefix
CROSS_ := riscv64-linux-gnu-

# Compiler and tools
GCC := $(CROSS_)gcc

ISA := rv64ia_zicsr_zifencei
ABI := lp64

# Compiler and linker flags
ARCH_FLAGS := -march=$(ISA) -mabi=$(ABI) -mcmodel=medany
CPPFLAGS := -I../include -I../../../include
CFLAGS := -ffreestanding -fno-builtin -ffunction-sections -fdata-sections \
	-nostartfiles -nostdlib -nostdinc -static -ggdb -Og \
	-Wall -Wextra -std=gnu11 $(ARCH_FLAGS)
LDFLAGS := -lgcc -Wl,--nmagic -Wl,--gc-sections

# Source files in the current directory
SRCS_S = head.S
SRCS_C = main.c print.c sbi.c

# Generate .o file names from source file names
OBJS_S = $(SRCS_S:.S=.o)
OBJS_C = $(SRCS_C:.c=.o)
OBJS   = $(OBJS_S) $(OBJS_C)

# Default target: build all .o files
.PHONY: all
all: $(OBJS)

# Rule to compile .c files into .o files
# CFLAGS and CPPFLAGS are inherited from the parent Makefile
%.o: %.c
	$(GCC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# Rule to compile .S files into .o files
# CFLAGS and CPPFLAGS are inherited from the parent Makefile
%.o: %.S
	$(GCC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# Phony target for cleaning up
.PHONY: clean
clean:
	rm -f $(OBJS)

