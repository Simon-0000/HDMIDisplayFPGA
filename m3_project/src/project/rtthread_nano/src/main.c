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


static void setColor(const char* rgb_hex_buffer)
{
	char *endptr;
	long rgb_value = strtol(rgb_hex_buffer, &endptr, 16);

	char hex_str[16];
	rt_snprintf(hex_str, sizeof(hex_str), "0x%06X\r\n", (unsigned int)rgb_value);
	rt_kprintf("\r\n setColor=");
	rt_kprintf(hex_str);
	*((volatile uint32_t*)APB2_MASTER_1_BASE) = (uint32_t)rgb_value;
}

void setColor_cmd(int argc, char **argv)
{
    if (argc < 2)
        rt_kprintf("Usage: setColor <RRGGBB>\n");
    else if (strlen(argv[1]) != 6)

        rt_kprintf("Error: Provide 6 hex characters <RRGGBB>\n");
    else
    	setColor(argv[1]);
}

MSH_CMD_EXPORT_ALIAS(setColor_cmd, setColor, Set RGB color RRGGBB);
