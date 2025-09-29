# Tools
ASM     = nasm
QEMU    = qemu-system-x86_64

# For later (C kernel)
CC      = x86_64-elf-gcc
LD      = x86_64-elf-ld

# Flags
ASM_FLAGS = -f bin
CFLAGS    = -m64 -ffreestanding -O2 -Wall -Wextra -Iinclude
LDFLAGS   = -T linker.ld -nostdlib

# Directories
BOOT_DIR = boot
SRC_DIR  = src
BIN_DIR  = isodir/bin
OBJ_DIR  = isodir/obj
IMG_DIR  = isodir/img

# Config
STAGE2_SECTORS = 1
KERNEL_SECTORS = 1

# Sources
BOOT_SRC   = $(BOOT_DIR)/boot.asm
STAGE2_SRC = $(BOOT_DIR)/stage2.asm
KERNEL_SRC = $(SRC_DIR)/kernel.c

BOOT_BIN   = $(BIN_DIR)/boot.bin
STAGE2_BIN = $(BIN_DIR)/stage2.bin
KERNEL_OBJ = $(OBJ_DIR)/kernel.o
KERNEL_BIN = $(BIN_DIR)/kernel.bin

IMG_FILE   = $(IMG_DIR)/os.img

# Default
all: dirs $(IMG_FILE)

# Ensure dirs exist
dirs:
	mkdir -p $(BIN_DIR) $(OBJ_DIR) $(IMG_DIR)

# Boot sector
$(BOOT_BIN): $(BOOT_SRC) | dirs
	$(ASM) $(ASM_FLAGS) -o $@ $< -DSTAGE2_SECTORS=$(STAGE2_SECTORS)

# Stage 2 (needs KERNEL_SECTORS for DAP setup)
$(STAGE2_BIN): $(STAGE2_SRC) $(KERNEL_BIN) | dirs
	$(ASM) $(ASM_FLAGS) -o $@ $< \
		-DSTAGE2_SECTORS=$(STAGE2_SECTORS) \
		-DKERNEL_SECTORS=$(KERNEL_SECTORS)

# Kernel
$(KERNEL_BIN): $(KERNEL_SRC) | dirs
	$(CC) $(CFLAGS) -c $< -o $(KERNEL_OBJ)
	$(LD) -m elf_x86_64 -Ttext 0x100000 --oformat binary -o $@ $(KERNEL_OBJ)
	# align to full sectors
	size=$$(stat -c%s "$@"); \
	size=$$(( (size + 511) / 512 * 512 )); \
	truncate -s $$size "$@"

# Build disk image (boot sector + stage2 + kernel)
$(IMG_FILE): $(BOOT_BIN) $(STAGE2_BIN) $(KERNEL_BIN)
	cat $(BOOT_BIN) $(STAGE2_BIN) $(KERNEL_BIN) > $@

# Run in QEMU
run: $(IMG_FILE)
	$(QEMU) -drive format=raw,file=$(IMG_FILE),if=ide,index=0,media=disk -full-screen -vga std

# Clean
clean:
	rm -f $(BIN_DIR)/*.bin $(OBJ_DIR)/*.o $(IMG_DIR)/*.img
