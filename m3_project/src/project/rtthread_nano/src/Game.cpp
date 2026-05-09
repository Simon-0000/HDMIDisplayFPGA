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
	rt_thread_t shellThread = rt_thread_find(FINSH_THREAD_NAME);
	if (shellThread != RT_NULL)//TODO check if the thread was already started before doing that
	{
		rt_thread_resume(shellThread);
		rt_schedule();
	}

	rt_thread_t gameThread = rt_thread_find(name_);
	if (gameThread != RT_NULL) //TODO check if the thread was already stopped before doing that
		rt_thread_control(gameThread, RT_THREAD_CTRL_CLOSE, RT_NULL);
}

void Game::processInputs()
{
}

static void processThread(void* param)
{
	rt_kprintf("Game thread started, disabling shell");
	for(int i = 0; i < 3; i++)
	{
		rt_kprintf(".");
		rt_thread_mdelay(500);
	}

	rt_thread_t shellThread = rt_thread_find(FINSH_THREAD_NAME);
	if (shellThread != RT_NULL)
	{
		rt_thread_suspend(shellThread);
	}

	rt_kprintf("\e[?25l\e[1;1H\e[2J");
	rt_kprintf("---------GAME (press q to quit)---------");
	Game* game = reinterpret_cast<Game*>(param);
	while(true)
	{
		game->processInputs();
		rt_thread_mdelay(100);
	}
	game->stop();
}



