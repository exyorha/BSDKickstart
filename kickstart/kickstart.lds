ENTRY(_start)

SECTIONS {
	.image_info 0 : {
		*(.image_info)
	}

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
}
