ENTRY(_start)

SECTIONS {
	.text : {
		*(.text)
	}

	.rodata : {
		*(.rodata)
	}

	.data : {
		*(.data)
	}

	.bss : {
		*(.bss)
	}

	PROVIDE_HIDDEN(_end = .);
}
