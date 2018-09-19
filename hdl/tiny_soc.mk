upload: hardware.bin firmware.bin
	tinyprog -p hardware.bin -u firmware.bin

hardware.blif: $(VERILOG_FILES) 
	yosys -f "verilog $(DEFINES)" -ql hardware.log -p 'synth_ice40 -top top -blif hardware.blif' $^

hardware.asc: $(PCF_FILE) hardware.blif
	arachne-pnr -d 8k -P cm81 -o hardware.asc -p $(PCF_FILE) hardware.blif

hardware.bin: hardware.asc
	icetime -d hx8k -c 12 -mtr hardware.rpt hardware.asc
	icepack hardware.asc hardware.bin

firmware.elf: $(C_FILE) 
	/opt/riscv32i/bin/riscv32-unknown-elf-gcc -march=rv32imc -nostartfiles -Wl,-Bstatic,-T,$(LDS_FILE),--strip-debug,-Map=firmware.map,--cref  -ffreestanding -nostdlib -o firmware.elf $(START_FILE) $(C_FILE)

firmware.bin: firmware.elf
	/opt/riscv32i/bin/riscv32-unknown-elf-objcopy -O binary firmware.elf /dev/stdout > firmware.bin

clean:
	rm -f firmware.elf firmware.hex firmware.bin firmware.o firmware.map \
	      hardware.blif hardware.log hardware.asc hardware.rpt hardware.bin

