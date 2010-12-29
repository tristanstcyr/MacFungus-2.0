#include <string>
#include <iostream>
#include <vector>
#include <MFGrid.h>
#include <sstream>

static const unsigned int DEFAULT_BITES = 3;

struct Color 
{ 
	float red, green, blue; 
	Color(float r, float g, float b) : red(r), green(g), blue(b) { }
	Color():red(0.0f), green(0.0f), blue(0.0f) { }
};

// MFPlayer contains full necessary player description
struct MFPlayer 
{
	bool alive;
	unsigned int bites;
	int blocks, turnSkips;
	Color color;
	std::string name;
	
	MFPlayer() : color(Color()), name("Olaf"), bites(DEFAULT_BITES), alive(true), blocks(1), turnSkips(0) {}
	MFPlayer(Color color, std::string name, unsigned int bites, bool isAlive) 
		: color(color), name(name), bites(bites), alive(isAlive), turnSkips(0) {}
};

// Data model of the game
class MFGame 
{
private:
	bool isGameStarted, isUsingHotCorners;
	int currentShapeIndex, currentPlayerIndex, winnerIndex, shapeDegrees;
	MFGrid currentGrid, lastMoveGrid;
	std::vector<boost::shared_ptr<MFPlayer> > players;
	std::vector<MFGridShape> shapesVector;
	std::vector<pMFGrid> lastErasedSequence, lastEatenSequence;
	
	int playerIndex(boost::shared_ptr<MFPlayer>);
	boost::shared_ptr<std::string> loadXMLfile(std::string path);

	std::vector<char*> sandwichedChars(std::vector<char*>initialChars, const int& playerIndex);
	void eraseDisconnects();
	void punishPlayerAtIndex(const int& anIndex);
	void endTurn();
	
public:
	MFGame(unsigned int gridSize, std::vector<boost::shared_ptr<MFPlayer> > thePlayers);
	MFGame(const char *xmlCString);
	MFGame();
	
	~MFGame() {}
	
	void setGridSize(const int& anInt);											// game must be restarted after changing the grid size
	void setIsUsingHotCorners(const bool& aBool);
	std::string getGameXMLData();												// returns xml data necessary to save the game and starts where it was
	void startGame();															// must be called before doing anything turn related
	bool getIsGameStarted();
	
	// Turns
	bool skipTurn(const int& player);
	bool playShape(const int& degrees, const int& player, const int& row, const int& col);
	bool playShapeIsValid(const int& degrees, const int& player, const int& row, const int& col);
	bool playBite(const int& bite, const int& player, const int& row, const int& col);
	bool playBiteIsValid(const int& bite, const int& playerIndex, const int& row, const int& col);
	
	// ----- Players list related functions ------
	void addPlayer(std::string aName, Color aColor);							
	void swapPlayersAtIndexes(const int i1,const int i2);
	int getNumberOfPlayers();
	MFPlayer getPlayerAtIndex(int anIndex);
	int getCurrentPlayerIndex();												// Returns the player who can currently play
	int getWinnerIndex();														// Returns -1 if there's no winner
	void removePlayerAtIndex(int anIndex);										// Allows to remove players at any time. 
																				// If a game is running it's chars will be removed from the grid.
	char getPlayerCharBody(int anIndex);
	char getPlayerCharHead(int anIndex);
	int getNumberOfCharsForPlayerIndex(int anIndex);							// Number of chars that the player has on the grid
	
	// ----- Grids: Functions for views ----- 
	MFGrid getShapeHighlightGrid(const int& degrees, const int& player, const int& row, const int& col);
	MFGrid getBiteHighlightGrid(const int& shapeIndex, const int& degrees, const int& playerIndex, const int& row, const int& col);
	MFGrid getShapeOnGrid(const int& degrees, const int& player, const int& row, const int& col);
	std::vector<pMFGrid> getLastEatSequence();
	std::vector<pMFGrid> getLastEraseSequence();
	MFGrid getCurrentGrid(); 
	MFGrid getLastMoveGrid();
	
	// ----- Shapes related functions ----- 
	int setShapesFromXMLCString(const char *xmlCString);
	void setCurrentShapeIndex(int);
	int rotateCurrentShape();
	int setRandomShapeIndex();													// Creates and sets the current shape to a random one
	int getRandomShapeIndex();													// Gets a random int within the index range of the current number of shapes
	int getCurrentShapeDegrees();
	int getCurrentShapeIndex();
	int getNumberOfShapes();
	MFGridShape getShapeAtIndex(int i);
};