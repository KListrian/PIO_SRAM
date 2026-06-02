#ifndef CORE1_H
#define CORE1_H

/**
 * @brief Entry point for Core 1, handling serial terminal and command processing.
 * 
 * This function is marked as __not_in_flash_func to ensure it runs from RAM.
 */
void core1_entry(void);

#endif // CORE1_H