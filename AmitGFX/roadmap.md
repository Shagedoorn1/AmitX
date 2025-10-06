# AmitGFX Bootloader Roadmap

## Stage 1 (Bootsector, real mode)
1) Boot strap
    - Start in 16 bit real mode (BIOS env)
    - Disable interrupts temporarily
    - Set small stack in low memory
2) Disk & environment setup
    - Save BIOS boot drive number (from DL register)
3) Load stage 2
    - Read fixed number of sectors into a known memory adress,`ORG 0x8000`
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
    - Enable A20 line (for +1MB memory)
    - Load raw kernel.bin from disk into 1MB
    - Future: replace with FS loader (ext2)
4) Hand off to protected-mode
    - Load small GDT for transition
    - Set CR0.PE = 1 (duh)
    - Far jump into `mode32_entry` from `mode32.asm`

## if implemented ? [x] : []
- 1 [x]
- 2 [x]
- 3 [x]
- 4 [x]

# Mode32
1) Initialize protected mode
    - Load 32-bit GDT (flat-memory-model)
    - Far jump to 32-bit code segment
2) Setup runtime env
    - Load 32-bit data segment (DS, ES, SS, ..., \<X>S)
    - Set up 32-bit stack
    - Print switch success message
3) Prepare for long mode
    - Identity-map first few MBs 
    - Load CR3 with page table base address (PML4 → PDPT → PD → PT)
    - Set CR4.PAE = 1
    - Set EFER.LME = 1 (Long Mode Enable)
    - Far jump into `mode64_entry` from `mode64.asm`
## if implemented ? [x] : []
- 1 []
- 2 []
- 3 []
# Mode64
1) Enter long mode
    - Set CR0.PGE = 1 (enable paging)
    - Far jump to 64-bit code segment
2) Initialize 64-bit env
    - Load 64-bit GDT (long mode code/data segment)
    - Set up new stack and clear segment registers
    - Print switch success message
3) Pass control to kernel
    - Jump to kernel entry point at 1 MB (0x100000)
    - Pass memory map and boot info struct

# if implemented ? [x] : []
- 1 []
- 2 []
- 3 []