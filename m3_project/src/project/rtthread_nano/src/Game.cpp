#include "Game.hpp"

Game::Game()
{

}

void Game::start()
{
	rt_thread_init(&thread_,
		"Game",
		processThread,
		this,
		stack_,
		STACK_SIZE,
		10,
		10);
	rt_thread_startup(&thread_); // Don't forget to actually start it!
}

void Game::stop()
{

}

void Game::processInputs()
{
	if (UART0->STATE & 0x01)
	    {
	        char key = UART0->DATA;
	        if (key == 'w') {
	            rt_kprintf("Player moved UP\n");
	        }
	        else if (key == ' ') {
	            rt_kprintf("Player fired LASER\n");
	        }
	    }
}

static void processThread(void* param)
{
	Game* game = reinterpret_cast<Game*>(param);
	game->processInputs();
}



