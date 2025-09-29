; boot.asm - AmitGFX Stage 1 bootloader
; Author: Amity
; Date:   27-9-2025

BITS 16
ORG 0x7C00

start:
    cli

    ; --- Set segments ---
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; Put stack safely away from boot sector
    mov ax, 0x9000
    mov ss, ax
    mov sp, 0xFFFF

    ; Save boot drive
    mov [BOOT_DRIVE], dl

    ; Prepare DAP
    lea si, [dap]          ; DS=0, SI points to DAP
    mov ah, 0x42
    mov dl, [BOOT_DRIVE]

    ; Retry logic for transient disk errors
    mov bp, RETRIES

.read_retry:
    int 0x13
    jnc stage2_loaded

    mov al, '!'
    call print_char
    dec bp
    jnz .read_retry

hang:
    hlt
    jmp hang

stage2_loaded:
    mov al, '*'
    call print_char
    ; jump to physical 0x8000
    jmp 0x0000:0x8000


; --- Helpers ---
print_char:
    push ax
    mov ah, 0x0E
    int 0x10
    pop ax
    ret


; --- Data ---
BOOT_DRIVE: db 0
RETRIES     equ 5


; Disk Address Packet (DAP) - 16 bytes
dap:
    db 0x10                ; size of packet
    db 0x00                ; reserved
    dw STAGE2_SECTORS      ; number of sectors to read
    dw 0x8000              ; buffer offset (little-endian: offset then seg)
    dw 0x0000              ; buffer segment
    dq 0x00000001          ; starting LBA (sector 1)


LAST_DISK_ERR: db 0
; Boot signature
times 510-($-$$) db 0
dw 0xAA55
