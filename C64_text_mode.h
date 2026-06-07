#ifndef C64_TEXT_MODE_H
#define C64_TEXT_MODE_H

#include <stdint.h>
#include <stddef.h>

#define C64_SCREEN_ADDR 0x0400
#define C64_SCREEN_SIZE 1000

// Reads 1000 bytes of C64 screen memory ($0400..$07E7) into `buffer`.
// `buffer` must be at least C64_SCREEN_SIZE bytes.
void read_C64_screen(uint8_t *buffer, size_t buffer_size);

#endif // C64_TEXT_MODE_H
