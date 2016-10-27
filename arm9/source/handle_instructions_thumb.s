.section .itcm

#define USE_SELF_MODIFYING

reg_table = 0x10000000

.macro finish_handler
	orr sp, #1
	mcr p15, 0, sp, c1, c0, 0

	ldr sp,= reg_table
	ldmia sp, {r0-r7}	//non-banked registers

	subs pc, lr, #8
.endm

.macro finish_handler_skip_op
	orr sp, #1
	mcr p15, 0, sp, c1, c0, 0

	ldr sp,= reg_table
	ldmia sp, {r0-r7}	//non-banked registers

	subs pc, lr, #6
.endm

.macro finish_handler_self_modifying
	orr sp, #1
	mcr p15, 0, sp, c1, c0, 0

	subs pc, lr, #8
.endm

.macro finish_handler_skip_op_self_modifying
	orr sp, #1
	mcr p15, 0, sp, c1, c0, 0

	subs pc, lr, #6
.endm

//we may not use r5 and r6 here
.global thumb7_8_address_calc
thumb7_8_address_calc:
#ifdef USE_SELF_MODIFYING
	and r12, r10, #(7 << 3)
	and r13, r10, #(7 << 6)
	orr r8, r12, r13, lsl #13
	ldr r9,= 0xE0809000
	orr r8, r9, r8, lsr #3
	str r8, thumb7_8_address_calc_op1
	b thumb7_8_address_calc_op1
thumb7_8_address_calc_op1:
	.word 0
#else
	and r8, r10, #(7 << 3)
	ldr lr, [r11, r8, lsr #1]
	and r12, r10, #(7 << 6)
	ldr r13, [r11, r12, lsr #4]
	add r9, lr, r13
#endif
	ldr pc, [pc, r9, lsr #22]

	nop
	.word address_calc_ignore_thumb	//bios: ignore
	.word address_calc_ignore_thumb	//itcm: ignore
	.word address_calc_ignore_thumb	//main: ignore
	.word address_calc_ignore_thumb	//wram: can't happen
	.word thumb7_8_address_calc_cont	//io, manual execution
	.word address_calc_ignore_thumb	//pal: can't happen
	.word thumb7_8_address_calc_cont	//sprites vram, manual execution
	.word address_calc_ignore_thumb	//oam: can't happen
	.word thumb7_8_address_calc_fix_cartridge	//card: fix
	.word thumb7_8_address_calc_fix_cartridge	//card: fix	
	.word thumb7_8_address_calc_fix_cartridge	//card: fix
	.word thumb7_8_address_calc_fix_cartridge	//card: fix
	.word thumb7_8_address_calc_fix_cartridge	//card: fix
	.word thumb7_8_address_calc_cont	//eeprom, manual execution
	.word thumb7_8_address_calc_fix_sram	//sram: fix
	.word address_calc_ignore_thumb	//nothing: shouldn't happen

thumb7_8_address_calc_fix_cartridge:
#ifdef USE_SELF_MODIFYING
	ldr lr,= 0x083B0000
	cmp r9, lr
#else
	ldr r7,= 0x083B0000
	cmp r9, r7
#endif
	bge thumb7_8_address_calc_cont
#ifdef USE_SELF_MODIFYING
	mov r12, r12, lsr #3
	strb r12, thumb7_8_address_calc_fix_cartridge_op1
	mov r13, r13, lsr #6
	strb r13, thumb7_8_address_calc_fix_cartridge_op2
	mov r12, r12, lsl #4
	strb r12, (thumb7_8_address_calc_fix_cartridge_op3 + 1)
	b thumb7_8_address_calc_fix_cartridge_op1
thumb7_8_address_calc_fix_cartridge_op1:
	mov lr, r0
	//.word 0xE1A0E000
#endif
	
	cmp lr, #0x08000000
#ifdef USE_SELF_MODIFYING
thumb7_8_address_calc_fix_cartridge_op2:
	movlt lr, r0
	//.word 0xB1A0E000
#else
	movlt r8, r12, lsr #3		//not for self-modifying
	movlt lr, r13
#endif
	bic lr, lr, #0x06000000
	sub lr, lr, #0x05000000
	sub lr, lr, #0x00FC0000
#ifdef USE_SELF_MODIFYING
thumb7_8_address_calc_fix_cartridge_op3:
	mov r0, lr
	//.word 0xE1A0000E
#else
	str lr, [r11, r8, lsr #1]	//not for self-modifying
#endif
	msr cpsr_c, #0x97
#ifdef USE_SELF_MODIFYING
	finish_handler_self_modifying
#else
	finish_handler
#endif

thumb7_8_address_calc_fix_sram:
#ifdef USE_SELF_MODIFYING
	mov r12, r12, lsr #3
	strb r12, thumb7_8_address_calc_fix_sram_op1
	mov r13, r13, lsr #6
	strb r13, thumb7_8_address_calc_fix_sram_op2
	mov r12, r12, lsl #4
	strb r12, (thumb7_8_address_calc_fix_sram_op3 + 1)
	b thumb7_8_address_calc_fix_sram_op1
thumb7_8_address_calc_fix_sram_op1:
	mov lr, r0
	//.word 0xE1A0E000
#endif

	cmp lr, #0x0E000000
#ifdef USE_SELF_MODIFYING
thumb7_8_address_calc_fix_sram_op2:
	movlt lr, r0
	//.word 0xB1A0E000
#else
	movlt r8, r12, lsr #3		//not for self-modifying
	movlt lr, r13
#endif
	sub lr, lr, #0x0B800000
	sub lr, lr, #0x00008C00
	sub lr, lr, #0x00000060
#ifdef USE_SELF_MODIFYING
thumb7_8_address_calc_fix_sram_op3:
	mov r0, lr
	//.word 0xE1A0000E
#else
	str lr, [r11, r8, lsr #1]
#endif
	msr cpsr_c, #0x97
#ifdef USE_SELF_MODIFYING
	finish_handler_self_modifying
#else
	finish_handler
#endif

thumb7_8_address_calc_cont:
	tst r10, #(1 << 9)
	bne thumb8_address_calc
thumb7_address_calc:
	tst r10, #(1 << 11)
	beq thumb7_address_calc_write
	and r8, r10, #7
#ifdef USE_SELF_MODIFYING
	mov r8, r8, lsl #4
	strb r8, (thumb7_address_calc_op1 + 1)
#endif
	tst r10, #(1 << 10)
#ifndef USE_SELF_MODIFYING
	add r8, r11, r8, lsl #2
#endif
	mov r11, #4
	movne r11, #1
	bl read_address_from_handler
#ifdef USE_SELF_MODIFYING
thumb7_address_calc_op1:
	mov r0, r10
	//.word 0xE1A0000A
#else
	str r10, [r8]
#endif
	msr cpsr_c, #0x97
	//add lr, #2
	//finish_handler
#ifdef USE_SELF_MODIFYING
	finish_handler_skip_op_self_modifying
#else
	finish_handler_skip_op
#endif

thumb7_address_calc_write:
	tst r10, #(1 << 10)
	and r10, r10, #7
#ifdef USE_SELF_MODIFYING
	strb r10, thumb7_address_calc_write_op1
	b thumb7_address_calc_write_op1
thumb7_address_calc_write_op1:
	mov r11, r0
	//.word 0xE1A0B000
#else
	ldr r11, [r11, r10, lsl #2]
#endif
	mov r12, #4
	movne r12, #1
	andne r11, r11, #0xFF
	bl write_address_from_handler
	msr cpsr_c, #0x97
	//add lr, #2
	//finish_handler
#ifdef USE_SELF_MODIFYING
	finish_handler_skip_op_self_modifying
#else
	finish_handler_skip_op
#endif

thumb8_address_calc:
	ands r8, r10, #(3 << 10)
	beq thumb8_address_calc_write
thumb8_address_calc_read:
	and r13, r10, #7
#ifdef USE_SELF_MODIFYING
	mov r13, r13, lsl #4
	strb r13, (thumb8_address_calc_read_cont_op1 + 1)
#else
	add r11, r11, r13, lsl #2
#endif
	cmp r8, #(1 << 10)
#ifndef USE_SELF_MODIFYING
	orr r8, r11, r8, lsl #20
#endif
	mov r11, #2
	moveq r11, #1
	bl read_address_from_handler
#ifdef USE_SELF_MODIFYING
	cmp r8, #(2 << 10)
#else
	and r9, r8, #(3 << 30)
	cmp r9, #(2 << 30)
#endif
	beq thumb8_address_calc_read_cont
#ifdef USE_SELF_MODIFYING
	cmp r8, #(1 << 10)
#else
	cmp r9, #(1 << 30)
#endif
	mov r10, r10, lsl #16
	moveq r10, r10, lsl #8
	mov r10, r10, asr #16
	moveq r10, r10, asr #8
thumb8_address_calc_read_cont:
#ifdef USE_SELF_MODIFYING
thumb8_address_calc_read_cont_op1:
	mov r0, r10
	//.word 0xE1A0000A
#else
	bic r8, r8, #(3 << 30)
	str r10, [r8]
#endif
	msr cpsr_c, #0x97
	//add lr, #2
	//finish_handler
#ifdef USE_SELF_MODIFYING
	finish_handler_skip_op_self_modifying
#else
	finish_handler_skip_op
#endif

thumb8_address_calc_write:
	mov r12, #2
	and r10, r10, #7
#ifdef USE_SELF_MODIFYING
	strb r10, thumb8_address_calc_write_op1
	b thumb8_address_calc_write_op1
thumb8_address_calc_write_op1:
	mov r11, r0, lsl #16
	//.word 0xE1A0B800
	mov r11, r11, lsr #16
#else
	mov r10, r10, lsl #2
	ldrh r11, [r11, r10]
#endif
	bl write_address_from_handler
	msr cpsr_c, #0x97
	//add lr, #2
	//finish_handler
#ifdef USE_SELF_MODIFYING
	finish_handler_skip_op_self_modifying
#else
	finish_handler_skip_op
#endif

.global thumb9_address_calc
thumb9_address_calc:
	and r8, r10, #(7 << 3)
#ifdef USE_SELF_MODIFYING
	mov r8, r8, lsr #3
	strb r8, thumb9_address_calc_op1
	b thumb9_address_calc_op1
thumb9_address_calc_op1:
	mov lr, r0
#else
	ldr lr, [r11, r8, lsr #1]
#endif
	and r12, r10, #(31 << 6)
	tst r10, #(1 << 12)
	addeq r9, lr, r12, lsr #4
	addne r9, lr, r12, lsr #6
	ldr pc, [pc, r9, lsr #22]

	nop
	.word address_calc_ignore_thumb	//bios: ignore
	.word address_calc_ignore_thumb	//itcm: ignore
	.word address_calc_ignore_thumb	//main: ignore
	.word address_calc_ignore_thumb	//wram: can't happen
	.word thumb9_address_calc_cont	//io, manual execution
	.word address_calc_ignore_thumb	//pal: can't happen
	.word thumb9_address_calc_cont	//sprites vram, manual execution
	.word address_calc_ignore_thumb	//oam: can't happen
	.word thumb9_address_calc_fix_cartridge	//card: fix
	.word thumb9_address_calc_fix_cartridge	//card: fix	
	.word thumb9_address_calc_fix_cartridge	//card: fix
	.word thumb9_address_calc_fix_cartridge	//card: fix
	.word thumb9_address_calc_fix_cartridge	//card: fix
	.word thumb9_address_calc_cont	//eeprom, manual execution
	.word thumb9_address_calc_fix_sram	//sram: fix
	.word address_calc_ignore_thumb	//nothing: shouldn't happen

thumb9_address_calc_fix_cartridge:
	ldr r13,= 0x083B0000
	cmp r9, r13
	bge thumb9_address_calc_cont
	bic lr, lr, #0x06000000
	sub lr, lr, #0x05000000
	sub lr, lr, #0x00FC0000
#ifdef USE_SELF_MODIFYING
	mov r8, r8, lsl #4
	strb r8, (thumb9_address_calc_fix_cartridge_op1 + 1)
	b thumb9_address_calc_fix_cartridge_op1
thumb9_address_calc_fix_cartridge_op1:
	mov r0, lr
#else
	str lr, [r11, r8, lsr #1]
#endif
	msr cpsr_c, #0x97
#ifdef USE_SELF_MODIFYING
	finish_handler_self_modifying
#else
	finish_handler
#endif

thumb9_address_calc_fix_sram:
	sub lr, lr, #0x0B800000
	sub lr, lr, #0x00008C00
	sub lr, lr, #0x00000060
#ifdef USE_SELF_MODIFYING
	mov r8, r8, lsl #4
	strb r8, (thumb9_address_calc_fix_sram_op1 + 1)
	b thumb9_address_calc_fix_sram_op1
thumb9_address_calc_fix_sram_op1:
	mov r0, lr
#else
	str lr, [r11, r8, lsr #1]
#endif
	msr cpsr_c, #0x97
#ifdef USE_SELF_MODIFYING
	finish_handler_self_modifying
#else
	finish_handler
#endif

thumb9_address_calc_cont:
	tst r10, #(1 << 11)
	beq thumb9_address_calc_write
	and r8, r10, #7
#ifdef USE_SELF_MODIFYING
	mov r8, r8, lsl #4
	strb r8, (thumb9_address_calc_cont_op1 + 1)
#else
	add r8, r11, r8, lsl #2
#endif
	tst r10, #(1 << 12)
	mov r11, #4
	movne r11, #1
	bl read_address_from_handler
#ifdef USE_SELF_MODIFYING
thumb9_address_calc_cont_op1:
	mov r0, r10
#else
	str r10, [r8]//r7, r4, lsl #2]
#endif
	msr cpsr_c, #0x97
#ifdef USE_SELF_MODIFYING
	finish_handler_skip_op_self_modifying
#else
	finish_handler_skip_op
#endif

thumb9_address_calc_write:
	tst r10, #(1 << 12)
	and r10, r10, #7
#ifdef USE_SELF_MODIFYING
	strb r10, thumb9_address_calc_write_op1
	b thumb9_address_calc_write_op1
thumb9_address_calc_write_op1:
	mov r11, r0
#else
	ldr r11, [r11, r10, lsl #2]
#endif
	mov r12, #4
	movne r12, #1
	andne r11, r11, #0xFF
	bl write_address_from_handler
	msr cpsr_c, #0x97
#ifdef USE_SELF_MODIFYING
	finish_handler_skip_op_self_modifying
#else
	finish_handler_skip_op
#endif
	
.global thumb10_address_calc
thumb10_address_calc:
	and r8, r10, #(7 << 3)
#ifdef USE_SELF_MODIFYING
	mov r8, r8, lsr #3
	strb r8, thumb10_address_calc_op1
	b thumb10_address_calc_op1
thumb10_address_calc_op1:
	mov lr, r0
#else
	ldr lr, [r11, r8, lsr #1]
#endif
	and r12, r10, #(31 << 6)
	add r9, lr, r12, lsr #5
	ldr pc, [pc, r9, lsr #22]

	nop
	.word address_calc_ignore_thumb	//bios: ignore
	.word address_calc_ignore_thumb	//itcm: ignore
	.word address_calc_ignore_thumb	//main: ignore
	.word address_calc_ignore_thumb	//wram: can't happen
	.word thumb10_address_calc_cont	//io, manual execution
	.word address_calc_ignore_thumb	//pal: can't happen
	.word thumb10_address_calc_cont	//sprites vram, manual execution
	.word address_calc_ignore_thumb	//oam: can't happen
	.word thumb10_address_calc_fix_cartridge	//card: fix
	.word thumb10_address_calc_fix_cartridge	//card: fix	
	.word thumb10_address_calc_fix_cartridge	//card: fix
	.word thumb10_address_calc_fix_cartridge	//card: fix
	.word thumb10_address_calc_fix_cartridge	//card: fix
	.word thumb10_address_calc_cont	//eeprom, manual execution
	.word thumb10_address_calc_fix_sram	//sram: fix
	.word address_calc_ignore_thumb	//nothing: shouldn't happen

thumb10_address_calc_fix_cartridge:
	ldr r13,= 0x083B0000
	cmp r9, r13
	bge thumb10_address_calc_cont
	bic lr, lr, #0x06000000
	sub lr, lr, #0x05000000
	sub lr, lr, #0x00FC0000
#ifdef USE_SELF_MODIFYING
	mov r8, r8, lsl #4
	strb r8, (thumb10_address_calc_fix_cartridge_op1 + 1)
	b thumb10_address_calc_fix_cartridge_op1
thumb10_address_calc_fix_cartridge_op1:
	mov r0, lr
#else
	str lr, [r11, r8, lsr #1]
#endif
	msr cpsr_c, #0x97
#ifdef USE_SELF_MODIFYING
	finish_handler_self_modifying
#else
	finish_handler
#endif

thumb10_address_calc_fix_sram:
	sub lr, lr, #0x0B800000
	sub lr, lr, #0x00008C00
	sub lr, lr, #0x00000060
#ifdef USE_SELF_MODIFYING
	mov r8, r8, lsl #4
	strb r8, (thumb10_address_calc_fix_sram_op1 + 1)
	b thumb10_address_calc_fix_sram_op1
thumb10_address_calc_fix_sram_op1:
	mov r0, lr
#else
	str lr, [r11, r8, lsr #1]
#endif
	msr cpsr_c, #0x97
#ifdef USE_SELF_MODIFYING
	finish_handler_self_modifying
#else
	finish_handler
#endif

thumb10_address_calc_cont:
	tst r10, #(1 << 11)
	beq thumb10_address_calc_write
thumb10_address_calc_read:
	and r8, r10, #7
#ifdef USE_SELF_MODIFYING
	mov r8, r8, lsl #4
	strb r8, (thumb10_address_calc_cont_op1 + 1)
#else
	add r8, r11, r8, lsl #2
#endif
	mov r11, #2
	bl read_address_from_handler
#ifdef USE_SELF_MODIFYING
thumb10_address_calc_cont_op1:
	mov r0, r10
#else
	str r10, [r8]//r7, r4, lsl #2]
#endif
	msr cpsr_c, #0x97
#ifdef USE_SELF_MODIFYING
	finish_handler_skip_op_self_modifying
#else
	finish_handler_skip_op
#endif

thumb10_address_calc_write:
	mov r12, #2
	and r10, r10, #7
#ifdef USE_SELF_MODIFYING
	strb r10, thumb10_address_calc_write_op1
	b thumb10_address_calc_write_op1
thumb10_address_calc_write_op1:
	mov r11, r0, lsl #16
	//.word 0xE1A0B800
	mov r11, r11, lsr #16
#else
	mov r10, r10, lsl #2
	ldrh r11, [r11, r10]
#endif
	bl write_address_from_handler
	msr cpsr_c, #0x97
#ifdef USE_SELF_MODIFYING
	finish_handler_skip_op_self_modifying
#else
	finish_handler_skip_op
#endif

.global thumb15_address_calc
thumb15_address_calc:
#ifdef USE_SELF_MODIFYING
	stmia r11, {r0-r7}	//non-banked registers
#endif
	and r8, r10, #(7 << 8)
	ldr r9, [r11, r8, lsr #6]
	ldr pc, [pc, r9, lsr #22]

	nop
	.word address_calc_ignore_thumb	//bios: ignore
	.word address_calc_ignore_thumb	//itcm: ignore
	.word address_calc_ignore_thumb	//main: ignore
	.word address_calc_ignore_thumb	//wram: can't happen
	.word thumb15_address_calc_cont	//io, manual execution
	.word address_calc_ignore_thumb	//pal: can't happen
	.word thumb15_address_calc_cont	//sprites vram, manual execution
	.word address_calc_ignore_thumb	//oam: can't happen
	.word thumb15_address_calc_fix_cartridge	//card: fix
	.word thumb15_address_calc_fix_cartridge	//card: fix	
	.word thumb15_address_calc_fix_cartridge	//card: fix
	.word thumb15_address_calc_fix_cartridge	//card: fix
	.word thumb15_address_calc_fix_cartridge	//card: fix
	.word thumb15_address_calc_cont	//eeprom, manual execution
	.word thumb15_address_calc_fix_sram	//sram: fix
	.word address_calc_ignore_thumb	//nothing: shouldn't happen

thumb15_address_calc_fix_cartridge:
	ldr r13,= 0x083B0000
	cmp r9, r13
	bge thumb15_address_calc_cont
	bic r9, r9, #0x06000000
	sub r9, r9, #0x05000000
	sub r9, r9, #0x00FC0000
	str r9, [r11, r8, lsr #6]
	msr cpsr_c, #0x97
	finish_handler

thumb15_address_calc_fix_sram:
	sub r9, r9, #0x0B800000
	sub r9, r9, #0x00008C00
	sub r9, r9, #0x00000060
	str r9, [r11, r8, lsr #6]
	msr cpsr_c, #0x97
	finish_handler

thumb15_address_calc_cont:
	and r1, r10, #0xFF
	ldr r12,= 0x10000040
	ldrb r13, [r12, r1]
	add lr, r9, r13, lsl #2
	str lr, [r11, r8, lsr #6]

	tst r10, #(1 << 11)
	mov r8, r11
	beq thumb15_address_calc_cont_write_loop
thumb15_address_calc_cont_load_loop:
	tst r1, #1
	beq thumb15_address_calc_cont_load_loop_cont
	mov r11, #4
	bl read_address_from_handler
	str r10, [r8]
	add r9, r9, #4
thumb15_address_calc_cont_load_loop_cont:
	add r8, r8, #4
	movs r1, r1, lsr #1
	bne thumb15_address_calc_cont_load_loop
	msr cpsr_c, #0x97
	//add lr, #2
	//finish_handler
	finish_handler_skip_op

thumb15_address_calc_cont_write_loop:
	tst r1, #1
	beq thumb15_address_calc_cont_write_loop_cont
	ldr r11, [r8]
	mov r12, #4
	bl write_address_from_handler
	add r9, r9, #4
thumb15_address_calc_cont_write_loop_cont:
	add r8, r8, #4
	movs r1, r1, lsr #1
	bne thumb15_address_calc_cont_write_loop
	msr cpsr_c, #0x97
	//add lr, #2
	//finish_handler
	finish_handler_skip_op

address_calc_ignore_thumb:
	msr cpsr_c, #0x97
	//add lr, #2
	//finish_handler
#ifdef USE_SELF_MODIFYING
	finish_handler_skip_op_self_modifying
#else
	finish_handler_skip_op
#endif