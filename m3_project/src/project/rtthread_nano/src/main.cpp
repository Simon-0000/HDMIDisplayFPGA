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
	while(1)
	{
		rt_thread_mdelay(10000);
	}
}

static void setScreenColor(const uint32_t rgb_value)
{
	uint32_t current_block = 0;
	uint32_t pair_counter = 0;

	uint16_t r = (uint16_t)((rgb_value >> 16) & 0xFF) >> 3;
	uint16_t g = (uint16_t)((rgb_value >> 8) & 0xFF) >> 2;
	uint16_t b = (uint16_t)((rgb_value) & 0xFF) >> 3;

	uint16_t rgb565_color = (r << 11) | (g << 5) | b;

	uint32_t pixel_pair = ((uint32_t)rgb565_color << 16) | rgb565_color;

	*((volatile uint32_t*)(APB2MASTER1_BASE + 0x04)) = current_block;

	for (uint32_t i = 0; i < ((640 * 480) / 2); i++)
	{
		*((volatile uint32_t*)(APB2MASTER1_BASE + 0x00)) = pixel_pair;

		pair_counter++;

		if (pair_counter == 128)
		{
			pair_counter = 0;
			current_block++;
			*((volatile uint32_t*)(APB2MASTER1_BASE + 0x04)) = current_block;
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

MSH_CMD_EXPORT(pong, Start pongGame);
MSH_CMD_EXPORT(clear, Clear terminal);
MSH_CMD_EXPORT(setAnimationCmd, Run RGB fade animation);
MSH_CMD_EXPORT_ALIAS(setColorCmd, setColor, Set RGB color RRGGBB);
MSH_CMD_EXPORT_ALIAS(setAnimationCmd, setAnimation, Start an rgb animation until you recall the function);
