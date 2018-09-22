HDL_DIR = ../../hdl
PICOSOC_DIR = $(HDL_DIR)/picosoc
FIRMWARE_DIR = ../../firmware
INCLUDE_DIR = ../../libraries
VERILOG_FILES = $(HDL_DIR)/game_top.v $(PICOSOC_DIR)/gpio_led/gpio_led.v $(PICOSOC_DIR)/audio/audio_simple.v $(PICOSOC_DIR)/audio/clock_divider.v $(PICOSOC_DIR)/audio/pdm_dac.v $(PICOSOC_DIR)/video/video.v $(PICOSOC_DIR)/video/VGASyncGen.v $(PICOSOC_DIR)/video/sprite_memory.v $(PICOSOC_DIR)/video/texture_memory.v $(PICOSOC_DIR)/video/tile_memory.v $(PICOSOC_DIR)/video/sprite.v $(PICOSOC_DIR)/memory/spimemio.v $(PICOSOC_DIR)/uart/simpleuart.v $(PICOSOC_DIR)/picosoc.v $(HDL_DIR)/picorv32/picorv32.v 
PCF_FILE = $(HDL_DIR)/pins.pcf
LDS_FILE = $(FIRMWARE_DIR)/sections.lds
START_FILE = $(FIRMWARE_DIR)/start.S
C_FILES = main.c $(INCLUDE_DIR)/uart/uart.c $(INCLUDE_DIR)/video/video.c $(INCLUDE_DIR)/songplayer/songplayer.c song_pacman.c
DEFINES = 

%.s : %.c
	/opt/riscv32i/bin/riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostartfiles -Wl,-Bstatic,-T,sections.lds,-Map=firmware.map,--cref  -ffreestanding -nostdlib -fverbose-asm -S $<
 
firmware: firmware.bin
	tinyprog -u firmware.bin

include $(HDL_DIR)/tiny_soc.mk

