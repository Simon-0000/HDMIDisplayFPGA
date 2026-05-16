#pragma once
#include "Game.hpp"

class Pong : public Game
{
public:
	Pong(char *name);
protected:
	void processGameFrame() override;
	void processGameInput(char c) override;
private:
	static constexpr uint16_t PLAYER_STEP = 25;
	static constexpr uint16_t BAR_LENGTH = 75;
	static constexpr uint16_t SCREEN_HEIGHT = 480;
	static constexpr uint16_t MAX_POS = SCREEN_HEIGHT-BAR_LENGTH;
	static constexpr uint16_t MIN_POS = 0;
	
	uint16_t P1Pos_ = 0;
	uint16_t P2Pos_ = 0;
	
};
