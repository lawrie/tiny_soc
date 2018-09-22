#include <stdint.h>
#include <stdbool.h>

#include <audio/audio.h>
#include <video/video.h>
#include <songplayer/songplayer.h>
#include <uart/uart.h>
#include <sine_table/sine_table.h>

#include "graphics_data.h"

// a pointer to this is a null pointer, but the compiler does not
// know that because "sram" is a linker symbol from sections.lds.
extern uint32_t sram;

#define reg_spictrl (*(volatile uint32_t*)0x02000000)
#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_leds  (*(volatile uint32_t*)0x03000000)

extern const struct song_t song_pacman;

#define CAN_GO_LEFT 1
#define CAN_GO_RIGHT 2
#define CAN_GO_UP 4
#define CAN_GO_DOWN 8
#define FOOD 16

#define BLANK_CELL 0
#define FOOD_CELL1 4
#define FOOD_CELL2 5
#define FOOD_CELL3 12
#define FOOD_CELL4 13

uint32_t counter_frequency = 16000000/50;  /* 50 times per second */
uint32_t led_state = 0x00000000;

uint8_t board[14][15];
uint8_t pac, pac_image, pac_x, pac_y;
uint8_t inky, blinky, pinky, clyde;
uint8_t inky_x, blinky_x, pinky_x, clyde_x;
uint8_t inky_y, blinky_y, pinky_y, clyde_y;

uint32_t set_irq_mask(uint32_t mask); asm (
    ".global set_irq_mask\n"
    "set_irq_mask:\n"
    ".word 0x0605650b\n"
    "ret\n"
);

uint32_t set_timer_counter(uint32_t val); asm (
    ".global set_timer_counter\n"
    "set_timer_counter:\n"
    ".word 0x0a05650b\n"
    "ret\n"
);

void set_up_board() {
  for(int y = 0; y < 14; y++) {
    for(int x = 0;  x < 15; x++) {
      uint8_t n = 0;
      uint8_t t = tile_data[((y*2 + 1) << 5) + x*2 + 1];

      if (t != BLANK_CELL && t != FOOD_CELL1) continue;

      if (t == FOOD_CELL1) n |= FOOD;

      if (y > 0) {
        uint8_t above = tile_data[(((y-1)*2 + 2) << 5) + x*2 + 1];
        if (above == BLANK_CELL || above == FOOD_CELL3) n |= CAN_GO_UP;
      }

      if (y < 13) {
        uint8_t below = tile_data[(((y+1)*2 + 1) << 5) + x*2 + 1];
        if (below == BLANK_CELL || below == FOOD_CELL1) n |= CAN_GO_DOWN;
      }

      if (x > 0) {
        uint8_t left = tile_data[((y*2 + 1) << 5) + (x-1)*2 + 2];
        if (left == BLANK_CELL || left == FOOD_CELL2) n |= CAN_GO_LEFT;
      }

      if (x < 14) {
        uint8_t right = tile_data[((y*2 + 1) << 5) + (x+1)*2 + 1];
        if (right == BLANK_CELL || right == FOOD_CELL1) n |= CAN_GO_RIGHT;
      }

      board[y][x] = n;
    }
  }      
}

void print_board() {
  print("Board:\n");
  for(int y = 0; y < 14; y++) {
    for(int x = 0; x < 15; x++) {
      print_hex(board[y][x],2);
      print(" ");
    }
    print("\n");
  }
}  

void setup_screen() {
  vid_init();
  vid_set_x_ofs(0);
  vid_set_y_ofs(0);
  int tex,x,y;

  for (tex = 0; tex < 64; tex++) {
    for (x = 0; x < 8; x++) {
      for (y = 0 ; y < 8; y++) {
        int texrow = tex >> 3;   // 0-7, row in texture map
        int texcol = tex & 0x07; // 0-7, column in texture map
        int pixx = (texcol<<3)+x;
        int pixy = (texrow<<3)+y;
        uint32_t pixel = texture_data[(pixy<<6)+pixx];
        vid_set_texture_pixel(tex, x, y, pixel);
      }
    }
  }
  for (x = 0; x < 32; x++) {
    for (y = 0; y < 32; y++) {
      vid_set_tile(x,y,tile_data[(y<<5)+x]);
    }
  }
  pac = 0;
  inky = 1;
  pinky = 2;
  blinky = 3;
  clyde = 4;
  pac_image = 0;
  inky_x = 6;
  inky_y = 10;
  pinky_x = 7;
  pinky_y = 10;
  blinky_x = 8;
  blinky_y = 10;
  clyde_x = 7;
  clyde_y = 9;
  vid_write_sprite_memory(pac_image, sprites[pac]);
  pac_x = 0;
  pac_y = 13;
  
  vid_set_sprite_pos(pac, 8 + (pac_x << 4), 8 + (pac_y << 4));
  vid_set_sprite_pos(inky, 8 + (inky_x << 4), 8 + (inky_y << 4));
  vid_set_sprite_pos(pinky, 8 + (pinky_x << 4), 8 + (pinky_y << 4));
  vid_set_sprite_pos(blinky, 8 + (blinky_x << 4), 8 + (blinky_y << 4));
  vid_set_sprite_pos(clyde, 8 + (clyde_x << 4), 8 + (clyde_y << 4));
  vid_set_sprite_colour(pac, 3);
  vid_set_sprite_colour(inky, 6);
  vid_set_sprite_colour(pinky, 5);
  vid_set_sprite_colour(blinky, 2);
  vid_set_sprite_colour(clyde, 1);
  vid_set_image_for_sprite(pac, pac_image);
  vid_set_image_for_sprite(inky, pac_image);
  vid_set_image_for_sprite(pinky, pac_image);
  vid_set_image_for_sprite(blinky, pac_image);
  vid_set_image_for_sprite(clyde, pac_image);
  vid_enable_sprite(pac, 1);
  vid_enable_sprite(inky, 1);
  vid_enable_sprite(pinky, 1);
  vid_enable_sprite(blinky, 1);
  vid_enable_sprite(clyde, 1);
}

void irq_handler(uint32_t irqs, uint32_t* regs)
{
  /* fast IRQ (4) */
  if ((irqs & (1<<4)) != 0) {
    // print_str("[EXT-IRQ-4]");
  }

  /* slow IRQ (5) */
  if ((irqs & (1<<5)) != 0) {
    // print_str("[EXT-IRQ-5]");
  }

  /* timer IRQ */
  if ((irqs & 1) != 0) {
    // retrigger timer
    set_timer_counter(counter_frequency);

    led_state = led_state ^ 0x01;
    reg_leds = led_state;
    songplayer_tick();
  }

}

void main() {

    reg_uart_clkdiv = 138;  // 16,000,000 / 115,200
    print("\n\nBooting..\n");
    print("Enabling IRQs..\n");
    set_irq_mask(0x00);

    setup_screen();
    
    set_up_board();
    print_board();

    songplayer_init(&song_pacman);

    print("Switching to dual IO SPI mode..\n");

    // switch to dual IO mode
    reg_spictrl = (reg_spictrl & ~0x007F0000) | 0x00400000;

    print("Playing song and blinking\n");

    // set timer interrupt to happen 1/50th sec from now
    // (the music routine runs from the timer interrupt)
    set_timer_counter(counter_frequency);

    int old_x = 255, old_y = 255, old2_x = 255, old2_y = 255;

    uint32_t time_waster = 0;
    while (1) {
        time_waster = time_waster + 1;
        if ((time_waster & 0xffff) == 0xffff) {
          /* update sprite locations */
          old_x = pac_x;
          old_y = pac_y;

          int n = board[pac_y][pac_x];
          if ((n & CAN_GO_UP) && (pac_y-1 != old2_y)) pac_y--;
          else if ((n & CAN_GO_RIGHT) && (pac_x+1 != old2_x)) pac_x++;
          else if ((n & CAN_GO_DOWN) && (pac_y+1 != old2_y)) pac_y++;
          else if ((n & CAN_GO_LEFT)) pac_x--;
          
          vid_set_sprite_pos(pac, 8 + (pac_x << 4), 8 + (pac_y << 4));
          
          old2_x = old_x;
          old2_y = old_y;
          old_x = pac_x;
          old_y = pac_y;
        }
    }
}
