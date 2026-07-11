#ifndef CORE1_H
#define CORE1_H

/**
 * @brief Entry point for Core 1, handling serial terminal and command processing.
 * 
 * This function is marked as __not_in_flash_func to ensure it runs from RAM.
 */
void core1_entry(void);

/**
 * @brief Enters a continuous loop that reads 1000 bytes of C64 screen memory
 * ($0400..$07E7) and sends them to the serial PIO.
 */
void __not_in_flash_func(C64_text_screen_update)(volatile uint8_t *byte_to_6502);

#endif // CORE1_H