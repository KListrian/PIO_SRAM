; --- Hardware Register Definitions ---
byte_out = $1C00
status   = $1C01
byte_in  = $1C02

; --- Zero Page ---
ptr      = $20
range_ptr = $22
limit_ptr = $24

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

strt            lda #'a'
                sta scrmem
inf	        lda byte_in     ; check for byte in
	        cmp #97         ; 'a' key to trigger send hello world
	        beq sndhlo
                inc scrmem
                lda scrmem
                cmp #'z'
                beq strt
                jmp inf


sndhlo  lda #0
        sta byte_in     ; clear byte_in
        
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
        jsr send_char
        iny
        bne next_ch
        inc ptr+1       ; Handle page wrap for long strings
        jmp next_ch
done:   rts

; Subroutine: dump_range
; Sends memory range [range_ptr] to [limit_ptr] (inclusive) as hex text
dump_range:
        ldy #$00
dump_loop:
        lda (range_ptr),y
        jsr print_hex_byte
        
        lda #$20        ; Space separator
        jsr send_char

        ; Check if range_ptr == limit_ptr
        lda range_ptr
        cmp limit_ptr
        bne inc_range
        lda range_ptr+1
        cmp limit_ptr+1
        beq dump_done   ; Reached the end

inc_range:
        inc range_ptr
        bne dump_loop
        inc range_ptr+1
        jmp dump_loop
dump_done:
        rts

print_hex_byte:
        pha             ; Save original byte
        lsr             ; Shift high nibble to low
        lsr
        lsr
        lsr
        jsr conv_send   ; Convert and send high nibble
        pla             ; Restore original byte
        and #$0F        ; Mask for low nibble
conv_send:
        cmp #$0A
        bcc is_num
        adc #$06        ; Convert to A-F (Carry is set)
is_num: adc #$30        ; Convert to '0'-'9'
send_char:
        sta byte_out
        lda #$01
        sta status      ; Signal Pi to send
tx_wait:lda status      ; Wait for Pi to finish
        bne tx_wait
        rts

*=$0400
 ;             1234567890123456789012345678901234567890
 scrmem .text "      *** 6502 Retro processor ***      "
        .text "READY                                   "
        .text "                                        "
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "1234567890123456789012345678901234567890"
        .text "12345678901234567890123456789012345678AA"
        .byte $00       ; null terminator for scrmem

*=$1c00
        .byte $00       ; reserved for byte_out
        .byte $00       ; reserved for status
        .byte $00       ; reserved for byte_in

ESC = $1B

resettext 	.text ESC, "[36m", "6502 resetted, message over serial", ESC, "[0m", 13, 10, 0
helloworld	.text ESC, "[36m", "Meddelande från 6502", ESC, "[0m", 13, 10, 0
homeclear	.text ESC, "[2J", ESC, "[H", 0

*=$7ffa
		.byte $c0,$01	; nmi
		.byte $c0,$01	; reset
		.byte $c0,$01	; irq
