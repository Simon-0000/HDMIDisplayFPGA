extern "C" {
#include <rtthread.h>
#include <stdio.h>
#include <stdint.h>
#include "uart.h"
}

static void processThread(void*);

class Game
{
public:
	Game();
	virtual ~Game() = default;
	void start();
	void stop();
protected:
	virtual void processGameFrame() = 0;

private:
	friend void processThread(void*);
	void processInputs();
	static constexpr size_t STACK_SIZE = 256;
	uint32_t gamePeriod;
	struct rt_thread thread_;
	rt_dev_t console_;
	uint8_t stack_[STACK_SIZE];
};
