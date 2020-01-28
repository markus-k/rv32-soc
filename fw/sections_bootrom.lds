/*
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.
*/

MEMORY {
	/* the memory in the testbench is 128k in size;
	 * set LENGTH=96k and leave at least 32k for stack */
	rom (rx) : ORIGIN = 0x00000000, LENGTH = 0xfff
	ram (wx) : ORIGIN = 0x20000000, LENGTH = 0xfff
}

SECTIONS {
	.text : {
		. = 0x000000;
		start*(.text)
		*(.text)

		. = ALIGN(4);

        *(.rodata*)
		end = .;

		. = ALIGN(4);
	} > rom

    .data : {
        *(.data);

        . = ALIGN(4);
    } > ram AT > rom

    .bss : {
         *(.bss*)
         *(COMMON)
         . = ALIGN(4);
    } > ram
}
