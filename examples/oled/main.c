#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "icosoc.h"
#include "gfx.h"

void send_cmd(uint8_t r) {
	icosoc_oled_cs(1);
	icosoc_oled_dc(0);
	icosoc_oled_cs(0);

	uint8_t d = icosoc_oled_xfer(r);
	icosoc_oled_cs(1);
	//printf("Command %x\n", d);
}

void send_data(uint8_t d) {
	icosoc_oled_cs(1);
	icosoc_oled_dc(1);
	icosoc_oled_cs(0);

	uint8_t r2 = icosoc_oled_xfer(d);

	icosoc_oled_cs(1);
	//printf("Data %x\n", r);
}

void reset() {
	icosoc_oled_rst(1);
        for (int i = 0; i < 20000; i++) asm volatile ("");
	icosoc_oled_rst(0);
        for (int i = 0; i < 200000; i++) asm volatile ("");
	icosoc_oled_rst(1);
}

void init() {
	printf("Initialising\n");
	icosoc_oled_cs(1);
	icosoc_oled_rst(1);
	icosoc_oled_prescale(4); // 5Mhz
	icosoc_oled_mode(false, false);
	printf("Reset\n");
	reset();
        printf("Reset pin is %ld\n", icosoc_oled_getrst());
	send_cmd(0xFD); // Command lock
	send_data(0x12); // 
	send_cmd(0xFD); // Command lock
	send_data(0xB1); // 
	send_cmd(0xAE); // Display off
	send_cmd(0xB3); // Set clock div
	send_cmd(0xF1); // 
	send_cmd(0xCA); // Mux ratio
	send_data(0x7F); // 
	send_cmd(0xA0); // Set remap
	send_data(0x74); // RGB
	send_cmd(0x15);
	send_data(0x00);
	send_data(0x7F);
	send_cmd(0x75);
	send_data(0x00);
	send_data(0x7F);
	send_cmd(0xA1); // Startline
	send_data(0x00); // 0
	send_cmd(0xA2); // Display offset
	send_data(0x00); // 0
	send_cmd(0xB5); // Set GPIO
	send_data(0x00); // 0
	send_cmd(0xAB); // Funcion select
	send_data(0x01); // internal diode drop
	send_cmd(0xB1); // Precharge
	send_cmd(0x32); // 
	send_cmd(0xBE); // Vcomh
	send_cmd(0x05); // 
	send_cmd(0xA6); // Normal display
	send_cmd(0xC1); // Set Contrast ABC
	send_data(0xC8); // 
	send_data(0x80); // 
	send_data(0xC8); // 
	send_cmd(0xC7); // Set Contrast Master
	send_data(0x0F); // 
	send_cmd(0xB4); // Set VSL
	send_data(0xA0); // 
	send_data(0xB5); // 
	send_data(0x55); // 
	send_cmd(0x86); // Precharge 2
	send_data(0x01); // 
	send_cmd(0xAF); // Switch on

	printf("Initialisation done\n");

}

void drawPixel(int16_t x, int16_t y, uint16_t color) {
        if((x < 0) || (y < 0) || (x >= WIDTH) || (y >= HEIGHT)) return;
	
	send_cmd(0x15);
	send_data(x);
	send_data(WIDTH-1);

	send_cmd(0x75);
	send_data(y);
	send_data(HEIGHT-1);

	send_cmd(0x5C);

	send_data(color >> 8);
	send_data(color);
}

int main()
{
	init();
	fillRect(0,0,WIDTH,HEIGHT,0);


	for (uint8_t i = 0;; i++)
	{
		icosoc_leds(i);

		drawText(20,30,"Hello World!",(i << 8) + i);

		for (int i = 0; i < 100000; i++)
			asm volatile ("");

	}
}

