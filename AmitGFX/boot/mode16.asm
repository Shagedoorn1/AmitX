; stage2.asm - Stage 2 bootloader for AmitGFX
; Author: Amity

; ------------------------------
; Alignment instructions:

; Instructions               begin at col 5
; First operand              begins at col 10
; Second operand             begins at col 15 (if possible)
; 
; Header comments            begin at col 5
; In-line comments           begin at col 40
; Labels                     begin at col 1, end with ':'
; Section dividers           use 30 '-' characters
; (Sub)Section titles        use 3 '-' characters before and after

; ------------------------------
; --- Macros ---
%define SECTOR_SIZE 512
%define MODE32_ADDR 0x8000 + (MODE32_SECTORS * SECTOR_SIZE)
; ------------------------------
; --- Code ---
BITS     16
ORG      0x8000

start:
    cli                                ; Disable interrupts before stack setup

    mov  [boot_drive], dl

    ; --- Step 1: Set up basics ---
    ; 1) Stack in high memory
    mov  ax,  0x9000                   ; Set stack segment to 0x9000
    mov  ss,  ax                       ; Load stack segment into SS
    mov  sp,  0x9FFF                   ; Set stack pointer to the top of 0x9000

    ; 2) Print banner
    mov  si,  banner
    call print_string
    call print_newline
    
    ; --- Step 2: Query BIOS ---
    ; 1) Get memory map (E820)
    mov  ax, cs
    mov  ds, ax          ; DS used for mem_table destination
    mov  es, ax          ; ES will be used for BIOS buffer (we'll set ES:DI before each call)
    cld

    xor  ebx, ebx        ; continuation value for E820
    xor  dx, dx          ; DX = entry count (word)
    mov  bp, mem_table + 2    ; BP = destination pointer (offset in DS) -> start after count

.e820_loop:
    mov  di,  mem_buffer
    mov  eax, 0xE820
    mov  edx, 0x534D4150
    mov  ecx, 24
    int  0x15
    jc   .e820_error
    cmp  eax, 0x534D4150
    jne  .e820_error

    mov  al, '#'
    call print_char

    
    mov  si,  mem_buffer       
    mov  cx,  4                
.copy_base:
    mov  ax,  [es:si]
    mov  [ds:bp], ax
    add  si,  2
    add  bp,  2
    loop .copy_base

    mov  cx,  4                
.copy_len:
    mov  ax,  [es:si]
    mov  [ds:bp], ax
    add  si,  2
    add  bp,  2
    loop .copy_len

    mov  cx,  2              
.copy_type:
    mov  ax,  [es:si]
    mov  [ds:bp], ax
    add  si,  2
    add  bp,  2
    loop .copy_type

    inc  dx

    test ebx, ebx
    jnz  .e820_loop          

    mov  ax,  dx
    mov  [mem_table], ax

    jmp .after_memmap

.e820_error:
    mov  al, '!'
    call print_char
    mov  ax, dx
    mov  [mem_table], ax

.after_memmap:
    mov  eax, mem_table
    mov  [boot_info_mem], eax
    mov  ax, [mem_table]
    mov  [boot_info_count], ax

    ; call test_boot_info
    ; this test will print a MASSIVE ammount of numbers, most of wich 0, there is some actual data in there but you'll need to be able to read yee-fast to make sense of it

    ; --- Step 3: Load kernel ---
    ; 1) Enable A20 line (for +1MB memory)
    in   al,  0x92
    or   al,  2
    out  0x92, al
    call print_newline
    call test_a20
    ; 2) Load raw kernel.bin from disk into 1MB (the return of LBA)
    mov  si,  mode32_load_msg
    call print_string
    call print_newline

    mov  dl,  [boot_drive]
    mov  ah,  0x42
    lea  si,  [mode32_dap]
    int  0x13
    jc   .mode32_read_fail

    mov  si,  load_done_msg
    call print_string
    call print_newline
    jmp  .after_mode32_load
.mode32_read_fail:
    mov  si,  disk_err_msg
    call print_string
    jmp hang
.after_mode32_load:
    ; --- print simple message ---
    call print_newline
    mov  si,  msg
    call print_string
    mov  ax, word MODE32_ADDR
    call print_hex32
    
    ; 3) Future, replace with FS loader (ext2)
    ; --- Step 4: Hand off to protected-mode (32-bit) ---
    ; 1) Far jump into `mode32_entry` from `mode32.asm`
    jmp 0x0000:MODE32_ADDR

hang:
    hlt
    jmp hang

; ------------------------------
; Helpers
print_char:
    push ax
    mov  ah,  0x0E
    int  0x10
    pop  ax
    ret

print_hex16:
    push ax
    push cx
    push dx
    mov  cx,  4
    mov  dx,  ax

.print_digit:
    mov  ax,  dx
    shr  ax,  12
    and  ax,  0xF
    cmp  ax,  10
    jl   .ph_num
    add  al,  'A'-10
    jmp  .ph_ready

.ph_num:
    add  al,  '0'

.ph_ready:
    mov  ah,  0x0E
    int  0x10
    shl  dx,  4
    loop .print_digit
    pop  dx
    pop  cx
    pop  ax
    ret

print_newline:
    mov  al,  0x0D
    call print_char
    mov  al,  0x0A
    call print_char
    ret

print_string:
    lodsb
    cmp  al,  0
    je   .ps_done
    call print_char
    jmp  print_string

.ps_done:
    ret

; usage: put 32-bit value in EAX, then call print_hex32
print_hex32:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si, scratch32      ; scratch area (4 bytes) in data section
    mov [si], eax          ; NASM will store EAX little-endian (low word @ si, high word @ si+2)

    ; print high word first
    mov ax, [si+2]
    call print_hex16

    ; then low word
    mov ax, [si]
    call print_hex16

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ------------------------------
; Tests
test_boot_info:
    call print_newline

    mov  si,  boot_drive_msg
    call print_string
    mov  al,  [boot_drive]
    call print_hex16
    call print_newline

    mov  cx,  [boot_info_count]
    mov  si,  mem_table + 2
.print_entries:
    mov  ax,  [si]
    call print_hex16
    mov  ax,  [si+16]
    call print_hex16
    call print_newline
    add  si,  20
    loop .print_entries
.done:
    ret

test_a20:
    cli                                ; disable interrupts

    ; Save original bytes (optional, can skip if safe)
    mov  ax,  0x0000
    mov  es,  ax
    mov  di,  0x0000
    mov  al,  [di]
    mov  [saved_low], al

    ; Write test pattern
    mov  al,  0xAA
    mov  [di], al                      ; write to 0x000000

    ; Write to 0x100000 (1 MB physical)
    mov  ax,  0xFFFF
    mov  es,  ax
    mov  di,  0x0010                   ; 0xFFFF0 + 0x10 = 0x100000
    mov  al,  0x55
    mov  [di], al

    ; Read back 0x100000
    mov  ax,  0xFFFF
    mov  es,  ax
    mov  di,  0x0010
    mov  al,  [di]
    cmp  al,  0x55
    je   .a20_on
    ; else
.a20_off:
    mov  si, msg_a20_off
    call print_string
    call print_newline
    jmp  .done

.a20_on:
    mov  si, msg_a20_on
    call print_string
    call print_newline

.done:
    ; Restore original 0x000000 byte (optional)
    mov  ax,  0x0000
    mov  es,  ax
    mov  di,  0x0000
    mov  al,  [saved_low]
    mov  [di], al
    ret
; ------------------------------
; Buffers
align 16
mem_buffer:        times 512 db 0      ; One E820 entry (24 bytes)
mem_table:         times 512 db 0      ; Stuctured copy for kernel

boot_info_mem:     dd 0                ; Physical address of mem_table (so we can access it later)
boot_info_count:   dw 0                ; Number of table entries
boot_drive:        db 0                ; Boot drive, from stage 1

saved_low:         db 0                ; for A20 test
align 2
scratch32:         times 4 db 0


mode32_dap:
    db 0x10                            ; size of packet
    db 0x00                            ; reserved
    dw MODE32_SECTORS                  ; number of sectors to read
    dw MODE32_ADDR                          ; buffer offset (little-endian: offset then seg)
    dw 0x0000                          ; buffer segment
    dq 1 + STAGE2_SECTORS              ; starting LBA (sector 1)

; ------------------------------
; Messages
msg:               db "hello from stage 2!",0
banner:            db "AmitGFX, by Amity",0
storing_msg:       db "Storing 0xE820 table...",0
done_msg:          db "Copying done!",0
boot_drive_msg:    db "Boot drive=0x",0
msg_a20_on:        db "A20 ON",0
msg_a20_off:       db "A20 OFF",0
mode32_load_msg:   db "Loading mode32...",0
load_done_msg:     db "mode32 read OK",0
disk_err_msg:      db "mode32 read failed",0
msg_pm_jump:       db "Jumping to mode32...",0




; ------------------------------
; Pad to full sectors (if times value is negative, update line 22 in the Makefile to the next power of two)
; In case this line ever gets moved:
; # Config
; STAGE2_SECTORS = 4
times (STAGE2_SECTORS*512)-($-$$) db 0
