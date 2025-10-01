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
    xor  ebx, ebx
    mov  di,  mem_buffer
    mov  ax,  cs
    mov  es, ax
.e820_loop:
    mov  eax, 0xE820                   ; BIOS function: get system memory map
    mov  edx, 0x534D4150               ; "SMAP" signature
    mov  ecx, 24                       ; request 24-byte signature
    int  0x15                          ; Call BIOS
    jc   .e820_done
    cmp  eax, 0x534D4150               ; Verify BIOS returned "SMAP"
    jne  .e820_done                    ; Error

    mov  al,  '#'                      ; Success, entry found
    call print_char

    ; Don't do `add di, 24` here, it will break everything. Why? Because the BIOS feels like it I guess
    test ebx, ebx
    jnz  .e820_loop
    jmp  .after_memmap


.e820_done:
    mov  al,  '!'
    call print_char
   
.after_memmap:
    ; 2) Store results in structured table in memory (for kernel)
    call print_newline
    mov  si,  storing_msg
    call print_string

    mov  ax,  cs
    mov  ds,  ax
    mov  es,  ax
    cld

    mov  si,  mem_buffer
    mov  di,  mem_table + 2
    xor  cx,  cx
.store_loop:
    ; Copy Base (QWORD)
    mov  ax,  [si]
    stosw
    mov  ax,  [si+2]
    stosw
    mov  ax,  [si+4]
    stosw
    mov  ax,  [si+6]
    stosw

    ; Copy Length (QWORD)
    mov  ax,  [si+8]
    stosw
    mov  ax,  [si+10]
    stosw
    mov  ax,  [si+12]
    stosw
    mov  ax,  [si+14]
    stosw

    ; Copy Type (DWORD)
    mov  ax,  [si+16]
    stosw
    mov  ax,  [si+18]
    stosw

    add  si,  24 ; Why did the BIOS throw a hissy fit the last time we did this? I haven't got a f*cking clue. It works now so that's great!
    inc  cx

    cmp  ebx, 0
    jne  .store_loop

    mov  [mem_table], cx

    call print_newline
    mov  si,  done_msg
    call print_string

    mov  eax, mem_table
    mov  [boot_info_mem], eax

    ; Store entry count
    mov  ax,  [mem_table]
    mov  [boot_info_count], ax
    ; --- print simple message ---
    call print_newline
    mov si, msg
    call print_string

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

; ------------------------------
; Tests

; ------------------------------
; Buffers
align 16
mem_buffer:        times 512 db 0      ; One E820 entry (24 bytes)
mem_table:         times 512 db 0      ; Stuctured copy for kernel

boot_info_mem:     dd 0                ; Physical address of mem_table (so we can access it later)
boot_info_count:   dw 0                ; Number of table entries
boot_drive:        db 0                ; Boot drive, from stage 1

; ------------------------------
; Messages
msg:               db "hello from stage 2!",0
banner:            db "AmitGFX, by Amity",0
storing_msg:       db "Storing 0xE820 table...",0
done_msg:          db "Copying done!",0


; ------------------------------
; Pad to full sectors (if times value is negative, update line 22 in the Makefile to the next power of two)
; In case this line ever gets moved:
; # Config
; STAGE2_SECTORS = 4
times (STAGE2_SECTORS*512)-($-$$) db 0
