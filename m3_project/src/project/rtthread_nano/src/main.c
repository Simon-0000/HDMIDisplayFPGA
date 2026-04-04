/*
 ******************************************************************************************
 * @file      main.c
 * @author    GowinSemiconductor
 * @device    Gowin_EMPU(GW1NS-4C)
 * @brief     Main program body.
 ******************************************************************************************
 */

/* Includes ------------------------------------------------------------------*/
#include <rtthread.h>
#include <stdio.h>
#include "gw1ns4c.h"
#include "uart.h"

#define APB2_MASTER_1_BASE 0x40002400
#define SET_COLOR_CMD "setColor"




static void setColor(const char* rgb_hex_buffer);
static int handle_uart_command(const char* buffer, uint8_t size);
static void UART0_Handler(void);


int main(void)
{
	SystemInit();      //Initializes system clock
	uart_init(UART0,   //Initializes UART0
	          9600,   //Baudrate
	          1,       //Tx
	          1,       //Rx
	          0,       //Tx interrupt
	          1,       //Rx interrupt
	          0,       //Tx overflow interrupt
	          0);      //Rx overflow interrupt

    rt_kprintf("hello :)\n");

	while(1)
	{
		rt_thread_mdelay(10000);
	}
}

static void setScreenColor(const uint32_t rgb_value)
{
	*((volatile uint32_t*)(APB2_MASTER_1_BASE + 0x04)) = 0;

	for (uint32_t i = 0; i < (640 * 480); i++)
	{
		*((volatile uint32_t*)(APB2_MASTER_1_BASE + 0x00)) = (uint32_t)rgb_value;
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

MSH_CMD_EXPORT(setAnimationCmd, Run RGB fade animation);

MSH_CMD_EXPORT_ALIAS(setColorCmd, setColor, Set RGB color RRGGBB);
MSH_CMD_EXPORT_ALIAS(setAnimationCmd, setAnimation, Start an rgb animation until you recall the function);
