#include <fstream>
#include <xmlParser.h>
#include <MFGame.h>
#include <time.h>

static const unsigned int MIN_GRID_SIZE = 10;
static const std::string SHAPES_XML_FILE_PATH = "../../shapes.xml";

static char highlightChar = '*';
static char hotCornerChar = '&';
using std::vector;

template <typename T>
bool vectorContains(vector<T> aVector, T anObject) {
	for (int i = 0; i < aVector.size(); i++) {
		T anotherObject = aVector.at(i);
		if (anotherObject == anObject)
			return true;
	}
	return false;
}

#pragma mark -

#pragma mark MFGame
#pragma mark -Constructors

MFGame::MFGame(unsigned int gridSize, std::vector<boost::shared_ptr<MFPlayer> > thePlayers) : 
	players(thePlayers), currentShapeIndex(0), currentPlayerIndex(0), winnerIndex(-1), 
	isGameStarted(false), isUsingHotCorners(true) { setGridSize(gridSize); }

MFGame::MFGame() : currentGrid(MFGrid(MIN_GRID_SIZE)), currentShapeIndex(0), currentPlayerIndex(0), 
				   winnerIndex(-1), isGameStarted(false), isUsingHotCorners(true) {}

// Constructed from an XML saved state
MFGame::MFGame(const char *xmlCString)
{
	int numPlayers;
	XMLNode xGameNode = XMLNode::parseString(xmlCString, "game");
	char *buffer;
	XMLNode xGridNobe = xGameNode.getChildNode("grid");
	XMLNode xPlayersNode = xGameNode.getChildNode("players");
	numPlayers = xPlayersNode.nChildNode("player");
	
	if (numPlayers == 0)
		goto bailout;
	
	// set ints & bools
	isGameStarted = ( atoi(xGameNode.getAttribute("isGameStarted")) != 0 );
	currentPlayerIndex = atoi((char*)xGameNode.getAttribute("currentPlayerIndex"));
	winnerIndex = atoi((char*)xGameNode.getAttribute("winnerIndex"));
	
	// set grid
	buffer = xGridNobe.createXMLString(false);
	currentGrid = MFGrid(buffer);
	free(buffer);
	
	// set players
	for (int playerIndex = 0; playerIndex < numPlayers; playerIndex++) {
		boost::shared_ptr<MFPlayer> aPlayer(new MFPlayer());
		XMLNode xPlayerNode = xPlayersNode.getChildNode("player", playerIndex);
		aPlayer->name = xPlayerNode.getAttribute("name");
		aPlayer->color.red = atof(xPlayerNode.getAttribute("red"));
		aPlayer->color.blue = atof(xPlayerNode.getAttribute("blue"));
		aPlayer->color.green = atof(xPlayerNode.getAttribute("blue"));
		aPlayer->alive = ( atoi(xPlayerNode.getAttribute("alive")) != 0 );
		players.push_back(aPlayer);
	}
	
	return;
	
bailout:
	*this = MFGame();
}

#pragma mark - Gameplay
void MFGame::startGame()
{
	if (players.size() < 2)
		throw "MFGame::startGame(): Not enough players to start game";
	
	
	const int gridSize = currentGrid.size();
	const int biteNum = 3;
	const int borderDistance = gridSize/5;
	std::vector<boost::shared_ptr<MFPlayer> >::iterator aPlayerPtr;
	
	winnerIndex = -1;
	currentPlayerIndex = 0;
	isGameStarted = true;
	currentGrid.clear();
	
	//Set all players to alive
	for (aPlayerPtr = players.begin(); aPlayerPtr < players.end(); aPlayerPtr++) {
		(*aPlayerPtr)->alive = true;
		(*aPlayerPtr)->bites = biteNum;
		(*aPlayerPtr)->turnSkips = 0;
	}
	
	// Assign a starting point for each player
		switch (players.size()) {
			case 4 : currentGrid.drawPosition(borderDistance, gridSize-1 - borderDistance, getPlayerCharHead(3));
			case 3 : currentGrid.drawPosition(gridSize-1 - borderDistance, borderDistance, getPlayerCharHead(2));
			case 2 : currentGrid.drawPosition(gridSize-1 - borderDistance, gridSize-1 - borderDistance, getPlayerCharHead(1));
			         currentGrid.drawPosition(borderDistance, borderDistance, getPlayerCharHead(0));
		}
	
	if (isUsingHotCorners) {
		currentGrid.drawPosition(0,0, hotCornerChar); 
		currentGrid.drawPosition(0,currentGrid.size()-1, hotCornerChar);
		currentGrid.drawPosition(currentGrid.size()-1, 0, hotCornerChar);
		currentGrid.drawPosition(currentGrid.size()-1, currentGrid.size()-1, hotCornerChar);
	}
}
bool MFGame::getIsGameStarted() { return isGameStarted; }
bool MFGame::playShape(const int& degrees, const int& player, const int& row, const int& col) 
{	
	const int cornerExtraBites = 3;
	if (this->playShapeIsValid(degrees, player, row, col) == false)
		return false;
	vector<char*>newBodyChars;
	vector<char*>::iterator charItrtr;
	MFGridShape rotatedShape = shapesVector.at(currentShapeIndex).rotate(degrees);
	players.at(player)->turnSkips = 0;
	
	lastErasedSequence.clear(); 
	lastEatenSequence.clear();
	
	
	lastMoveGrid = currentGrid;
	newBodyChars = currentGrid.charsAtShape(rotatedShape, row, col);
	for (charItrtr = newBodyChars.begin(); charItrtr < newBodyChars.end(); charItrtr++) {
		if (**charItrtr == hotCornerChar)
			players.at(player)->bites += cornerExtraBites;
	}
	currentGrid.drawShape(rotatedShape, row, col, getPlayerCharBody(currentPlayerIndex));
	if(sandwichedChars(newBodyChars, player).size())
		eraseDisconnects();

	endTurn();
	return true;
}

vector<char*> MFGame::sandwichedChars(vector<char*>initialChars, const int& playerIndex) {
	vector<char*>::iterator charItrtr;
	vector<char*> finalChars;
	for (charItrtr = initialChars.begin(); charItrtr < initialChars.end(); charItrtr++) {
		int row, col;
	
		currentGrid.rowColForChar(*charItrtr, row, col);
		// Check sandwiched chars from specific char
		vector<char*> foundSandwichedChars = currentGrid.sandwitchedChars(row, col, getPlayerCharBody(playerIndex), getPlayerCharHead(playerIndex));
		for (int i = 0; i < foundSandwichedChars.size(); i++) {
			*(foundSandwichedChars.at(i)) = getPlayerCharBody(playerIndex);
			lastEatenSequence.push_back(pMFGrid( new MFGrid(currentGrid) ));
		}
		
		// If any chrs were sandwiched check sandwiches for those
		if (foundSandwichedChars.size() > 0) { // Recursive call
			vector<char*> recursiveSandwichedChars = sandwichedChars(foundSandwichedChars, playerIndex);
			finalChars.insert(finalChars.end(), recursiveSandwichedChars.begin() , recursiveSandwichedChars.end());
		}
		
		finalChars.insert(finalChars.end(), foundSandwichedChars.begin() , foundSandwichedChars.end());
	}
	
	return finalChars;
}

bool MFGame::playBite(const int& shapeIndex, const int& playerIndex, const int& row, const int& col)
{
	if (playBiteIsValid(shapeIndex, playerIndex, row, col) == false)
		return false;
	
	MFGrid newGrid = currentGrid;
	MFGridShape aShape = getShapeAtIndex(shapeIndex).rotate(getCurrentShapeDegrees());
	char currentBody = getPlayerCharBody(getCurrentPlayerIndex()),
		 currentHead = getPlayerCharHead(getCurrentPlayerIndex());
	newGrid.drawShapeWithExceptions(aShape, row, col, newGrid.getDefaultChar(), 2, &currentBody, &currentHead);
	
	lastErasedSequence.erase(lastErasedSequence.begin(), lastErasedSequence.end());
	lastMoveGrid = newGrid;
	players.at(playerIndex)->bites -= aShape.cellVectors.size();
	
	currentGrid = newGrid;
	eraseDisconnects();
	return true;
}

bool MFGame::skipTurn(const int& anIndex)										
{
	if (anIndex != currentPlayerIndex)
		return false;
		
	boost::shared_ptr<MFPlayer> skipPlayer = players.at(anIndex);
	skipPlayer->turnSkips += 1;

	if (skipPlayer->turnSkips > 2) {
		punishPlayerAtIndex(anIndex);
		skipPlayer->turnSkips = 0;
	}
	endTurn();
	return true;
}

bool MFGame::playShapeIsValid(const int& degrees, const int& player, const int& row, const int& col) 
{	
	int i;
	bool isTouching = false;
	std::vector<Position> rotatedShape(shapesVector.at(currentShapeIndex).rotate(degrees).cellVectors);
	int gridsize = currentGrid.size();
	
	// Is it the current player or is the game over?
	if (player != currentPlayerIndex || winnerIndex != -1 || getIsGameStarted() == false)
		return false;
	
	// Can the shape be placed?
	for (i = 0; i < rotatedShape.size(); i++) 
	{
		Position displacement = rotatedShape.at(i);
		int dispRow = displacement.row + row;
		int dispCol  = displacement.col + col;
		
		// Is it out of bound
		if ( dispRow > gridsize - 1 || dispRow < 0 )
			return false;
		if ( dispCol > gridsize - 1 || dispCol < 0 )
			return false;
		
		// Is the spot blank or an artifact
		char *charOnGrid = currentGrid.charAtRowCol(dispRow, dispCol);
		if (*charOnGrid != currentGrid.getDefaultChar() && *charOnGrid != '&')
			return false;
		
		// Is touching some similar char
		if (currentGrid.charNeighbors(dispRow, dispCol, getPlayerCharBody(player)).size() > 0)
			isTouching = true;
		
		if (currentGrid.charNeighbors(dispRow, dispCol, getPlayerCharHead(player)).size() > 0)
			isTouching = true;
	}
	
	return isTouching;
}

bool MFGame::playBiteIsValid(const int& shapeIndex, const int& playerIndex, const int& row, const int& col)
{
	using std::vector;
	bool foundBiteable = false;
	MFGridShape shape = getShapeAtIndex(shapeIndex);
	vector<char*> bittenChars = currentGrid.charsAtShape(shape, row, col);
	vector<char*>::iterator charItrtr;
	vector<char*> neighbors;
	
	for (charItrtr = bittenChars.begin(); charItrtr < bittenChars.end(); charItrtr++) {
		vector<char*> headNeighbors, bodyNeighbors;
		int aRow, aCol;
		currentGrid.rowColForChar(*charItrtr, aRow, aCol);
		headNeighbors = currentGrid.charNeighbors(aRow, aCol, getPlayerCharHead(playerIndex));
		bodyNeighbors = currentGrid.charNeighbors(aRow, aCol, getPlayerCharBody(playerIndex));
		neighbors.insert(neighbors.end(), headNeighbors.begin(), headNeighbors.end());
		neighbors.insert(neighbors.end(), bodyNeighbors.begin(), bodyNeighbors.end());
		if (**charItrtr != currentGrid.getDefaultChar() && 
		**charItrtr != getPlayerCharHead(getCurrentPlayerIndex()) &&
		**charItrtr !=  getPlayerCharBody(getCurrentPlayerIndex()))
			foundBiteable = true;
	}
	
	//Check if the game's conditions are right
	if (playerIndex != currentPlayerIndex || 
		getIsGameStarted() == false || 
		players.at(playerIndex)->bites < shape.cellVectors.size() ||
		neighbors.size() == 0 ||
		!foundBiteable)
		return false;
	
	//Check bounds
	if (row > currentGrid.size() - 1 || col > currentGrid.size() - 1 || row < 0 || row < 0) 
		return false;

	return true;
}

// Called when the player skips a certain number of turns consecutively from the skipTurn function
void MFGame::punishPlayerAtIndex(const int& anIndex)							// Choose a percentage or a player's square's at 
{																				// random and delete'em
	const int PUNISH_PERC = 10;
	int charNum, eraseCharNum;
	std::vector<char*> playerChars = currentGrid.identicalChars(getPlayerCharBody(anIndex)),
				       charErases;
	char *aChar;
	charNum = playerChars.size();
	lastEatenSequence.clear();
	if (charNum == 0)															// Don't punish someone with only a head
		return;
	
	eraseCharNum = charNum/PUNISH_PERC;
	srand((unsigned)time(0));
	for (int i = 0; i < eraseCharNum; i++) {									// get eraseCharNum number of unique random chars
		int row, col;
		do {
			int randomInt = rand();
			int randomIndex = randomInt % charNum;								// get a randomIndex from 0 to eraseCharNum
			aChar = playerChars.at(randomIndex);								// get the char
		} while (vectorContains(charErases, aChar));							// continue until it's a new one
		charErases.push_back(aChar);
		currentGrid.rowColForChar(aChar, row, col);
		currentGrid.drawPosition(row, col, currentGrid.getDefaultChar());		// erase the char
		lastEatenSequence.push_back(pMFGrid( new MFGrid(currentGrid)));
	}
	eraseDisconnects();
}
void MFGame::endTurn() 
{
	if (getIsGameStarted() == false)
		return;
		
	int nextPlayerIndex = currentPlayerIndex;
	std::vector<boost::shared_ptr<MFPlayer> > deadPlayers, alivePlayers;
	
	// Check dead players and set blocks
	for (int i = 0; i < players.size(); i++) 
	{
		int row, col;
		if (currentGrid.rowColForUniqueChar(getPlayerCharHead(i), &row, &col) == false) 
		{
			players.at(i)->alive = false;
			deadPlayers.push_back(players.at(i));
		} else  {
			players.at(i)->blocks = currentGrid.identicalChars(getPlayerCharBody(i)).size() + 1;
			alivePlayers.push_back(players.at(i));
		}
	}
	
	// Game over if one player is left
	if (deadPlayers.size() == players.size() - 1) {
		winnerIndex = playerIndex(alivePlayers.at(0));
		isGameStarted = false;
		return;
	}

	// Switch to the next player that is not dead
	while (nextPlayerIndex == currentPlayerIndex || players.at(nextPlayerIndex)->alive == false) {
		if (++nextPlayerIndex > players.size()-1)
			nextPlayerIndex = 0;
	}
	
	currentPlayerIndex = nextPlayerIndex;
}

#pragma mark - Grid
void MFGame::setGridSize(const int& anInt) {
	if (isGameStarted) isGameStarted = false;
	currentGrid = (anInt < MIN_GRID_SIZE ? MFGrid(MIN_GRID_SIZE) : MFGrid(anInt)); 
}
MFGrid MFGame::getCurrentGrid() { return currentGrid; }
MFGrid MFGame::getLastMoveGrid() { return lastMoveGrid; }

MFGrid MFGame::getShapeOnGrid(const int& degrees, const int& player, const int& row, const int& col) {
	MFGrid aGrid = currentGrid;
	MFGridShape rotatedShape = shapesVector.at(currentShapeIndex).rotate(degrees);
	aGrid.drawShape(rotatedShape, row, col, getPlayerCharBody(player));
	return aGrid;
}

MFGrid MFGame::getShapeHighlightGrid(const int& degrees, const int& player, const int& row, const int& col) 
{
	MFGrid highlightGrid = MFGrid(getCurrentGrid().size());
	MFGrid currentGridCopy =MFGrid(getCurrentGrid().size());
	std::vector<char*> highlightChars;
	std::vector<char*>::iterator charItrtr;
	MFGridShape aShape = shapesVector.at(currentShapeIndex);
	currentGridCopy.drawShapeOnDefaultChars(aShape.rotate(degrees), row, col, highlightChar);
	highlightChars = currentGridCopy.identicalChars(highlightChar);
	
	for (charItrtr = highlightChars.begin(); charItrtr < highlightChars.end(); charItrtr++) 
	{
		int aRow, aCol;
		currentGridCopy.rowColForChar(*charItrtr, aRow, aCol);
		highlightGrid.drawPosition(aRow, aCol, highlightChar);
	}
	
	return highlightGrid;
}

MFGrid MFGame::getBiteHighlightGrid(const int& shapeIndex, const int& degrees, const int& playerIndex, const int& row, const int& col)
{
	MFGrid intersectingGrid = MFGrid(currentGrid.size());
	MFGridShape aShape = shapesVector.at(shapeIndex).rotate(degrees);
	std::vector<Position>::iterator posItrtr;
	for (posItrtr = aShape.cellVectors.begin() ; posItrtr < aShape.cellVectors.end(); posItrtr++)
	{
		Position charPosition = *posItrtr;
		charPosition.row += row;
		charPosition.col += col;
		if (charPosition.row >= 0 && charPosition.col >= 0 && charPosition.row < currentGrid.size() && charPosition.col < currentGrid.size()) {
			char foundChar = *currentGrid.charAtRowCol(charPosition.row, charPosition.col);
			if (foundChar != getPlayerCharBody(playerIndex) && foundChar != getPlayerCharHead(playerIndex) && foundChar != currentGrid.getDefaultChar())
				intersectingGrid.drawPosition(charPosition.row, charPosition.col, highlightChar);
		}
	}
	
	return intersectingGrid;
}

std::vector<pMFGrid> MFGame::getLastEatSequence() { return lastEatenSequence; }
std::vector<pMFGrid> MFGame::getLastEraseSequence() { return lastErasedSequence; }
void MFGame::eraseDisconnects() {

	lastErasedSequence.clear();

	for (int i = 0; i < players.size(); i++) 
	{
		int headRow, headCol;
		vector<char*>isolatedChars, sandwitchedChars;
		vector<char*>::iterator itrtr;
		
		// If the head is still on the grid we check for isolated if not we take all
		if (currentGrid.rowColForUniqueChar(getPlayerCharHead(i), &headRow, &headCol)) 
			isolatedChars = currentGrid.isolatedChars(headRow, headCol, getPlayerCharBody(i));
		else
			isolatedChars = currentGrid.identicalChars(getPlayerCharBody(i));
		
		for (itrtr = isolatedChars.begin(); itrtr < isolatedChars.end(); itrtr++)
		{
			**itrtr = currentGrid.getDefaultChar();
			// Assemble the animation for eaten chars
			lastErasedSequence.push_back(pMFGrid( new MFGrid(currentGrid) ));
		}
	}
}

#pragma mark - Players
int MFGame::getWinnerIndex() { return winnerIndex; }
int MFGame::getNumberOfPlayers() { return players.size(); }
int MFGame::getCurrentPlayerIndex() { return currentPlayerIndex; }
MFPlayer MFGame::getPlayerAtIndex(int anIndex) { 
	if (anIndex >= players.size()) {
		std::cout << "\nMFGame::getPlayerAtIndex : ";
		std::cout << anIndex;
		std::cout << " beyond range\n";
	}
	return *players.at(anIndex); 
}

void MFGame::removePlayerAtIndex(int deleteIndex)
{
	if (deleteIndex < 0 || deleteIndex > players.size())
		return;
	
	boost::shared_ptr<MFPlayer> erasedPlayer = players.at(deleteIndex);
	std::vector<boost::shared_ptr<MFPlayer> >::iterator itrtr;
	for (itrtr = players.begin(); itrtr < players.end(); itrtr++) {
		if (*itrtr ==  erasedPlayer)
			players.erase(itrtr);
	}
	
	if (currentPlayerIndex > deleteIndex)
		--currentPlayerIndex;
	else if (currentPlayerIndex == deleteIndex) {
		--currentPlayerIndex;
		endTurn();
	}
}

void MFGame::swapPlayersAtIndexes(const int i1,const int i2) {
	std::vector<boost::shared_ptr<MFPlayer> > newPlayersVector;
	for (int i = 0; i < players.size(); i++) {
			if (i == i1)
				newPlayersVector.push_back(players.at(i2));
			else if (i == i2)
				newPlayersVector.push_back(players.at(i1));
			else 
				newPlayersVector.push_back(players.at(i));
	}
	
	players = newPlayersVector;
}

void MFGame::addPlayer(std::string aName, Color aColor)
{
	bool isAlive = (getIsGameStarted() == false);
	boost::shared_ptr<MFPlayer> aPlayer(new MFPlayer(aColor, aName, DEFAULT_BITES, isAlive));
	players.push_back(aPlayer);
}

int MFGame::playerIndex(boost::shared_ptr<MFPlayer> aPlayer) 
{
	for (int i = 0; i < players.size(); i++) {
		if (players.at(i) == aPlayer)
			return i;
	}
	return -1;
}

// Returns the number of chars on the grid of the player at index
int MFGame::getNumberOfCharsForPlayerIndex(int anIndex) 
{
	int numChars = 0;
	if (anIndex >= getNumberOfPlayers() || getPlayerAtIndex(anIndex).alive == false)
		return numChars;
	numChars = currentGrid.identicalChars(getPlayerCharBody(anIndex)).size();
	return numChars+1;
}

char MFGame::getPlayerCharBody(int anIndex) {
	if (anIndex >= players.size() || anIndex < 0)
		return currentGrid.getDefaultChar();
	else
		return 'a' + anIndex;
}

char MFGame::getPlayerCharHead(int anIndex) {
	if (anIndex >= players.size() || anIndex < 0)
		return currentGrid.getDefaultChar();
	else
		return 'A' + anIndex;
}

#pragma mark - Shapes

int MFGame::getRandomShapeIndex() { srand(time(NULL)); return (rand() % shapesVector.size()) + 1; }

int MFGame::getCurrentShapeIndex() { return currentShapeIndex; }

void MFGame::setCurrentShapeIndex(int anIndex)
{
	if (anIndex >= 0 && anIndex < shapesVector.size())
		currentShapeIndex = anIndex;
	shapeDegrees = 0;
}

int MFGame::rotateCurrentShape() {
	switch (shapeDegrees) {
		case 0: shapeDegrees = 90; break;
		case 90: shapeDegrees = 180; break;
		case 180: shapeDegrees = 270; break;
		default : shapeDegrees = 0; break;
	}
	return shapeDegrees;
}

int MFGame::setShapesFromXMLCString(const char *xmlCString) 
{	
	int i, numShapes;
	std::vector<MFGridShape> newShapesVector;
	
	// this open and parse the XML file and looks for the tag "Shapes":
	XMLNode xMainNode = XMLNode::parseString(xmlCString, "Shapes");
	numShapes = xMainNode.nChildNode("Shape");
	
	if (numShapes == 0)
		return -1;
	std::cout << numShapes;
	// Get each shape
	for (i = 0; i < numShapes; i++)
	{
		int j, numCells;
		bool rotates;
		std::vector<Position> shape;
		
		XMLNode shapeNode = xMainNode.getChildNode("Shape",i);
		numCells = shapeNode.nChildNode("Cell");
		rotates = (bool)atoi(shapeNode.getAttribute("rotates"));
		
		// Get the x y coordinates
		for (j = 0; j < numCells; j++) {
			XMLNode cellNode = shapeNode.getChildNode("Cell", j);
			Position coordinates;
			coordinates.row = atoi(cellNode.getAttribute("row"));
			coordinates.col = atoi(cellNode.getAttribute("col"));
			shape.push_back(coordinates);
		}
		
		newShapesVector.push_back(MFGridShape(shape, rotates));
	}
	
	shapesVector = newShapesVector;
	
	return 0;
	
bailout:
		std::cout << "Error loading shapes";
	return -1;
}

int MFGame::setRandomShapeIndex() {
	
	srand(time(NULL));
	int randomInt = rand();
	int numberOfShapes = getNumberOfShapes();
	int randomIndex = randomInt % (numberOfShapes + 1);
	setCurrentShapeIndex(randomIndex);
	return randomIndex;
}

int MFGame::getCurrentShapeDegrees() { return shapeDegrees; }
MFGridShape MFGame::getShapeAtIndex(int i) { return shapesVector.at(i); }
int MFGame::getNumberOfShapes() { return shapesVector.size(); }

#pragma mark - Misc
void MFGame::setIsUsingHotCorners(const bool& aBool) { isUsingHotCorners = aBool; }

// Loads an XML file at specifies path and returns the string
boost::shared_ptr<std::string> MFGame::loadXMLfile(std::string path)
{	
	std::ifstream myFile(path.c_str());
	std::string xmlString;
	
	while (! myFile.eof() )
	{
		std::string line;
		getline(myFile, line);
		xmlString.append(line+"\n");
	}
	myFile.close();
	
	return boost::shared_ptr<std::string>(new std::string(xmlString));
}
std::string MFGame::getGameXMLData()
{
	/* 
		The state of the game can be saved and transported over the network using this method.
		It packs the following ivars: isGameStarted, currentPlayerIndex, winnerIndex, currentGrid and players.
		From this XML data another quasi identical MFGame instance can be isntantiate with the proper constructor
	*/
	const int MAX_CHAR_LENGTH = 20;
	char bufferChar[MAX_CHAR_LENGTH], *XMLCString;
	std::string XMLString;
	
	XMLNode xMainNode = XMLNode::createXMLTopNode("xml", TRUE), xGameNode, xGridNode, xPlayersNode;
	std::vector<boost::shared_ptr<MFPlayer> >::iterator playerPtr;
	xGameNode = xMainNode.addChild("game");
	xGameNode.addAttribute("isGameStarted", ( getIsGameStarted() ? "0" : "1" ));
	
	sprintf(bufferChar, "%i", getCurrentPlayerIndex());
	xGameNode.addAttribute("currentPlayerIndex", bufferChar);
	sprintf(bufferChar, "%i", getWinnerIndex());
	xGameNode.addAttribute("winnerIndex", bufferChar);
	
	// pack the grid
	xGameNode.addChild(currentGrid.getXMLNode());
	
	// pack the players
	xPlayersNode = xGameNode.addChild("players");
	for (playerPtr = players.begin(); playerPtr <  players.end();  playerPtr++) 
	{
		XMLNode xPlayerNode = xPlayersNode.addChild("player");
		Color playerColor = (*playerPtr)->color;
		
		xPlayerNode.addAttribute("name", (*playerPtr)->name.c_str());
		sprintf(bufferChar, "%f", playerColor.red);
		xPlayerNode.addAttribute("red", bufferChar);
		sprintf(bufferChar, "%f", playerColor.green);
		xPlayerNode.addAttribute("green", bufferChar);
		sprintf(bufferChar, "%f", playerColor.blue);
		xPlayerNode.addAttribute("blue", bufferChar);
		sprintf(bufferChar, "%i", (*playerPtr)->bites);
		xPlayerNode.addAttribute("bites", bufferChar);
		sprintf(bufferChar, "%i", (*playerPtr)->alive);
		xPlayerNode.addAttribute("alive", bufferChar);
	}
	
	XMLCString = xMainNode.createXMLString(false);
	XMLString = XMLCString;
	free(XMLCString);
	
	return XMLString;
}
