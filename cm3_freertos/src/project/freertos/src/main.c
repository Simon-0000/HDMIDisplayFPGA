/*
 ******************************************************************************************
 * @file      main.c
 * @author    GowinSemiconductor
 * @device    Gowin_EMPU(GW1NS-4C)
 * @brief     Main program body.
 ******************************************************************************************
 */

/* Includes ---------------------------------------------------------------------*/
#include "uart.h"
#include "gpio.h"
#include <stdio.h>

//FreeRTOS Library
#include "FreeRTOS.h"
#include "task.h"


/* Definitions ------------------------------------------------------------------*/

#define SW_STR_NAME					"FreerRTOS_V10.2.1"	//Software name
#define SW_STR_EDITION				"V2.1"				//Software version
#define SW_STR_AUTHOR				"GOWIN"				//Owner
#define CHAR_BUFFER_SIZE 16
#define SET_COLOR_CMD "setColor"
#define LOGO_PRINT_ON
#ifdef LOGO_PRINT_ON
#include "logo.h"
#endif	//LOGO_PRINT_ON

#define TASK_DELAY_MS_TO_TICK(ms)	((ms) / (1000 / configTICK_RATE_HZ))

//Task 1
#define LED0_TASK_PRIO			1
#define LED0_STK_SIZE 			40
TaskHandle_t LED0Task_Handler;
volatile int led0_task_flag = 0;

//Task 2
#define LED1_TASK_PRIO			2
#define LED1_STK_SIZE 			20
TaskHandle_t LED1Task_Handler;
volatile int led1_task_flag = 0;


/* Declarations: */
extern void xPortSysTickHandler(void);
static void led0_task(void *pvParameters);
static void led1_task(void *pvParameters);
static void printf_str(const char *str);
static void stars_print(uint8_t n);
static void help_print();
static void sw_edition_print(void);
static void sys_tick_init(void);
void UART0_Handler(void);

//Global variables
uint8_t currentColor[3] = {0};
char colorBuffer[CHAR_BUFFER_SIZE] = {0};
volatile uint8_t colorBufferIndex = 0;

/* Functions ------------------------------------------------------------------*/
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
	gpio_init();       //Initializes GPIO
	
	NVIC_PriorityGroupConfig(NVIC_PriorityGroup_2);
	
	sw_edition_print();
	
//#ifdef LOGO_PRINT_ON
//	printf_str(LOGO);
//#endif	//LOGO_PRINT_ON

	sys_tick_init();				//Initializes Systick
	
	taskENTER_CRITICAL();

	//led0_task
	xTaskCreate((TaskFunction_t )led0_task,
              	(const char *   )"led0_task",
                (uint16_t       )LED0_STK_SIZE,
                (void *         )NULL,
                (UBaseType_t    )LED0_TASK_PRIO,
                (TaskHandle_t * )&LED0Task_Handler);

	NVIC_EnableIRQ(UART0_IRQn);
	taskEXIT_CRITICAL();
	
	vTaskStartScheduler();
	while(1);
}

void substring_before(const char* in, char* out, size_t* size_out, const char seperator)
{
	*size_out = 0;
	while(in[*size_out] != '\0' && in[*size_out] != '\r' && in[*size_out] != seperator)
	{
		out[*size_out] = in[*size_out];
		++(*size_out);

	}
	out[*size_out] = '\0';
}

void setColor(const char* rgb_hex_buffer)
{
	char *endptr;
	long rgb_value = strtol(rgb_hex_buffer,&endptr, 8);

//	char hex_str[10];
//	sprintf(hex_str, "0x%06X\r\n", (unsigned int)rgb_value);
//	printf_str("\r\n setColor=");
//	printf_str(hex_str);
}

int handle_uart_command(const char* buffer, uint8_t size)
{

	printf_str(buffer);
	char cmdBuffer[CHAR_BUFFER_SIZE];
	size_t cmdBufferSize = 0;
	substring_before(buffer,cmdBuffer,&cmdBufferSize,' ');
	printf_str(cmdBuffer);

	if(cmdBufferSize != 0 && strcmp(cmdBuffer, SET_COLOR_CMD) == 0)
	{
		substring_before(&buffer[strlen(SET_COLOR_CMD) + 1],cmdBuffer,&cmdBufferSize,' ');
		if(cmdBufferSize == 6)
		{
			printf_str(cmdBuffer);
			printf_str("\r\n setColor called\r\n");
			setColor(cmdBuffer);
			return 1;
		}
		else
		{
			printf_str("\r\nInvalid syntax for '");
			printf_str(SET_COLOR_CMD);
			printf_str("', use hex numbers '<RRGGBB>'");
		}
	}
	else
	{
		printf_str("\r\nInvalid command '");
		printf_str(cmdBuffer);
		printf_str("'");
	}

	return 0;
}


void UART0_Handler(void)
{
    if (UART_GetRxIRQStatus(UART0) == SET)
    {
    	static char received[2] = {0};
        received[0] = UART_ReceiveChar(UART0);
    	if(received[0] != 127)
    	{
        	printf_str(received);
            colorBuffer[colorBufferIndex++] = received[0];
    	}
    	else if(colorBufferIndex > 0)
    	{
        	printf_str(received);
    		--colorBufferIndex;
    	}

        if(received[0] == '\r')
        {
        	colorBuffer[colorBufferIndex++] = '\0';
        	if(!handle_uart_command(colorBuffer, colorBufferIndex))
        		help_print();
        	printf_str("\r\n>");
        	colorBufferIndex = 0;

        }
        else if(colorBufferIndex >= CHAR_BUFFER_SIZE)
        {
        	colorBufferIndex = 0;
        	printf_str("\r\n...Buffer overflow, input ignored... \r\n>");
        }
        UART_ClearRxIRQ(UART0);
    }
}
//Print string
static void printf_str(const char *str)
{
	UART_SendString(UART0, (char *)str);
}

//Print *
static void stars_print(uint8_t n)
{
	while (n--)
	{
		printf_str("*");
	}
}

static void help_print()
{
	printf_str("\r\n--- Available Commands ---");
	printf_str("\r\n 'setColor' <RRGGBB>");
	printf_str("\r\n--------------------------\r\n");
}

//Print software information
static void sw_edition_print(void)
{
	printf_str("\r\n");
	stars_print(48);
	printf_str("\r\n");
	printf_str("************************************************\r\n");
	printf_str("Name:     "SW_STR_NAME"\r\n"
						 "Edition:  "SW_STR_EDITION"\r\n"
						 "Compiled: "__DATE__", "__TIME__"\r\n"
						 "Author:   "SW_STR_AUTHOR"\r\n");
	printf_str("************************************************\r\n");
	stars_print(48);
	printf_str("\r\n\r\n>");
}

//Initializes Systick
static void sys_tick_init(void)
{
	uint32_t temp;
	
	//24-bit register, max value is 16777215
	//When SystemCoreClock is 25MHz, it is 671ms
	//Set value of reload register
	temp = (1000 / configTICK_RATE_HZ) * (SystemCoreClock / 1000) - 1;
	SysTick->LOAD = temp;
	
	SysTick->VAL = temp;	//Reset current counter value

	//Select clock source, enable interrupt, enable counter
	SysTick->CTRL = SysTick_CTRL_CLKSOURCE_Msk | SysTick_CTRL_TICKINT_Msk | SysTick_CTRL_ENABLE_Msk; 
}

//Systick interrupt handler function
void SysTick_Handler(void)
{
	if(taskSCHEDULER_NOT_STARTED != xTaskGetSchedulerState())
    {
        xPortSysTickHandler();	
    }
}

//Task 1
static void led0_task(void *pvParameters)
{
  while (1)
	{
		vTaskDelay(TASK_DELAY_MS_TO_TICK(1000));

//		printf_str("0.task0\r\n");
//		if (0 == led0_task_flag)
//		{
//			GPIO_ResetBit(GPIO0, GPIO_Pin_0);
//		}
//		else
//		{
//			GPIO_SetBit(GPIO0, GPIO_Pin_0);
//		}
//		led0_task_flag = !led0_task_flag;

	}
}
