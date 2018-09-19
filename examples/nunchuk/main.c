#include <stdint.h>
#include <stdbool.h>
#include "nunchuk.h"

// a pointer to this is a null pointer, but the compiler does not
// know that because "sram" is a linker symbol from sections.lds.
extern uint32_t sram;

#define reg_spictrl (*(volatile uint32_t*)0x02000000)
#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data (*(volatile uint32_t*)0x02000008)
#define reg_leds (*(volatile uint32_t*)0x03000000)
#define reg_buttons (*(volatile uint32_t*)0x03000004)

extern uint32_t _sidata, _sdata, _edata, _sbss, _ebss,_heap_start;

uint32_t set_irq_mask(uint32_t mask); asm (
    ".global set_irq_mask\n"
    "set_irq_mask:\n"
    ".word 0x0605650b\n"
    "ret\n"
);

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

void delay(uint32_t n) {
  for (uint32_t i = 0; i < n; i++) asm volatile ("");
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


    // Initialize the Nunchuk
    i2c_send_cmd(0x40, 0x00);

    uint32_t timer = 0;
       
    while (1) {
        timer = timer + 1;

        if ((timer & 0xffff) == 0xffff) {
          i2c_send_cmd(0x00, 0x00);
          delay(1000);
          uint8_t jx = i2c_read();
          print("Joystick x: ");
          print_hex(jx, 2);
          print("\n");
          uint8_t jy = i2c_read();
          print("Joystick y: ");
          print_hex(jy, 2);
          print("\n");
          uint8_t ax = i2c_read();
          print("Acceleration x: ");
          print_hex(ax, 2);
          print("\n");
          uint8_t ay = i2c_read();
          print("Acceleration y: ");
          print_hex(ay, 2);
          print("\n");
          uint8_t az = i2c_read();
          print("Acceleration z: ");
          print_hex(az, 2);
          print("\n");
          uint8_t rest = i2c_read();
          print("Buttons: ");
          print_hex(rest & 3, 2);
          print("\n");
        } 
    } 
}
