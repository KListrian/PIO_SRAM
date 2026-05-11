.section .time_critical.sram, "aw"
.global sram
.balign 4
sram:
    .incbin "sram.bin"
.global sram_end
sram_end: