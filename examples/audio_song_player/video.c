#include "video.h"

void vid_set_texture_pixel(uint32_t texnum, uint32_t x, uint32_t y, uint32_t pixel)
{
  reg_video_texmem[(texnum << 6) + (y << 3) + x] = pixel;
}

void vid_set_texture(uint32_t texnum, const uint32_t *data)
{
  int ofs = 0;
  for (int y = 0; y < 8; y++) {
    for (int x = 0; x < 8; x++) {
      reg_video_texmem[texnum<<6 + ofs] = data[ofs];
      ++ofs;
    }
  }
}

void vid_set_tile(uint32_t x, uint32_t y, uint32_t texture)
{
  reg_video_tilemem[(y<<6)+x]=texture;
}

void vid_set_x_ofs(uint32_t x)
{
  reg_video_xofs = x;
}

void vid_set_y_ofs(uint32_t y)
{
  reg_video_yofs = y;
}
