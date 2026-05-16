#include <Pong.hpp>


Pong::Pong(char *name) : Game(name)
{

}

void Pong::processGameFrame()
{

}

void Pong::processGameInput(char c) {
	uint16_t* player = nullptr;
	uint16_t step = 0;
	switch(c)
	{
	case 'w':
		player = &P1Pos_;
		step = PLAYER_STEP;
		break;
	case 's':
		player = &P1Pos_;
		step = -PLAYER_STEP;
		break;
	case 'i':
		player = &P2Pos_;
		step = PLAYER_STEP;
		break;
	case 'k':
		player = &P2Pos_;
		step = -PLAYER_STEP;
		break;
	}
	*player = std::clamp<int>(*player + step,MIN_POS,MAX_POS);
}
