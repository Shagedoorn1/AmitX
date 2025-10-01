# AmitGFX Bootloader Roadmap

## Stage 1 (Bootsector, real mode)
1) Boot strap
    - Start in 16 bit real mode (BIOS env)
    - Disable interrupts temporarily
    - Set small stack in low memory
2) Disk & environment setup
    - Save BIOS boot drive number (from DL register)
    - Enable A20 line (for +1MB memory)
3) Load stage 2
    - Read fixed number of sectors into a known memory adress, e.g. `0x8000`
    - Handle errors gracefully (but with the spirit of Owly)
4) Jump to stage 2
    - Far jump to stage 2 entry point in 16-bit real mode

## if implemented ? [x] : []
- 1 [x]
- 2 [x]
- 3 [x]
- 4 [x]

# Stage 2 (extended loader, 16-bit real mode → 64-bit long mode)
1) Initialize basics
    - Set up larger stack, real-mode stack.
    - Store boot drive (again)
    - Print banner (cause why not?)
2) Query BIOS
    - Get memory map (E820).
    - Store results in structured table in memory (for kernel)
3) Load kernel
    - Load raw kernel.bin from disk into 1MB
    - Future: replace with FS loader (ext2)
4) Switch to protected mode (32-bit)
    - Load and enable GDT (with proper 32-bit segments).
    - Enable protected mode (CR0.PE=1).
    - Far jump into 32-bit code.
5) Switch to long mode (64-bit)
    - In 32-bit protected mode, set up a page table for identity mapping (1:1).
    - Enable PAE (CR4.PAE=1).
    - Load 64-bit GDT.
    - Enable long mode (EFER.LME=1).
    - Set CR0.PG=1 to enable paging.
    - Far jump into 64-bit code.
6) Pass boot info & jump to kernel
    - Clear VGA text screen and print status message
    - Prepare boot info structure:
        - Memory map (0xE820)
        - Boot drive
        - Kernel load address
    - Jump to kernel's 64-bit entry point at 1MB

## if implemented ? [x] : []
- 1 [x]
- 2 [x]
- 3 []
- 4 []
- 5 []
- 6 []