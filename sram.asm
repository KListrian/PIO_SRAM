*=$0000
start	ldx #$77
		jmp	start

*=$01c0
		ldy #65
loop	sty light
waitz	ldx light
		bne waitz
		inc y
		jmp loop
		
		

*=$1c00
light	.byte $00

hello = "READY."

*=$7ffa
		.byte $c0,$01	; nmi
		.byte $c0,$01	; reset
		.byte $c0,$01	; irq
