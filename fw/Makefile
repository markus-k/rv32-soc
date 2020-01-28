TOOLCHAIN_PREFIX = /opt/riscv32i/bin/riscv32-unknown-elf-

GCC := $(TOOLCHAIN_PREFIX)gcc
LD := $(TOOLCHAIN_PREFIX)ld
OBJCOPY := $(TOOLCHAIN_PREFIX)objcopy
OBJDUMP := $(TOOLCHAIN_PREFIX)objdump

ARCHFLAGS = -march=rv32i
CFLAGS = $(ARCHFLAGS) -ffreestanding -nostdlib -Os --std=c99
ASMFLAGS = $(ARCHFLAGS)
LDFLAGS = -ffreestanding -nostdlib -Os -Wl,-Bstatic,-T,sections_bootrom.lds,-Map,firmware.map,--strip-debug -lgcc

OBJS = start.o blinky.o

all: fw.bin fw.hex

fw.hex: fw.bin
#	python3 makehex.py $< 4096 > $@
	cat $< |xxd -b -c 4 -g 4 | cut -d ' ' -f  2 > $@

fw.bin: fw.elf
	$(OBJCOPY) -O binary $< $@

fw.elf: $(OBJS) sections_bootrom.lds
	$(GCC) -o $@ $(LDFLAGS) $(OBJS)

start.o: start.S
	$(GCC) -c $(ASMFLAGS) -o $@ $<

test.o: test.S
	$(GCC) -c $(ASMFLAGS) -o $@ $<

%.o: %.c
	$(GCC) -c $(CFLAGS) -o $@ $<

dump: fw.elf
	$(OBJDUMP) -d $<

.PHONY: clean
clean:
	rm -f fw.bin fw.hex fw.elf *.o
