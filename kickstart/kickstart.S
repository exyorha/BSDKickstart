.arch armv7a
.syntax unified
.section .image_info, "a"
.globl image_info
image_info:
	.long 0 @ Metadata base
	.long 0 @ Kernel entry point
	.long 0 @ Compressed data base
	.long 0 @ Uncompressed data base
	.long 0 @ Initialization chain
.type image_info,%object
.size image_info,. - image_info

.text

.globl _start
_start:
	ldr r0, =stack + 2048
	msr		cpsr_c, #0xD1 @ FIQ mode
	mov		sp, r0
	sub		r0, r0, #4
	msr		cpsr_c, #0xD2 @ IRQ mode
	mov		sp, r0
	sub		r0, r0, #4
	sub		r0, r0, #4
	msr		cpsr_c, #0xD7 @ Abort mode
	mov		sp, r0
	sub		r0, r0, #4
	msr		cpsr_c, #0xDB @ Undefined mode
	mov		sp, r0
	sub		r0, r0, #4
	msr		cpsr_c, #0xD3 @ SVC mode
	mov		sp, r0

  @ Enable ICache
	mrc     p15, 0, R1, c1, c0, 0
	orr     R1, R1, #0x00001000
	mcr     p15, 0, R1, c1, c0, 0

	ldr r4, =image_info

	ldr	r5, [r4, #16]
	cmp	r5, #0
	beq	1f

2:
	ldr		r6, [r5], #4
	cmp		r6, #0
	beq		1f

	push	{r4, r5}
	blx		r6
	pop		{r4, r5}

1:

	@ r0 - src
	@ r1 - dst
	ldr r0, [r4, #8]
	ldr r1, [r4, #12]
	cmp r0, r1
	blxne ulz4f
	ldr r0, [r4, #0]
	ldr pc, [r4, #4]
.type _start,%function
.size _start,. - _start

.bss
.lcomm stack, 2048
