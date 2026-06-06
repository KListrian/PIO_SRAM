ptr = $20

*=$0000
start	ldx #$77
		jmp	start

*=$01c0
reset_entry:
        lda #<resettext
        sta ptr
        lda #>resettext
        sta ptr+1
        jsr send_str

inf		lda byte_in
		cmp #13
		bne inf
		lda #0
		sta byte_in
        
        lda #<helloworld
        sta ptr
        lda #>helloworld
        sta ptr+1
        jsr send_str
        jmp inf

; Subroutine: send_str
; Argument: Pointer to null-terminated string in 'ptr' ($20/$21)
send_str:
        ldy #$00
next_ch:
        lda (ptr),y     ; Read char from string pointer
        beq done        ; End of string (0)?
        sta byte_out    ; Place byte for Pi
        lda #$01
        sta status      ; Signal Pi to send
wait:   lda status      ; Wait for Pi to finish
        bne wait
        iny
        bne next_ch
        inc ptr+1       ; Handle page wrap for long strings
        jmp next_ch
done:   rts

*=$1c00
byte_out .byte $0
status	 .byte $0
byte_in  .byte $0

resettext 	.text 27,"[36m","*** 6502 Retro processor ***",27,"[0m",13,10
		  	.text "Ready",13,10,0

helloworld	.text 27,"[36m","Hello World!",27,"[0m",13,10,0

*=$7ffa
		.byte $c0,$01	; nmi
		.byte $c0,$01	; reset
		.byte $c0,$01	; irq
