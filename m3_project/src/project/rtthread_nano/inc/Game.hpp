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
	Game(char *name);
	virtual ~Game() = default;
	void start();
	void stop();
protected:
	virtual void processGameFrame() = 0;

private:
	friend void processThread(void*);
	void processInputs();
	static constexpr rt_uint8_t THREAD_PRIORITY = 3;
	static constexpr size_t STACK_SIZE = 1024;
	char *name_;
	uint32_t gamePeriod;
	struct rt_thread thread_;
	rt_dev_t console_;

	__attribute__((aligned(8)))
	uint8_t stack_[STACK_SIZE];
};
