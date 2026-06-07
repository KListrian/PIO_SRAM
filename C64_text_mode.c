#include "C64_text_mode.h"
#include "sram.h"

void read_C64_screen(uint8_t *buffer, size_t buffer_size)
{
    if (buffer == NULL || buffer_size < C64_SCREEN_SIZE)
    {
        return;
    }

    for (size_t i = 0; i < C64_SCREEN_SIZE; ++i)
    {
        buffer[i] = sram[C64_SCREEN_ADDR + i];
    }
}
