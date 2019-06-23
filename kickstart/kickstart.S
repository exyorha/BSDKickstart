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
	MRC     p15, 0, r0, c0, c0, 5   @ Read CPU ID register
	ands    r0, r0, #0x03           @ Mask off, leaving the CPU ID field
	bne    	ap_start

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

.globl ap_start
ap_start:
	MRC     p15, 4, r0, c15, c0, 0  @ Read periph base address      (see DE593076)
	ADD     r0, r0, #0x1000         @ Add GIC offset to base address

	# Enable the GIC
	LDR     r1, [r0]                @ Read the GIC's Enable Register  (ICDDCR)
	ORR     r1, r1, #0x01           @ Set bit 0, the enable bit
	STR     r1, [r0]                @ Write the GIC's Enable Register  (ICDDCR)

	# Enable interrupt source 0->15
	MOV     r1, #0xFF00             @ Load mask
	ORR     r1, #0xFF
	STR     r1, [r0, #0x100]        @ Write enable set register

	# Set priority of interrupt source 0->16 to 0x0 (highest priority)
	MOV     r1, #0x00
	STR     r1, [r0, #0x400]        @ Sources 00-03
	STR     r1, [r0, #0x404]        @ Sources 04-07
	STR     r1, [r0, #0x408]        @ Sources 08-11
	STR     r1, [r0, #0x40C]        @ Sources 12-15

	# Enable the Processor Interface
	MRC     p15, 4, r0, c15, c0, 0  @ Re-Read periph base address
	LDR     r1, [r0, #0x100]        @ Read the Processor Interface Control register
	ORR     r1, r1, #0x03           @ Bit 0: Enables secure interrupts, Bit 1: Enables Non-Secure interrupts
	STR     r1, [r0, #0x100]        @ Write the Processor Interface Control register

	# Set the Processor's Priority Mask
	MOV     r1, #0x1F
	STR     r1, [r0, #0x0104]       @ Write the Priority Mask register

	ldr			r0, =0xfffffff0
1:
	ldr			r1, [r0]
	cmp			r1, #0
	bxne		r1
	wfe
	b				1b
	
.type ap_start,%function
.size ap_start, . - ap_start

.bss
.lcomm stack, 2048
