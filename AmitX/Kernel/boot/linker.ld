ENTRY(_start)

SECTIONS {
    . = 0x100000;

    .text : {
        *(.multiboot)
        *(.text*)
    }

    .rodata : { *(.rodata*) }
    .data : { *(.data*) }
    .bss : ALIGN(4K) {
        *(.bss*)
        *(COMMON)
    }
}
