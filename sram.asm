*=$0000
start	ldx #$77
		jmp	start

*=$01c0
loop
		lda #$00
		sta light
		nop
		nop
		lda #$55
		sta light
		nop
		jmp loop
		
		

*=$1c00
light	.byte $00

*=$7ffa
		.byte $00,$00	; nmi
		.byte $c0,$01	; reset
		.byte $00,$00	; irq

