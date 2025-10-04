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
; --- Code ---
mode32_entry:
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

; ------------------------------
; Tests
; ------------------------------
; Buffers
; ------------------------------
; Messages

; ------------------------------
; Pad to full sectors (if times value is negative, update line 23 in the Makefile to the next power of two)
; In case this line ever gets moved:
; # Config
; MODE32_SECTORS = 4
times (MODE32_SECTORS*512)-($-$$) db 0
