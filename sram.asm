*=$0000
start	ldx #$77
		jmp	start

*=$01c0
loop
		inc light
		jmp loop
		
		

*=$1c00
light	.byte $00

*=$7ffa
		.byte $c0,$01	; nmi
		.byte $c0,$01	; reset
		.byte $c0,$01	; irq
