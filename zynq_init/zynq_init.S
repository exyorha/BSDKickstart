.text
.globl _start
_start:
  mov  r5, #0x03
  mov  r6, #0
  ldr  r7, =0xF8000000    @ SLCR base address
  ldr  r8, =0xF8F00000    @ MPCORE base address
  ldr  r9, =0x0000767B    @ SLCR lock key
  mov  r10, #0x1F
  ldr  r11, =0x0000DF0D   @ SLCR unlock key
  dsb
  isb                     @ make sure it completes
  pli  do_remap           @ preload the instruction cache
  pli  do_remap + 32
  pli  do_remap + 64
  pli  do_remap + 96
  pli  do_remap + 128
  pli  do_remap + 160
  pli  do_remap + 192
  isb                     @ make sure it completes
  b    do_remap
.align 5, 0xFF            @ forces the next block to a cache line alignment
do_remap:                 @ Unlock SLCR
  str  r11, [r7, #0x8]    @ Configuring OCM remap value
  str  r10, [r7, #0x910]  @ Lock SLCR
  str  r9,  [r7, #0x4]    @ Disable SCU & address filtering
  str  r6,  [r8, #0x0]    @ Set filter start addr to 0x00000000
  str  r6,  [r8, #0x40]   @ Enable SCU & address filtering
  str  r5,  [r8, #0x0]
  dmb

  b enable_all_caches

.type _start, %function
.size _start, . - _start
