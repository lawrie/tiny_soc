#include <stdint.h>
#include <stdbool.h>

// a pointer to this is a null pointer, but the compiler does not
// know that because "sram" is a linker symbol from sections.lds.
extern uint32_t sram;

#define reg_spictrl (*(volatile uint32_t*)0x02000000)
#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data (*(volatile uint32_t*)0x02000008)
#define reg_leds (*(volatile uint32_t*)0x03000000)
#define reg_buttons (*(volatile uint32_t*)0x03000004)
#define reg_cs (*(volatile uint32_t*)0x05000004)
#define reg_dc (*(volatile uint32_t*)0x05000010)
#define reg_rst (*(volatile uint32_t*)0x05000014)
#define reg_xfer (*(volatile uint32_t*)0x05000008)
#define reg_prescale (*(volatile uint32_t*)0x05000000)
#define reg_mode (*(volatile uint32_t*)0x0500000c)

#define WIDTH 128
#define HEIGHT 128

extern uint32_t _sidata, _sdata, _edata, _sbss, _ebss,_heap_start;

uint32_t set_irq_mask(uint32_t mask); asm (
    ".global set_irq_mask\n"
    "set_irq_mask:\n"
    ".word 0x0605650b\n"
    "ret\n"
);
// --------------------------------------------------------

void send_cmd(uint8_t r) {
	reg_cs = 1;
	reg_dc = 0;
	reg_cs = 0;

	reg_xfer = r;
	reg_cs = 1;
}

void send_data(uint8_t d) {
	reg_cs = 1;
	reg_dc = 1;
	reg_cs = 0;

	reg_xfer = d;
	reg_cs = 1;
}

void reset() {
	reg_rst = 1;
        for (int i = 0; i < 20000; i++) asm volatile ("");
	reg_rst = 0;
        for (int i = 0; i < 200000; i++) asm volatile ("");
	reg_rst = 1;;
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

// --------------------------------------------------------

void putchar(char c)
{
	if (c == '\n')
		putchar('\r');
	reg_uart_data = c;
}

void print(const char *p)
{
	while (*p)
		putchar(*(p++));
}

void print_hex(uint32_t v, int digits)
{
	for (int i = 7; i >= 0; i--) {
		char c = "0123456789abcdef"[(v >> (4*i)) & 15];
		if (c == '0' && i >= digits) continue;
		putchar(c);
		digits = i;
	}
}

void print_dec(uint32_t v)
{
	if (v >= 100) {
		print(">=100");
		return;
	}

	if      (v >= 90) { putchar('9'); v -= 90; }
	else if (v >= 80) { putchar('8'); v -= 80; }
	else if (v >= 70) { putchar('7'); v -= 70; }
	else if (v >= 60) { putchar('6'); v -= 60; }
	else if (v >= 50) { putchar('5'); v -= 50; }
	else if (v >= 40) { putchar('4'); v -= 40; }
	else if (v >= 30) { putchar('3'); v -= 30; }
	else if (v >= 20) { putchar('2'); v -= 20; }
	else if (v >= 10) { putchar('1'); v -= 10; }

	if      (v >= 9) { putchar('9'); v -= 9; }
	else if (v >= 8) { putchar('8'); v -= 8; }
	else if (v >= 7) { putchar('7'); v -= 7; }
	else if (v >= 6) { putchar('6'); v -= 6; }
	else if (v >= 5) { putchar('5'); v -= 5; }
	else if (v >= 4) { putchar('4'); v -= 4; }
	else if (v >= 3) { putchar('3'); v -= 3; }
	else if (v >= 2) { putchar('2'); v -= 2; }
	else if (v >= 1) { putchar('1'); v -= 1; }
	else putchar('0');
}

char getchar_prompt(char *prompt)
{
	int32_t c = -1;

	uint32_t cycles_begin, cycles_now, cycles;
	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));

	if (prompt)
		print(prompt);

	reg_leds = ~0;
	while (c == -1) {
		__asm__ volatile ("rdcycle %0" : "=r"(cycles_now));
		cycles = cycles_now - cycles_begin;
		if (cycles > 12000000) {
			if (prompt)
				print(prompt);
			cycles_begin = cycles_now;
			reg_leds = ~reg_leds;
		}
		c = reg_uart_data;
	}
	reg_leds = 0;
	return c;
}

char getchar()
{
	return getchar_prompt(0);
}

// --------------------------------------------------------


void main() {
    reg_uart_clkdiv = 139;

    set_irq_mask(0xff);

    // zero out .bss section
    for (uint32_t *dest = &_sbss; dest < &_ebss;) {
        *dest++ = 0;
    }

    // switch to dual IO mode
    reg_spictrl = (reg_spictrl & ~0x007F0000) | 0x00400000;
 
    print("\n");
    print("  ____  _          ____         ____\n");
    print(" |  _ \\(_) ___ ___/ ___|  ___  / ___|\n");
    print(" | |_) | |/ __/ _ \\___ \\ / _ \\| |\n");
    print(" |  __/| | (_| (_) |__) | (_) | |___\n");
    print(" |_|   |_|\\___\\___/____/ \\___/ \\____|\n");

    uint32_t timer = 0;

    /*print("Initialising\n");      
    reg_cs = 1;
    reg_rst = 1;
    reg_prescale = 4; // 4Mhz
    reg_mode = 0;
    print("Reset\n");
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

    print("Initialisation done\n");*/

    int x = 0;
    while (1) {
        timer = timer + 1;
        if (timer > 10000) reg_cs = x++;
	if ((timer & 0xffff) == 0) {
            print("Oled display\n");
        }
    } 
}
