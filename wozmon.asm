;  The WOZ Monitor for the Apple 1
;  Written by the great Steve Wozniak in 1976

; 0300: A9 41 20 E6 7F 4C 00 7F, testprogram som laddar A till Acc och anropar ECHO på $7FE9

; CPU
.setcpu "6502"
.debuginfo

.segment "BIOS"

CHRIN:
                LDA byte_in     ; Check if a byte is ready.
                BEQ @no_keypressed ; No, return with A=0.
                jsr CHROUT      ; Yes, output it.
                sec
                rts
@no_keypressed: 
                CLC
                rts

.segment "WOZMON"
; Page 0 Variables
XAML            = $24           ;  Last "opened" location Low
XAMH            = $25           ;  Last "opened" location High
STL             = $26           ;  Store address Low
STH             = $27           ;  Store address High
L               = $28           ;  Hex value parsing Low
H               = $29           ;  Hex value parsing High
YSAV            = $2A           ;  Used to see if hex value is given
MODE            = $2B           ;  $00=XAM, $7F=STOR, $AE=BLOCK XAM

; Serial I/O Variables
byte_out        = $0100         ;  byte_out = $1C00
status          = $0101         ;  status   = $1C01        ;status_out: 0 = empty, 1 = there is a byte
byte_in         = $0102         ;  byte_in  = $1C02
hw_buffer       = $0103         ;  buffer 74HC541 hardwired

IN              = $0200         ;  Input buffer to $027F

RESET:
                CLD             ; Clear decimal arithmetic mode.
                CLI
                LDY #$7F        ; Mask for DSP data direction register.

NOTCR:          CMP #$7F        ; Backspace?    08 eller 7F
                BEQ BACKSPACE   ; Yes.
                CMP #$02        ; ESC? ctrl-b special
                BEQ ESCAPE      ; Yes.
                INY             ; Advance text index.
                BPL NEXTCHAR    ; Auto ESC if > 127.

ESCAPE:         LDA #$5C        ; "\".
                JSR ECHO        ; Output it.

GETLINE:        LDA #$0D        ; CR.
                JSR ECHO        ; Output it.

                LDY #$01        ; Initialize text index.
BACKSPACE:      DEY             ; Back up text index.
                BMI GETLINE     ; Beyond start of line, reinitialize.

NEXTCHAR:       LDA byte_in     ; Key ready?
                BEQ NEXTCHAR    ; Loop until ready.
                PHA
                LDA #$00        ; Clear X for text buffer index. <- new
                STA byte_in     ; Clear input ready flag.        <- new
                PLA
                STA IN,Y        ; Add to text buffer.
                JSR ECHO        ; Display character.       ; comment away to disable echoing of input characters
                CMP #$0D        ; CR?
                BNE NOTCR       ; No.

                LDY #$FF        ; Reset text index.
                LDA #$00        ; For XAM mode.
                TAX             ; 0->X.

SETBLOCK:       ASL

SETSTOR:        ASL             ; Leaves $7B if setting STOR mode.
                STA MODE        ; $00=XAM, $7B=STOR, $AE=BLOCK XAM.

BLSKIP:         INY             ; Advance text index.

NEXTITEM:       LDA IN,Y        ; Get character.
                CMP #$0D        ; CR?
                BEQ GETLINE     ; Yes, done this line.
                CMP #$2E        ; "."?
                BCC BLSKIP      ; Skip delimiter.
                BEQ SETBLOCK    ; Set BLOCK XAM mode.
                CMP #$3A        ; ":"?
                BEQ SETSTOR     ; Yes. Set STOR mode.
                CMP #$52        ; "R"?
                BEQ RUN         ; Yes. Run user program.
                STX L           ; $00->L.
                STX H           ;  and H.
                STY YSAV        ; Save Y for comparison.

NEXTHEX:        LDA IN,Y        ; Get character for hex test.
                EOR #$30        ; Map digits to $0-9.
                CMP #$0A        ; Digit?
                BCC DIG         ; Yes.
                ADC #$88        ; Map letter "A"-"F" to $FA-FF.
                CMP #$FA        ; Hex letter?
                BCC NOTHEX      ; No, character not hex.

DIG:            ASL
                ASL             ; Hex digit to MSD of A.
                ASL
                ASL

                LDX #$04        ; Shift count.

HEXSHIFT:       ASL             ; Hex digit left, MSB to carry.
                ROL L           ; Rotate into LSD.
                ROL H           ; Rotate into MSD’s.
                DEX             ; Done 4 shifts?
                BNE HEXSHIFT    ; No, loop.
                INY             ; Advance text index.
                BNE NEXTHEX     ; Always taken. Check next character for hex.

NOTHEX:         CPY YSAV        ; Check if L, H empty (no hex digits).
                BEQ ESCAPE      ; Yes, generate ESC sequence.

                BIT MODE        ; Test MODE byte.
                BVC NOTSTOR     ; B6=0 STOR, 1 for XAM and BLOCK XAM

                LDA L           ; LSD’s of hex data.
                STA (STL,X)     ; Store at current ‘store index’.
                INC STL         ; Increment store index.
                BNE NEXTITEM    ; Get next item. (no carry).
                INC STH         ; Add carry to ‘store index’ high order.
TONEXTITEM:     JMP NEXTITEM    ; Get next command item.

RUN:            JMP (XAML)      ; Run at current XAM index.

NOTSTOR:        BMI XAMNEXT     ; B7=0 for XAM, 1 for BLOCK XAM.

                LDX #$02        ; Byte count.
SETADR:         LDA L-1,X       ; Copy hex data to
                STA STL-1,X     ;  ‘store index’.
                STA XAML-1,X    ; And to ‘XAM index’.
                DEX             ; Next of 2 bytes.
                BNE SETADR      ; Loop unless X=0.

NXTPRNT:        BNE PRDATA      ; NE means no address to print.
                LDA #$0D        ; CR.
                JSR ECHO        ; Output it.
                LDA XAMH        ; ‘Examine index’ high-order byte.
                JSR PRBYTE      ; Output it in hex format.
                LDA XAML        ; Low-order ‘examine index’ byte.
                JSR PRBYTE      ; Output it in hex format.
                LDA #$3A        ; ":".
                JSR ECHO        ; Output it.

PRDATA:         LDA #$20        ; Blank.
                JSR ECHO        ; Output it.
                LDA (XAML,X)    ; Get data byte at ‘examine index’.
                JSR PRBYTE      ; Output it in hex format.
XAMNEXT:        STX MODE        ; 0->MODE (XAM mode).
                LDA XAML
                CMP L           ; Compare ‘examine index’ to hex data.
                LDA XAMH
                SBC H
                BCS TONEXTITEM  ; Not less, so no more data to output.

                INC XAML
                BNE MOD8CHK     ; Increment ‘examine index’.
                INC XAMH

MOD8CHK:        LDA XAML        ; Check low-order ‘examine index’ byte
                AND #$07        ;  For MOD 8=0
                BPL NXTPRNT     ; Always taken.

PRBYTE:         PHA             ; Save A for LSD.
                LSR
                LSR
                LSR             ; MSD to LSD position.
                LSR
                JSR PRHEX       ; Output hex digit.
                PLA             ; Restore A.

PRHEX:          AND #$0F        ; Mask LSD for hex print.
                ORA #$30        ; Add "0".
                CMP #$3A        ; Digit?
                BCC ECHO        ; Yes, output it.
                ADC #$06        ; Add offset for letter.

CHROUT:
ECHO:           
                PHA             ; Save A for echo wait.
                STA byte_out    ; Output character.
                LDA #$01        ; Tell there is a byte to send.
                STA status      ; Signal Pi that a byte is ready.
@wait_echo:     LDA status      ; Check if output is ready.
                BNE @wait_echo
                PLA             ; Restore A.
                RTS             ; Return.

; Interrupt Vectors
.segment "RESETVEC"
		.word RESET 	; nmi
		.word RESET	    ; reset
		.word RESET 	; irq
