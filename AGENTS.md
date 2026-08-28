# Custom Agents for PIO_SRAM Project

This file defines custom agents specialized for this Raspberry Pi Pico SRAM/PIO project.

## Available Agents

### Pico Embedded Developer
- **Description**: Use when debugging PIO assembly, SRAM configuration, or C code for Raspberry Pi Pico projects
- **Expertise**: PIO programming, assembly debugging, Pico SDK integration
- **Tools**: read, search, execute
- **Purpose**: Specialized agent for embedded systems development on RP2350

### SRAM Assembly Specialist
- **Description**: Use when analyzing or fixing 64tass assembly code, particularly for SRAM operations
- **Expertise**: 6502 assmbly code, 64tass syntax, memory addressing, low-level operations
- **Tools**: read, search, edit
- **Purpose**: Read-only assembly analysis and debugging without execution

### Build & Flash Manager
- **Description**: Use when compiling, building, or flashing the Pico with OpenOCD/picotool
- **Expertise**: CMake builds, ninja compilation, device flashing, debugging targets
- **Tools**: execute, read, search
- **Purpose**: Manage build system and device operations

#### 64tass Configuration
- **64tass executable**: `/c/tmp/64tass.exe` (Windows path: `c:/tmp/64tass.exe`)
- **Assembly command**: `/c/tmp/64tass.exe -f sram.asm -o sram.bin`
- **Important**: Do not assume `64tass` is available on `PATH`; always use the absolute path above.

#### CA65 LD65 Configuration
- **ca65 executable**: `/c/tmp/ca65.exe` (Windows path: `c:/tmp/ca65.exe`)
- **ld65 executable**: `/c/tmp/ld65.exe` (Windows path: `c:/tmp/ld65.exe`)
- **Assembly command**: `/c/tmp/ca65.exe`
- **Linker command**: `/c/tmp/ld65.exe`
- **Important**: Do not assume `64tass` is available on `PATH`; always use the absolute path above.
