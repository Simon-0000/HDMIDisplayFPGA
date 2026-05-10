#include "Game.hpp"
extern "C" {
#include "shell.h"
}

Game::Game(char *name) : name_(name)
{
	rt_thread_t gameThread = rt_thread_find(name_);
	if (gameThread != RT_NULL)
		rt_kprintf("ERROR: Game name already used, undefined behavior");
}

void Game::start()
{
	rt_thread_init(&thread_,
		name_,
		processThread,
		this,
		stack_,
		STACK_SIZE,
		THREAD_PRIORITY,
		10);

	rt_thread_startup(&thread_);
}

void Game::stop()
{

	isRunning_ = false;
}

void Game::processInputs()
{
	while (UART_GetRxBufferFull(UART0) != SET)
	{
		rt_thread_mdelay(5);
		if (!isRunning_) return;
	}

	char key = UART_ReceiveChar(UART0);
	UART_ClearRxIRQ(UART0);

	if (key == 'w') {
		rt_kprintf("UP\r\n");
	}
	else if (key == 's') {
		rt_kprintf("DOWN\r\n");
	}
	else if (key == 'q') {
		stop();
	}
}

static void processThread(void* param)
{
	rt_thread_t shellThread = rt_thread_find(FINSH_THREAD_NAME);
	if (shellThread != RT_NULL)
	{
		rt_thread_suspend(shellThread);
	}


	rt_kprintf("\e[?25l\e[1;1H\e[2J");
	rt_kprintf("---------GAME (press q to quit)---------");
	Game* game = reinterpret_cast<Game*>(param);
	game->isRunning_ = true;
	while(game->isRunning_)
	{
		rt_kprintf(".");
		game->processInputs();
		rt_thread_mdelay(25);
	}

	rt_kprintf("\e[?25h\e[1;1H\e[2J");
	if (shellThread != RT_NULL)
	{
		rt_thread_resume(shellThread);
        rt_schedule();
	}
}



