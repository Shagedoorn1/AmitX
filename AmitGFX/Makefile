# Tools
ASM     = nasm
QEMU    = qemu-system-x86_64
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
STAGE2_SECTORS = 4
MODE32_SECTORS = 2
MODE64_SECTORS = 1
KERNEL_SECTORS = 1

# Source files
#Manually enter bootloader files, the order is important, using wildcard places stage2.asm last, which crashes the kernel at the first possible moment
#You know, fuck that, renaming files works too, especially great if for consistency
ASM_SRC = $(wildcard $(BOOT_DIR)/*.asm)
C_SRC   = $(wildcard $(SRC_DIR)/*.c)

# Bin/obj targets (automatically derived)
ASM_BIN = $(patsubst $(BOOT_DIR)/%.asm,$(BIN_DIR)/%.bin,$(ASM_SRC))
C_OBJ   = $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(C_SRC))
.SECONDARY: $(C_OBJ)
C_BIN   = $(patsubst $(SRC_DIR)/%.c,$(BIN_DIR)/%.bin,$(C_SRC))

# Disk image
IMG_FILE = $(IMG_DIR)/amitgfx.img

# Default
all: dirs $(IMG_FILE)

# Ensure directories exist
dirs:
	mkdir -p $(BIN_DIR) $(OBJ_DIR) $(IMG_DIR)

# Pattern rule for ASM -> BIN
$(BIN_DIR)/%.bin: $(BOOT_DIR)/%.asm | dirs
	$(ASM) $(ASM_FLAGS) -o $@ $< -DSTAGE2_SECTORS=$(STAGE2_SECTORS) -DKERNEL_SECTORS=$(KERNEL_SECTORS) -DMODE32_SECTORS=$(MODE32_SECTORS) -DMODE64_SECTORS=$(MODE64_SECTORS)

# Pattern rule for C -> OBJ
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c | dirs
	$(CC) $(CFLAGS) -c $< -o $@

# Pattern rule for OBJ -> BIN (kernel)
$(BIN_DIR)/%.bin: $(OBJ_DIR)/%.o | dirs
	$(LD) -m elf_x86_64 -Ttext 0x100000 --oformat binary -o $@ $<
	size=$$(stat -c%s "$@"); \
	size=$$(( (size + 511) / 512 * 512 )); \
	truncate -s $$size "$@"

# Build disk image
$(IMG_FILE): $(ASM_BIN) $(C_BIN)
	cat $(ASM_BIN) $(C_BIN) > $@


# Run in QEMU
run: $(IMG_FILE)
	$(QEMU) -drive format=raw,file=$(IMG_FILE),if=ide,index=0,media=disk -full-screen -vga std

# Clean
clean:
	rm -f $(BIN_DIR)/*.bin $(OBJ_DIR)/*.o $(IMG_DIR)/*.img
