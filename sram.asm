*=$0000
start	ldx #$77
		jmp	start

*=$01c0
send	ldy #$00
next	lda resettext,y
		beq inf         ; End of string? Go wait for 'a'
		sta byte_out    ; Place byte for Pi
		lda #$01
		sta status      ; Signal Pi to send
		jsr waitz       ; Wait for Pi to finish
		iny             ; Next character
		jmp next

inf		lda byte_in
		cmp #97
		bne inf
		lda #0
		sta byte_in
		jmp send

waitz	lda status
		bne waitz
		rts

*=$1c00
byte_out .byte $0
status	 .byte $0
byte_in  .byte $0

resettext 	.text 27,"[36m","*** 6502 Retro processor ***",27,"[0m",13,10
		  	.text "Ready",13,10,0

*=$7ffa
		.byte $c0,$01	; nmi
		.byte $c0,$01	; reset
		.byte $c0,$01	; irq
