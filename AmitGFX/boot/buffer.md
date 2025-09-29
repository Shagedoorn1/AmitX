```nasm
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
    mov [boot_drive], dl

    ; --- Step 1: Set up as simple stack ---
    mov  ax,  0x9000                   ; Set stack segment to 0x9000
    mov  ss,  ax                       ; Load stack segment into SS
    mov  sp,  0x9FFF                   ; Set stack pointer to the top of 0x9000
    
    ; --- Step 2: Query BIOS ---
    ; 1) Get memory map (E820)
    xor  ebx, ebx                      ; Clear EBX
    mov  di,  mem_buffer               ; ES:DI -> buffer for mem map
    mov  ax,  cs                       ; Point ES to current code segment for buffer
    mov  es,  ax

.e820_loop:
    mov  eax, 0xE820                   ; BIOS function: get system memory map
    mov  edx, 0x534D4150               ; "SMAP" signature
    mov  ecx, 24                       ; request 24-byte signature
    int  0x15                          ; Call BIOS
    jc   .e820_done                    ; Jump if carry (error)
    cmp  eax, 0x534D4150               ; Verify BIOS returned "SMAP"
    jne  .e820_done                    ; Error

    mov  al,  '#'
    call print_char

    add  di,  24
    test ebx, ebx
    jnz .e820_loop
    jmp .after_memmap

.e820_done:
    mov  al,  '!'
    call print_char 
.after_memmap:

    ; 2) Get VBE info block ---
    mov  ax,  cs
    mov  es,  ax
    mov  di,  vbe_buffer

    mov  ax,  0x4F00
    int  0x10
    cmp  ax,  0x004F
    jne  .vbe_fail

    mov  al,  'V'
    call print_char
    jmp  .after_vbe

.vbe_fail:
    mov  al,  'v'
    call print_char

.after_vbe:
    ; --- Step 3: Enter graphics mode
    ; 1) Available modes from mode list
    mov  si,  [vbe_buffer+0x0E]        ; offset of mode list
    mov  es,  word [vbe_buffer+0x10]   ; segment of mode list
    mov  di,  si

    mov  word [selected_mode], 0x0118
    
    jmp  .mode_selected

.mode_selected:
    mov  ax,  [selected_mode]
    call print_hex16
    call print_newline
    ; 2) Switch using int 0x10, AX=4F02h.
    mov  ax,  0x4F02
    mov  bx,  [selected_mode]
    or   bx,  0x4000
    int  0x10
    jc   .mode_fail
         
    mov  al,  'G'
    call print_char
    call print_newline
    jmp  .after_mode

.mode_fail:
    mov  al,  'g'
    call print_char
    call print_newline

.after_mode:
    ; --- ModeInfo: ask about the mode we set ---
    mov  ax,  cs
    mov  es,  ax
    mov  di,  vbe_buffer
    mov  cx,  [selected_mode]
    mov  ax,  0x4F01
    int  0x10
    cmp  ax,  0x004F
    jne  .mode_info_fail

    ; print ModeAttributes
    mov  si,  modeattr_label
    call print_string
    mov  ax,  word [vbe_buffer + 0x00]
    call print_hex16
    call print_newline

    ; print XRES
    mov  si,  xres_label
    call print_string
    mov  ax,  word [vbe_buffer + 0x12]
    call print_hex16
    call print_newline

    ; print YRES
    mov  si,  yres_label
    call print_string
    mov  ax,  word [vbe_buffer + 0x14]
    call print_hex16
    call print_newline

    ; print LFB flag (bit 7 of ModeAttributes)
    mov  si, lfb_label
    call print_string
    mov  ax,  word [vbe_buffer + 0x00]
    test ax,  1<<7
    jz   .no_lfb
    mov  al,  '1'
    call print_char
    call print_newline
    jmp  .lfb_yes

.no_lfb:
    mov  al,  '0'
    call print_char
    call print_newline
    mov  al,  'b'                      ; indicate banked mode
    call print_char
    call print_newline
    jmp  .after_modeinfo

.lfb_yes:
    ; print FB_ADDR (dword)
    mov  si,  fb_label
    call print_string
    mov  ax,  [vbe_buffer + 0x2A]      ; High byte (LE)
    call print_hex16
    mov  ax,  [vbe_buffer + 0x28]      ; Low Byte (LE)
    call print_hex16
    call print_newline

    ; print pitch
    mov  si,  pitch_label
    call print_string
    mov  ax,  [vbe_buffer + 0x10]
    call print_hex16
    call print_newline

    ; print bpp
    mov  si,  bpp_label
    call print_string
    xor  ah,  ah
    mov  al,  [vbe_buffer + 0x19]
    call print_hex16
    call print_newline

    jmp  .after_modeinfo

.mode_info_fail:
    mov  si,  fail_label
    call print_string
    call print_newline

.after_modeinfo:
    ; 3) Store mode info
    mov  ax,  [vbe_buffer + 0x12]      ; XRES
    mov  [vbe_xres], ax
    mov  ax,  [vbe_buffer + 0x14]      ; YRES
    mov  [vbe_yres], ax
    mov  ax,  [vbe_buffer + 0x10]      ; PITCH (bytes per scanline)
    mov  [vbe_pitch], ax
    xor  ah,  ah
    mov  al,  [vbe_buffer + 0x19]      ; BPP (byte)
    mov  [vbe_bpp], ax

    ; FB physical (dword)
    mov  ax, [vbe_buffer + 0x28]       ; low word (LE)
    mov  [fb_phys_low], ax
    mov  ax, [vbe_buffer + 0x2A]       ; high word (LE)
    mov  [fb_phys_high], ax

    
    ; --- Step 4: Load kernel ---
    ; 1) Load kernel sectors from disk into 1 MB (0x0010_0000)
    mov  si,  kernel_dap
    mov  ah,  0x42
    mov  dl,  [boot_drive]
    int  0x13
    jc   .kernel_load_failed

    mov  si, kernel_ok 
    call print_string
    call print_newline
    jmp  .after_kernel

.kernel_load_failed:
    mov  si,  disk_err_msg
    call print_string
    hlt
    jmp $

.after_kernel:
    ; --- Step 5: Switch to 32-bit protected mode ---
    ; 1) Enable A20
    in al, 0x92
    or al, 2
    out 0x92, al
    call test_a20
    ; 2) Load GDT
    call load_gdt
    call test_gdt
    ; 3) Set CR0.PE = 1
    ; 4) Far jump into kernel at 1 MB
    ; --- Print simple message ---
    mov  si,  msg

.print_loop:
    lodsb
    cmp  al,  0
    je   .done
    call print_char
    jmp  .print_loop

.done:
    hlt
    jmp  .done

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

load_gdt:
    cli
    lgdt [gdt_descriptor]              ; Load GDT into GDTR

    mov  al,  'L'
    call print_char
    call print_newline
    ret

; ------------------------------
; Tests
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

test_gdt:
    ; Print GDT limit
    mov  si,  test_gdt_label
    call print_string
    mov  ax,  [gdt_descriptor]
    call print_hex16
    call print_newline

    ; Print GDT base (dword)
    mov ax, word [gdt_descriptor+2]
    call print_hex16
    mov ax, word [gdt_descriptor+4]
    call print_hex16
    call print_newline

    ret

; ------------------------------
; Buffers
align 16
mem_buffer:        times 1284 db 0     ; One E820 entry (24 bytes)
align 16
vbe_buffer:        times 512 db 0      ; 1 sector, large enough for VBE info block + mode info
align 2
selected_mode:     dw 0

align 16
kernel_dap:
    db 16
    db 0
    dw KERNEL_SECTORS
    dw 0x0000
    dw 0x1000
    dq (1 + STAGE2_SECTORS)

fb_phys_low:       dw 0
fb_phys_high:      dw 0

vbe_xres:          dw 0
vbe_yres:          dw 0
vbe_pitch:         dw 0
vbe_bpp:           dw 0

boot_drive:        db 0

kernel_lba:        dq (1 + STAGE2_SECTORS)
kernel_sectors     dw KERNEL_SECTORS

saved_low:         db 0

align 8
gdt_start:
    ; 0x00 Null descriptor
    dd 0x00000000
    dd 0x00000000

    ; 0x08 Kernel code
    dw 0xFFFF
    dw 0x0000
    db 0x00 
    db 0x9A
    db 0xCF
    db 0x00 

    ; 0x10 Kernel Data
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x92
    db 0xCF
    db 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start



; ------------------------------
; Messages
msg:               db "hello from stage 2!",0
modeattr_label:    db "MODEATTR=0x",0
xres_label:        db "XRES=0x",0
yres_label:        db "YRES=0x",0
lfb_label:         db "LFB=",0
fb_label:          db "FB_ADDR=0x",0
pitch_label:       db "PITCH=0x",0
bpp_label:         db "BPP=0x",0
fail_label:        db "MODEINFO FAIL",0
disk_err_msg:      db "Kernel read failed",0
kernel_ok:         db "Kernel loaded",0
msg_a20_on:        db "A20 ON",0
msg_a20_off:       db "A20 OFF",0
test_gdt_label: db "GDT: limit=0x, base=0x",0

; ------------------------------
; Pad to full sectors (if times value is negative, update line 22 in the Makefile to the next power of two)
; In case this line ever gets moved:
; # Config
; STAGE2_SECTORS = 4
times (STAGE2_SECTORS*512)-($-$$) db 0
```