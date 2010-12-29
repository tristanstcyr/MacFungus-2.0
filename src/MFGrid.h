#include <string>
#include <iostream>
#include <vector>
#include <xmlParser.h>
#include <boost/shared_ptr.hpp>

struct Position 
{ 
	int row, col; 
	Position operator + (Position aPosition) 
	{
		aPosition.row += row;
		aPosition.col += col;
		return aPosition;
	}
	Position() : row(0), col(0) {}
	Position(int aRow, int aCol) : row(aRow), col(aCol) {}
};

struct MFGridShape 
{
	bool rotates;
	std::vector<Position> cellVectors;
	MFGridShape();
	MFGridShape(std::vector<Position>, bool aBool);
	MFGridShape rotate(int degrees);
};

class MFGrid 
{
public:
	MFGrid(const unsigned int& aSize);
	MFGrid(const MFGrid& aGrid);
	MFGrid(const char *xmlCString);
	MFGrid();
	
	//Drawing
	void drawPosition(const int& row, const int& col, const char& aChar);
	void drawShape(const MFGridShape& aShape, const int& row, const int& col, const char& character);
	void drawShapeWithExceptions(const MFGridShape& aShape, const int& row, const int& col, const char& character, int num, ...);
	void drawShapeOnDefaultChars(MFGridShape aShape, const int& row, const int& col, const char& character);
	void clear();
	
	// Output
	std::string print();

	// Accessing Entries
	int size();
	const char getDefaultChar();
	char* charAtRowCol(int row, int col);
	std::vector<char*> charsAtShape(MFGridShape& aShape, const int& row, const int& col);
	bool rowColForUniqueChar(char aChar, int *row, int *col);
	bool rowColForChar(const char *aChar, int& row, int& col);
	std::vector<char*> charNeighbors(const int& row, const int& col, const char& theChar);
	std::vector<char*> identicalChars(const char& aChar);
	std::vector<char*> isolatedChars(const int& row, const int& col, const char& body);
	// Starts at a specified row col and goes in all 8 directions to find chars which are
	// between the starting point and either a head char or a body char
	std::vector<char*> sandwitchedChars(const int& row, const int& col, const char& head, const char& body);
	std::vector<Position> differentRowCols(MFGrid& anotherGrid);
	XMLNode getXMLNode();

private:
	// The char entries of the grid
	std::vector<std::vector<char> > entries;
};

typedef boost::shared_ptr<MFGrid> pMFGrid;
