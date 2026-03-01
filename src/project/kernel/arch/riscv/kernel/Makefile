# Source files in the current directory
SRCS_S = $(wildcard *.S)
SRCS_C = $(wildcard *.c)

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

