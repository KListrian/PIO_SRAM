*=$0000
start	ldx #$77
		jmp	start

*=$01c0
loop
		inc light
		jmp loop
		
		

*=$1c00
light	.byte $00

*=$1ffa
		.byte $00,$00	; nmi
		.byte $c0,$01	; reset
		.byte $00,$00	; irq

