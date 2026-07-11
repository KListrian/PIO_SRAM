#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/pio.h"
#include "hardware/clocks.h"
#include "hardware/watchdog.h"
#include "serial.pio.h"
#include "sram.h"
#include "core1.h"

#define SERIAL_PIN 26
#define SERIAL_BAUD 115200

#define C64_SCREEN_ADDR 0x0400
#define C64_SCREEN_SIZE 1000

static PIO serial_pio;
static uint serial_sm;
static uint serial_rx_sm;
static void __not_in_flash_func(pico_reset)()
{
    serial_program_puts(serial_pio, serial_sm, "\r\nPico reseted");     // cursor off, clear screen, home
    serial_program_wait_tx_done(serial_pio, serial_sm, SERIAL_BAUD);

    watchdog_enable(200, 1);
    while(1); 
}

static void __not_in_flash_func(check_rx)(volatile uint8_t *byte_to_6502)
{
    while (!pio_sm_is_rx_fifo_empty(serial_pio, serial_rx_sm))
    {
        uint32_t val = pio_sm_get(serial_pio, serial_rx_sm);
        int ch = (int)(val >> 24u);
        if (ch == 1) // Ctrl+A
        {
            pico_reset();
        }
        else if (byte_to_6502 != NULL)
        {
            *byte_to_6502 = (uint8_t)ch;
        }
    }
}

static void __not_in_flash_func(serial_tx_char)(uint8_t ch, volatile uint8_t *byte_to_6502)
{
    // Process any pending RX bytes before transmitting to keep the FIFO clean
    check_rx(byte_to_6502);

    // Send the character
    serial_program_putc(serial_pio, serial_sm, ch);
    
    // Wait for transmission to finish
    serial_program_wait_tx_done(serial_pio, serial_sm, SERIAL_BAUD);

    // Wait for the local echo to appear in the RX FIFO
    while (pio_sm_is_rx_fifo_empty(serial_pio, serial_rx_sm))
    {
        tight_loop_contents();
    }

    // Read and discard the echo
    pio_sm_get(serial_pio, serial_rx_sm);
}

static void __not_in_flash_func(serial_tx_puts)(const char *s, volatile uint8_t *byte_to_6502)
{
    while (*s)
    {
        serial_tx_char((uint8_t)*s++, byte_to_6502);
    }
}

void __not_in_flash_func(core1_entry)()
{
    serial_pio = pio1;
    uint serial_offset = pio_add_program(serial_pio, &serial_program);
    uint serial_rx_offset = pio_add_program(serial_pio, &serial_rx_program);
    serial_sm = pio_claim_unused_sm(serial_pio, true);
    serial_rx_sm = pio_claim_unused_sm(serial_pio, true);
    serial_program_init(serial_pio, serial_sm, serial_offset, SERIAL_PIN, SERIAL_BAUD);
    serial_rx_program_init(serial_pio, serial_rx_sm, serial_rx_offset, SERIAL_PIN, SERIAL_BAUD);

    // Keep both enabled!
    pio_sm_set_enabled(serial_pio, serial_rx_sm, true);

    gpio_put(PICO_DEFAULT_LED_PIN, 1);
    serial_tx_puts("\033[2J\033[H\033[?25h", NULL);    // clear the terminal, home, cursor on

    volatile uint8_t *byte_from_6502 = &sram[0x1c00];           // byte points ta memory location voliatile makes sure it passes between cores
    volatile uint8_t *byte_from_6502_status = &sram[0x1c01];    // tr_status points ta memory location voliatile makes sure it passes between cores
    volatile uint8_t *byte_to_6502 = &sram[0x1c02];             // byte points ta memory location voliatile makes sure it passes between cores

    // Clear any leftover echo/input bytes from the RX FIFO
    while (!pio_sm_is_rx_fifo_empty(serial_pio, serial_rx_sm))
    {
        pio_sm_get(serial_pio, serial_rx_sm);
    }

    while (true)
    {
        gpio_xor_mask(1u << PICO_DEFAULT_LED_PIN);  // toggle led

        // 1. Check for incoming characters from terminal
        check_rx(byte_to_6502);

        // 2. Check if the 6502 has placed a byte for us to send to the terminal
        if (*byte_from_6502_status == 1)
        {
            serial_tx_char(*byte_from_6502, byte_to_6502);
            *byte_from_6502_status = 0;
        }
        else if (*byte_from_6502_status == 2)
        {
            C64_text_screen_update(byte_to_6502);
            *byte_from_6502_status = 0;
        }

        tight_loop_contents();
    }
}

void __not_in_flash_func(C64_text_screen_update)(volatile uint8_t *byte_to_6502)
{
    serial_tx_puts("\033[?25l\033[H", byte_to_6502);     // cursor off, clear screen, home
 
    for (size_t i = 0; i < C64_SCREEN_SIZE; ++i)
    {
        uint8_t data = sram[C64_SCREEN_ADDR + i];
        
        // Send data using the PIO state machine
        if (data != 0)
        {
            serial_tx_char(data, byte_to_6502);
        }
        
        // Add a carriage return and newline after every 40 characters
        if ((i + 1) % 40 == 0)
        {
            serial_tx_puts("\r\n", byte_to_6502);
        }
    }
}
