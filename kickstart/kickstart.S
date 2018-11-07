.arch armv7a
.syntax unified
.section .image_info, "a"
.globl image_info
image_info:
	.long 0 @ Metadata base
	.long 0 @ Kernel entry point
	.long 0 @ Compressed data base
	.long 0 @ Uncompressed data base
.type image_info,%object
.size image_info,. - image_info

.text

.globl _start
.func _start
_start:
	ldr sp, =stack + 2048
	ldr r4, =image_info
	@ r0 - src
	@ r1 - dst
	ldr r0, [r4, #8]
	ldr r1, [r4, #12]
	blx ulz4f
	ldr r0, [r4, #0]
	ldr pc, [r4, #4]
.endfunc
.type _start,%function
.size _start,. - _start

.bss
.lcomm stack, 2048
