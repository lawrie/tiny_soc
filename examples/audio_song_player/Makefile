VERILOG_FILES = ../../hdl/gundy_top.v ../../hdl/picosoc/memory/spimemio.v ../../hdl/picosoc/uart/simpleuart.v ../../hdl/picosoc/picosoc.v ../../hdl/picorv32/picorv32.v ../../hdl/picosoc/gpio_led_gpio_led.v ../../hdl/picosoc/audio/pdm_dac.v 
PCF_FILE = ../../hdl/pins.pcf
LDS_FILE = ../../firmware/sections.lds
START_FILE = ../../firmware/start.S
C_FILES = firmware.c songplayer.c song_petergun.c uart.c video.c
DEFINES = 
INCLUDE_DIR = ../../libraries

%.s : %.c
        /opt/riscv32i/bin/riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostartfiles -Wl,-Bstatic,-T,sections.lds,-Map=firmware.map,--cref  -ffreestanding -nostdlib -fverbose-asm -S $<

include ../../hdl/tiny_soc.mk





