/*
 ******************************************************************************************
 * @file      main.c
 * @author    GowinSemiconductor
 * @device    Gowin_EMPU(GW1NS-4C)
 * @brief     Main program body.
 ******************************************************************************************
 */

/* Includes ------------------------------------------------------------------*/


//#include "PongGame.hpp"
#include "Pong.hpp"
extern "C" {
#include <cstdlib>
#include <cstring>
#include <rtthread.h>
#include <stdio.h>
#include "gw1ns4c.h"
#include "uart.h"
}


static void setColor(const char* rgb_hex_buffer);
static int handle_uart_command(const char* buffer, uint8_t size);
static void clear(int argc, char **argv);
static void pong(int argc, char **argv);


extern "C" int main(void)
{
	SystemInit();
	uart_init(UART0,
	          9600,
	          1,
	          1,
	          0,
	          1,
	          0,
	          0);
	clear(0,0);
    rt_kprintf("hello :)\n");
//    setColor("FFFFFF");
	while(1)
	{
		rt_thread_mdelay(10000);
	}
}

static void setScreenColor(const uint32_t rgb_value)
{
	uint16_t r = (uint16_t)((rgb_value >> 16) & 0xFF) >> 3;
	uint16_t g = (uint16_t)((rgb_value >> 8) & 0xFF) >> 3;
	uint16_t b = (uint16_t)((rgb_value) & 0xFF) >> 3;

	uint16_t rgb555_color = (r << 10) | (g << 5) | b;
	uint32_t pixel_pair = ((uint32_t)rgb555_color << 16) | rgb555_color;

	uint32_t words_per_line = 320;
	uint32_t block_width_words = 32;
	uint32_t block_height = 32;

	uint32_t blocks_x = words_per_line / block_width_words;
	uint32_t blocks_y = 480 / block_height;

	volatile uint32_t* fifo_reg = (volatile uint32_t*)APB2MASTER1_BASE;

	for (uint32_t by = 0; by < blocks_y; by++)
	{
		for (uint32_t bx = 0; bx < blocks_x; bx++)
		{
			uint32_t base_address = (by * block_height * words_per_line) + (bx * block_width_words);

			*fifo_reg = base_address;

			for (uint32_t py = 0; py < block_height; py++)
			{
				for (uint32_t px = 0; px < block_width_words; px++)
				{
					*fifo_reg = pixel_pair;
				}
			}
		}
	}
}

static void setColor(const char* rgb_hex_buffer)
{
	char *endptr;
	long rgb_value = strtol(rgb_hex_buffer, &endptr, 16);
	setScreenColor(rgb_value);

}

void setColorCmd(int argc, char **argv)
{
    if (argc < 2)
        rt_kprintf("Usage: setColor <RRGGBB>\n");
    else if (strlen(argv[1]) != 6)

        rt_kprintf("Error: Provide 6 hex characters <RRGGBB>\n");
    else
    	setColor(argv[1]);
}

void setAnimationCmd(int argc, char **argv)
{
	for (int i = 0; i < 255; i++) {
		setScreenColor(((255 - i) << 16) | (i << 8) | 0);
	}

	for (int i = 0; i < 255; i++) {
		setScreenColor(0 | ((255 - i) << 8) | i);
	}

	for (int i = 0; i < 255; i++) {
		setScreenColor((i << 16) | 0 | (255 - i));
	}

}
void pong(int argc, char **argv)
{
    static Pong game("PongGame");
    game.start();
}

void clear(int argc, char **argv)
{
	rt_kprintf("\e[1;1H\e[2J");
}
void setSingleBlock(int argc, char **argv)
{
    if (argc < 4) {
        rt_kprintf("Usage: setBlock <bx> <by> <RRGGBB>\n");
        return;
    }

    uint32_t bx = atoi(argv[1]);
    uint32_t by = atoi(argv[2]);
    uint32_t rgb_value = strtol(argv[3], NULL, 16);

    uint32_t words_per_line = 320;
    uint32_t block_width_words = 32;
    uint32_t block_height = 32;

    // Boundary check
    if (bx >= (words_per_line / block_width_words) || by >= (480 / block_height)) {
        rt_kprintf("Error: Coordinates out of bounds\n");
        return;
    }

    uint16_t r = (uint16_t)((rgb_value >> 16) & 0xFF) >> 3;
    uint16_t g = (uint16_t)((rgb_value >> 8) & 0xFF) >> 3;
    uint16_t b = (uint16_t)((rgb_value) & 0xFF) >> 3;
    uint16_t rgb555_color = (r << 10) | (g << 5) | b;
    uint32_t pixel_pair = ((uint32_t)rgb555_color << 16) | rgb555_color;

    volatile uint32_t* fifo_reg = (volatile uint32_t*)APB2MASTER1_BASE;

    uint32_t base_address = (by * block_height * words_per_line) + (bx * block_width_words);

    *fifo_reg = base_address;

    for (uint32_t py = 0; py < block_height; py++)
    {
        for (uint32_t px = 0; px < block_width_words; px++)
        {
            *fifo_reg = pixel_pair;
        }
    }
    rt_kprintf("Block (%d, %d) set to %s\n", bx, by, argv[3]);
}
void setCrossBlock(int argc, char **argv)
{
    if (argc < 4) {
        rt_kprintf("Usage: setCross <bx> <by> <RRGGBB>\n");
        return;
    }

    uint32_t bx = atoi(argv[1]);
    uint32_t by = atoi(argv[2]);
    uint32_t rgb_value = strtol(argv[3], NULL, 16);

    // Color conversion
    uint16_t r = (uint16_t)((rgb_value >> 16) & 0xFF) >> 3;
    uint16_t g = (uint16_t)((rgb_value >> 8) & 0xFF) >> 3;
    uint16_t b = (uint16_t)((rgb_value) & 0xFF) >> 3;
    uint16_t rgb555_color = (r << 10) | (g << 5) | b;
    uint32_t pixel_pair = ((uint32_t)rgb555_color << 16) | rgb555_color;

    uint32_t words_per_line = 320;
    uint32_t block_width_words = 32;
    uint32_t block_height = 32;

    volatile uint32_t* fifo_reg = (volatile uint32_t*)APB2MASTER1_BASE;
    uint32_t base_address = (by * block_height * words_per_line) + (bx * block_width_words);

    *fifo_reg = base_address;

    for (uint32_t py = 0; py < block_height; py++)
	{
		for (uint32_t px = 0; px < block_width_words; px++)
		{
			if ((px == block_width_words / 2) || (py == block_height / 2)) {
				*fifo_reg = pixel_pair & 0x7FFFFFFF;
			} else {
				*fifo_reg = 0x80000000;
			}
		}
	}
    rt_kprintf("Cross drawn at (%d, %d)\n", bx, by);
}

MSH_CMD_EXPORT_ALIAS(setCrossBlock, setCross, Set a block with a cross pattern <bx> <by> <RRGGBB>);
MSH_CMD_EXPORT_ALIAS(setSingleBlock, setBlock, Set a single block color <bx> <by> <RRGGBB>);
MSH_CMD_EXPORT(pong, Start pongGame);
MSH_CMD_EXPORT(clear, Clear terminal);
MSH_CMD_EXPORT(setAnimationCmd, Run RGB fade animation);
MSH_CMD_EXPORT_ALIAS(setColorCmd, setColor, Set RGB color RRGGBB);
MSH_CMD_EXPORT_ALIAS(setAnimationCmd, setAnimation, Start an rgb animation until you recall the function);
