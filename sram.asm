*=$0000
start	ldx #$77
		jmp	start

*=$01c0
send	ldy #$00
next	lda hello,y
		sta light
		lda #$01
		sta status
		jsr waitz
		lda hello,y
		beq send
		iny
		jmp next

waitz	lda status
		bne waitz
		rts

*=$1c00
light	.byte $0
status	.byte $0

hello	.text "Hello, world!"
		.byte 13
		.byte 10
		.byte 0

*=$7ffa
		.byte $c0,$01	; nmi
		.byte $c0,$01	; reset
		.byte $c0,$01	; irq
