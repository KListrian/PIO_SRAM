; --- Hardware Register Definitions ---
byte_out = $1C00
status   = $1C01
byte_in  = $1C02

; --- Zero Page ---
ptr      = $20

*=$0000
start	ldx #$77
		jmp	start

*=$01c0
reset_entry:
        lda #<homeclear
        sta ptr
        lda #>homeclear
        sta ptr+1
        jsr send_str

        lda #<resettext
        sta ptr
        lda #>resettext
        sta ptr+1
        jsr send_str

inf		lda byte_in
		cmp #97
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
        .byte $00       ; reserved for byte_out
        .byte $00       ; reserved for status
        .byte $00       ; reserved for byte_in

ESC = $1B

resettext 	.text ESC, "[36m", "*** 6502 Retro processor ***", ESC, "[0m", 13, 10
		  	.text "Ready", 13, 10, 0

helloworld	.text ESC, "[36m", "Hello World!", ESC, "[0m", 13, 10, 0

homeclear	.text ESC, "[2J", ESC, "[H", 0

*=$7ffa
		.byte $c0,$01	; nmi
		.byte $c0,$01	; reset
		.byte $c0,$01	; irq
