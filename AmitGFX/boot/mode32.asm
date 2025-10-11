; mode32.asm - Stage 2 bootloader for AmitGFX, protected mode
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
%define SEL_KCODE 0x08
%define SEL_KDATA 0x10
%define SEL_UCODE 0x18
%define SEL_UDATA 0x20
%define SEL_TSS   0x28

%define SECTOR_SIZE 512
%define MODE32_ADDR 0x8000 + (MODE32_SECTORS * SECTOR_SIZE)
%define ENABLE_PM 0
; ------------------------------
; --- Code ---
ORG      MODE32_ADDR
BITS     16

mode32_entry:
    ; Print success message
    mov  si,  welcome_msg
    call print_string
    call print_newline

    ; --- Step 1: Initialize protected mode ---
    ; 1) Load 32-bit GDT (flat-memory-model)
    lgdt [gdt_descriptor]
    call test_gdt
    mov  ax,  SEL_TSS
    call print_hex16
    call print_newline
    ; 2) Set CR0.PE = 1 (duh)
%if ENABLE_PM
    mov  eax, cr0
    or   eax, 1
    mov  cr0, eax                      ; Set ENABLE_PM to 0 to enable printing with BIOS calls, haven't figured out another option yet
    ; So far I have no idea if that works with the outcome we want, but it sounds legit, printing with BIOS calls with CR0.PE = 1 will result in a pretty scarry glitch
    ; 3) Far jump to 32-bit code segment
    jmp SEL_KCODE:protected_entry

[BITS    32]
%endif
protected_entry:
%if ENABLE_PM
    mov  ax,  SEL_KDATA
    mov  ds,  ax
    mov  es,  ax
    mov  fs,  ax
    mov  gs,  ax
    mov  ss,  ax
    mov  esp, 0x90000

    mov  ax,  SEL_TSS
    ltr  ax
%endif
    mov  si, welcome_msg
    call print_string
hang:
    hlt
    jmp  hang
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

pm_print_string:
    pushad
    ; VGA text buffer physical address 0xB8000
    mov     edi, 0xB8000
    ; Use 2 bytes per cell: char, attribute
.next_char:
    mov     al, byte [esi]
    test    al, al
    jz      .done
    inc     esi
    mov     ah, 0x07          ; light grey on black (or choose another attr)
    mov     [edi], ax
    add     edi, 2
    jmp     .next_char
.done:
    popad
    ret
; ------------------------------
; Tests
test_gdt:
    ; Print GDT limit
    mov  si,  test_gdt_1
    call print_string

    mov  ax,  [gdt_descriptor]        ; limit (word)
    call print_hex16
    call print_newline

    mov  si,  test_gdt_2
    call print_string

    mov  ax,  [gdt_descriptor + 4]    ; base high word
    call print_hex16
    mov  ax,  [gdt_descriptor + 2]    ; base low word
    call print_hex16
    call print_newline

    mov  si, test_gdt_3
    call print_string

    mov  bx, SEL_TSS
    add  bx, gdt_start - $$           ; make BX = offset from current origin to gdt_start + SEL_TSS
    mov  ax, [gdt_start + SEL_TSS + 6] ; word: bytes 6-7 (highest word of descriptor)
    call print_hex16
    mov  ax, [gdt_start + SEL_TSS + 4] ; word: bytes 4-5
    call print_hex16

    mov  ax, [gdt_start + SEL_TSS + 2] ; word: bytes 2-3 (low dword high word)
    call print_hex16
    mov  ax, [gdt_start + SEL_TSS + 0] ; word: bytes 0-1 (lowest word)
    call print_hex16

    call print_newline

    ret


; ------------------------------
; Buffers
align 2
scratch32:         times 4 db 0

; ------------------------------
; TSS
align 4
tss_struct:
    dw 0                               ; previous task link
    dd 0x90000                         ; esp0  (kernel stack)
    dw SEL_KDATA                       ; ss0   (kernel data selector)
    dw 0, 0, 0, 0                      ; esp1, ss1, esp2, ss2 (unused)
    dd 0                               ; cr3 (unused)
    dd 0                               ; eip (unused)
    dd 0                               ; eflags (unused)
    times 104 - ($ - tss_struct) db 0  ; fill rest with 0s
tss_end:

; ------------------------------
; GDT
align 4
gdt_start:
; 0: Null descriptor
gdt_null:
    dq 0
; 1: Kernel code (base =0, limit = 4GB, access = 0x9A, flags = 0xCF)
gdt_code:
    dw 0xFFFF                          ; limit low
    dw 0x0000                          ; base low
    db 0x00                            ; base middle
    db 0x9A                            ; access
    db 0xCF                            ; granularity (flags + limit high nibble)
    db 0x00                            ; base high

; 2: Kernel data (base = 0, limit = 4GB, access = 0x92, flags = 0xCF)
gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x92
    db 0xCF
    db 0x00

; 3: User code (base = 0, limit = 4GB, access = 0xFA, flags = 0xCF) DPL = 3 in access
gdt_ucode:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0xFA
    db 0xCF
    db 0x00

; 4: User data (base = 0, limit = 4GB, access = 0xF2, flags = 0xCF)
gdt_udata:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0xF2
    db 0xCF
    db 0x00

; 5: TSS descriptor
%assign TSS_BASE   (MODE32_ADDR + (tss_struct - $$))
%assign TSS_LIMIT  (tss_end - tss_struct - 1)
gdt_tss:
    dw TSS_LIMIT                       ; TSS limit (low)
    dw TSS_BASE & 0xFFFF               ; Base low
    db (TSS_BASE >> 16) & 0xFF         ; Base mid
    db 0x89                            ; Access
    db 0x00                            ; Flags/limit high
    db (TSS_BASE >> 24) & 0xFF         ; Base high
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1         ; Limit (size - 1)
    dd gdt_start                       ; Base address

; ------------------------------
; Messages
welcome_msg:       db "Hello from mode32",0
test_gdt_1:        db "GDT: limit=0x",0
test_gdt_2:        db "base=0x",0
test_gdt_3:        db "TSS desc (bytes, high->low) = 0x",0

; ------------------------------
; Pad to full sectors (if times value is negative, update line 23 in the Makefile to the next power of two)
; In case this line ever gets moved:
; # Config
; MODE32_SECTORS = 2
times (MODE32_SECTORS*512)-($-$$) db 0
