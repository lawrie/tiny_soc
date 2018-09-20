#include <stdint.h>
#include <stdbool.h>
#include <uart/uart.h>

// a pointer to this is a null pointer, but the compiler does not
// know that because "sram" is a linker symbol from sections.lds.
extern uint32_t sram;

#define reg_spictrl (*(volatile uint32_t*)0x02000000)
#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_leds (*(volatile uint32_t*)0x03000000)
#define reg_buttons (*(volatile uint32_t*)0x03000004)
#define reg_i2c_write (*(volatile uint32_t*)0x07000000)
#define reg_i2c_read (*(volatile uint32_t*)0x07000004)
#define reg_sprite (*(volatile uint32_t*)0x05000000)

uint32_t set_irq_mask(uint32_t mask); asm (
    ".global set_irq_mask\n"
    "set_irq_mask:\n"
    ".word 0x0605650b\n"
    "ret\n"
);

void irq_handler(uint32_t irqs, uint32_t* regs) {
}

void main() {
    reg_uart_clkdiv = 139;

    set_irq_mask(0xff);

    // switch to dual IO mode
    reg_spictrl = (reg_spictrl & ~0x007F0000) | 0x00400000;
 
    uint32_t timer = 0;
    uint16_t sprite_x = 0, sprite_y = 0;
       
    while (1) {
        timer = timer + 1;

        if ((timer & 0xffff) == 0x3fff) {
          reg_i2c_write = 0xd2000000; // Request data
        } else if ((timer & 0xffff) == 0x7fff) {
          reg_i2c_read = 0x00a40001; // Request data
        } else if ((timer & 0xffff) == 0) {
            sprite_x = (sprite_x + 10) % 640;
            sprite_y = (sprite_y + 10) % 480;
            print("Sprite x is ");
            print_hex(sprite_x,8);
            print(", Sprite y is ");
            print_hex(sprite_y,8);
            print("\n"); 
            reg_sprite = (sprite_y << 16) + sprite_x;
            print("i2c status: ");
            print_hex(reg_i2c_read, 8);
            print("\n");
        }    
    } 
}
