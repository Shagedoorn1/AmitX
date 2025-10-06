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
%define SECTOR_SIZE 512
%define MODE32_ADDR 0x8000 + (MODE32_SECTORS * SECTOR_SIZE)
; ------------------------------
; --- Code ---
ORG      MODE32_ADDR
BITS     16

mode32_entry:
    mov  si,  welcome_msg
    call print_string
    call print_newline

    lgdt [gdt_descriptor]
    call test_gdt

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
; ------------------------------
; Tests
test_gdt:
    ; Print GDT limit
    mov  si,  test_gdt_1
    call print_string
    mov  ax,  [gdt_descriptor]
    call print_hex16
    call print_newline

    ; Print GDT base (dword)
    mov  si,  test_gdt_2
    call print_string
    mov  ax,  word [gdt_descriptor+2]
    call print_hex32
    call print_newline

    ret

; ------------------------------
; Buffers
align 2
scratch32:         times 4 db 0


gdt_start:
gdt_null:          dq 0x0000000000000000    ; Null descriptor
gdt_code:          dq 0x00CF9A000000FFFF    ; Code segment: base=0, limit=4GB, flags=9A
gdt_data:          dq 0x00CF92000000FFFF    ; Data segment: base=0, limit=4GB, flags=92
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1         ; Limit (size - 1)
    dd gdt_start                       ; Base address
; ------------------------------
; Messages
welcome_msg:       db "Hello from mode32",0
test_gdt_1:        db "GDT: limit=0x",0
test_gdt_2:        db "base=0x",0

; ------------------------------
; Pad to full sectors (if times value is negative, update line 23 in the Makefile to the next power of two)
; In case this line ever gets moved:
; # Config
; MODE32_SECTORS = 1
times (MODE32_SECTORS*512)-($-$$) db 0
