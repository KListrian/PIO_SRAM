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
static bool in_tx_mode = false;

static void software_reset()
{
    watchdog_enable(1, 1);
    while(1); 
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
    serial_program_set_tx_mode(serial_pio, serial_sm, serial_rx_sm, SERIAL_PIN);

    gpio_put(PICO_DEFAULT_LED_PIN, 1);
    serial_program_puts(serial_pio, serial_sm, "\033[2J\033[H\033[?25h");    // clear the terminal, home, cursor on

    serial_program_wait_tx_done(serial_pio, serial_sm, SERIAL_BAUD);
    serial_program_set_rx_mode(serial_pio, serial_sm, serial_rx_sm, SERIAL_PIN);

    volatile uint8_t *byte_from_6502 = &sram[0x1c00];           // byte points ta memory location voliatile makes sure it passes between cores
    volatile uint8_t *byte_from_6502_status = &sram[0x1c01];    // tr_status points ta memory location voliatile makes sure it passes between cores
    volatile uint8_t *byte_to_6502 = &sram[0x1c02];             // byte points ta memory location voliatile makes sure it passes between cores

    while (true)
    {
        gpio_xor_mask(1u << PICO_DEFAULT_LED_PIN);  // toggle led

        // 1. Check if the 6502 has placed a byte for us to send to the terminal
        if (*byte_from_6502_status == 1)
        {
            if (!in_tx_mode)
            {
                serial_program_set_tx_mode(serial_pio, serial_sm, serial_rx_sm, SERIAL_PIN);
                in_tx_mode = true;
            }
            serial_program_putc(serial_pio, serial_sm, *byte_from_6502);
            serial_program_wait_tx_done(serial_pio, serial_sm, SERIAL_BAUD);
            
            // Clear status to signal 6502 that it can send the next character
            *byte_from_6502_status = 0;
        }
        else
        {
            // 2. Otherwise, check for terminal input. Only switch to RX if needed.
            if (in_tx_mode)
            {
                serial_program_set_rx_mode(serial_pio, serial_sm, serial_rx_sm, SERIAL_PIN);
                in_tx_mode = false;
            }

            // Use a short timeout to keep the loop responsive to the 6502
            int ch = serial_rx_program_getc_timeout_us(serial_pio, serial_rx_sm, 10);
            
            // Only update memory if an actual character was received (ch != -1)
            if (ch != -1)
            {
                if (ch==4) C64_text_screen_update();           // 4=^d to print C64 screen buffer
                else *byte_to_6502 = (uint8_t)ch;
            }
        }

        tight_loop_contents();
    }
}

void __not_in_flash_func(C64_text_screen_update)(void)
{
    // Ensure the PIO is in TX mode for the bulk transfer
    serial_program_set_tx_mode(serial_pio, serial_sm, serial_rx_sm, SERIAL_PIN);
    in_tx_mode = true;
    serial_program_puts(serial_pio, serial_sm, "\033[?25l\033[H");     // cursor off, clear screen, home
    serial_program_wait_tx_done(serial_pio, serial_sm, SERIAL_BAUD);

    for (size_t i = 0; i < C64_SCREEN_SIZE; ++i)
    {
        uint8_t data = sram[C64_SCREEN_ADDR + i];
        
        // Send data using the PIO state machine
        if (data!=0) serial_program_putc(serial_pio, serial_sm, data);
        
        // Wait for the character to be physically shifted out to avoid FIFO overflow
        serial_program_wait_tx_done(serial_pio, serial_sm, SERIAL_BAUD);

        // Add a carriage return and newline after every 40 characters
        if ((i + 1) % 40 == 0)
        {
            serial_program_puts(serial_pio, serial_sm, "\r\n");
            serial_program_wait_tx_done(serial_pio, serial_sm, SERIAL_BAUD);
        }
    }

    serial_program_puts(serial_pio, serial_sm, "\033[?25h");     // cursor on
    serial_program_wait_tx_done(serial_pio, serial_sm, SERIAL_BAUD);
}
