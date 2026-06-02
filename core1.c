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

static void software_reset()
{
    watchdog_enable(1, 1);
    while(1); 
}

void __not_in_flash_func(core1_entry)()
{
    PIO serial_pio = pio1;
    uint serial_offset = pio_add_program(serial_pio, &serial_program);
    uint serial_rx_offset = pio_add_program(serial_pio, &serial_rx_program);
    uint serial_sm = pio_claim_unused_sm(serial_pio, true);
    uint serial_rx_sm = pio_claim_unused_sm(serial_pio, true);
    serial_program_init(serial_pio, serial_sm, serial_offset, SERIAL_PIN, SERIAL_BAUD);
    serial_rx_program_init(serial_pio, serial_rx_sm, serial_rx_offset, SERIAL_PIN, SERIAL_BAUD);
    serial_program_set_tx_mode(serial_pio, serial_sm, serial_rx_sm, SERIAL_PIN);

    gpio_put(PICO_DEFAULT_LED_PIN, 1);
    busy_wait_ms(500);

    serial_program_puts(serial_pio, serial_sm, "\033[2J\033[H*** RP 6502 Terminal ***\r\n");
    serial_program_wait_tx_done(serial_pio, serial_sm, SERIAL_BAUD);
    serial_program_set_rx_mode(serial_pio, serial_sm, serial_rx_sm, SERIAL_PIN);

    volatile uint8_t *light = &sram[0x1c00];    // light points ta memory location voliatile makes sure it passes between cores
    char command_text[80];
    size_t command_len = 0;
    while (true)
    {
        int command = serial_rx_program_getc_timeout_us(serial_pio, serial_rx_sm, 1000);
        if (command < 0)
        {
            tight_loop_contents();
            continue;
        }

        if (command != '\r' && command != '\n')
        {
            if (command_len + 1 < sizeof(command_text))
            {
                command_text[command_len++] = (char)command;
            }
            continue;
        }

        if (command_text[0]=='@' && command_text[1]=='@' && command_text[2]=='r' && command_len==3)
        {
            serial_program_set_tx_mode(serial_pio, serial_sm, serial_rx_sm, SERIAL_PIN);
            serial_program_puts(serial_pio, serial_sm, "\r\nReset pi pico\r\n");
            software_reset();
        }

//        command_len = 0;
        gpio_xor_mask(1u << PICO_DEFAULT_LED_PIN);

        char serial_text[6];
        snprintf(serial_text, sizeof(serial_text), "%u\r\n", *light);

        serial_program_set_tx_mode(serial_pio, serial_sm, serial_rx_sm, SERIAL_PIN);
        serial_program_puts(serial_pio, serial_sm, serial_text);
        serial_program_wait_tx_done(serial_pio, serial_sm, SERIAL_BAUD);
        serial_program_set_rx_mode(serial_pio, serial_sm, serial_rx_sm, SERIAL_PIN);
    }
}