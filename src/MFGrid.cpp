#include <MFGrid.h>
#include <cstdarg>

#pragma mark MFGridShape

MFGridShape::MFGridShape(std::vector<Position> aVector, bool aBool) : cellVectors(aVector), rotates(aBool) {}
MFGridShape::MFGridShape() : rotates(false) {}
MFGridShape MFGridShape::rotate(int degrees) 
{	
	int row, col;
	std::vector<Position> aShape = cellVectors;

	if (cellVectors.size() == 1 || !rotates)
		degrees = 0;
	
	switch (degrees) {
		case 90 :
			for (int i = 0; i < aShape.size();i++) 
			{
				row = -aShape.at(i).col; col = aShape.at(i).row;
				aShape.at(i).row = row;
				aShape.at(i).col = col;
			}
			break;
		case 180 :
			for (int i = 0; i < aShape.size();i++) 
			{
				row = -aShape.at(i).row; col = -aShape.at(i).col;
				aShape.at(i).row = row;
				aShape.at(i).col = col;
			}
			break;
		case 270 :
			for (int i = 0; i < aShape.size();i++) 
			{
				row = aShape.at(i).col; col = -aShape.at(i).row;
				aShape.at(i).row = row;
				aShape.at(i).col = col;
			}
			break;
		
	}
	
	return MFGridShape(aShape, rotates);
}

#pragma mark -

#pragma mark MFGrid

// Grid Class function definitions
static const char DEFAULT_CHAR = '0';
static const unsigned int DEFAULT_SIZE = 10;

MFGrid::MFGrid(const unsigned int& aSize) 
{
	std::vector<char> v(aSize, DEFAULT_CHAR);
	entries.assign(aSize, v);
}

MFGrid::MFGrid(const MFGrid& aGrid) { entries = aGrid.entries; }

MFGrid::MFGrid(const char *xmlCString)
{
	int numRows;
	XMLNode xMainNode = XMLNode::parseString(xmlCString, "grid");
	numRows = xMainNode.nChildNode("row");
	
	if (numRows == 0)
		goto bailout;
	
	for (int row = 0; row < numRows; row++) {
		XMLNode rowNode = xMainNode.getChildNode("row", row);
		int numEntries = rowNode.nChildNode("entry");
		std::vector<char> rowVector;
		
		if (numEntries == 0)
			goto bailout;
			
		for (int entry = 0; entry < numEntries; entry++) {
			const char *aChar = rowNode.getChildNode("entry", entry).getAttribute("value");
			rowVector.push_back(*aChar);
		}
		entries.push_back(rowVector);
	}
	
	return;
	
bailout:
	*this = MFGrid();
}

MFGrid::MFGrid() 
{
	std::vector<char> v(DEFAULT_SIZE, DEFAULT_CHAR);
	entries.assign(DEFAULT_SIZE, v);
}
void MFGrid::drawPosition(const int& row, const int& col, const char& aChar) { 
	*charAtRowCol(row, col) = aChar; 
}

void MFGrid::drawShapeOnDefaultChars(MFGridShape aShape, const int& row, const int& col, const char& character)
{
	for (int i = 0; i < aShape.cellVectors.size(); i++) 
	{
		Position charPosition = aShape.cellVectors.at(i);
		charPosition.row += row;
		charPosition.col += col;
		if (charPosition.row >= 0 && charPosition.row < size()
			&& charPosition.col >= 0 && charPosition.col < size()
			&& *charAtRowCol(charPosition.row,charPosition.col) == getDefaultChar())
			this->drawPosition(charPosition.row, charPosition.col, character);
	}
}

void MFGrid::drawShape(const MFGridShape& aShape, const int& row, const int& col, const char& character) 
{	
	for (int i = 0; i < aShape.cellVectors.size(); i++) 
	{
		Position charPosition = aShape.cellVectors.at(i);
		charPosition.row += row;
		charPosition.col += col;
		if (charPosition.row >= 0 && charPosition.row < size() && charPosition.col >= 0 && charPosition.col < size())
			drawPosition(charPosition.row, charPosition.col, character);
	}
}

void MFGrid::drawShapeWithExceptions(const MFGridShape& aShape, const int& row, const int& col, const char& character, int num, ...) 
{	
	
	for (int i = 0; i < aShape.cellVectors.size(); i++) 
	{
		char *aChar, *exceptChar;
		bool foundException = false;
		va_list cl;
		
		Position charPosition = aShape.cellVectors.at(i);
		charPosition.row += row;
		charPosition.col += col;
		aChar = charAtRowCol(charPosition.row, charPosition.col);
		
		va_start(cl, num);
		for (int l = 0; l < num; l++) {
			exceptChar = va_arg(cl, char*);
			if (*exceptChar == *aChar) {
				foundException = true;
				break;
			}
		}
		va_end(cl);
		
		if (aChar != NULL && !foundException)
			drawPosition(charPosition.row, charPosition.col, character);
	}
}

std::string MFGrid::print()
{
	int row, col;
	std::string outString = "";
	row = entries.size();
	for (row = 0; row < entries.size() ; row++) 
	{
		outString += "\n";
		for (col = 0; col < entries.size(); col++) 
		{
			outString += *charAtRowCol(row, col);
			outString += " ";
		}
	}
	return outString;
}

int MFGrid::size() 
{ 
	return entries.size(); 
}

const char MFGrid::getDefaultChar() 
{ 
	return DEFAULT_CHAR; 
}

char* MFGrid::charAtRowCol(int row, int col) 
{ 
	if (row < 0 || col < 0 || row >= size() || col >= size())
		return NULL;
	return &entries.at(row).at(col); 
}

std::vector<char*> MFGrid::charsAtShape(MFGridShape& aShape, const int& row, const int& col) {
	std::vector<char*> chars;
	
	for (int i = 0; i < aShape.cellVectors.size(); i++) 
	{
		Position charPosition = aShape.cellVectors.at(i);
		charPosition.row += row;
		charPosition.col += col;
		if (charPosition.row >= 0 && charPosition.row < size() && charPosition.col >= 0 && charPosition.col < size())
			chars.push_back(charAtRowCol(charPosition.row, charPosition.col));
	}
	return chars;
}

// Returns the first identical char found or NULL
bool MFGrid::rowColForUniqueChar(char aChar, int *row, int *col)
{
	for (int aRow = 0; aRow < entries.size(); aRow++) 
	{
		for (int aCol = 0; aCol < entries.at(aRow).size(); aCol++) 
		{
			char foundChar = *charAtRowCol(aRow, aCol);
			if (aChar == foundChar) 
			{
				*row = aRow; *col = aCol;
				return true;
			}
		}
	}
	return false;
}

bool MFGrid::rowColForChar(const char *aChar, int& row, int& col)
{
	for (int aRow = 0; aRow < entries.size(); aRow++) 
	{
		for (int aCol = 0; aCol < entries.at(aRow).size(); aCol++) 
		{
			char *foundChar = this->charAtRowCol(aRow, aCol);
			if (aChar == foundChar) 
			{
				row = aRow; col = aCol;
				return 1;
			}
		}
	}
	row = col = -1;
	return 0;
}

// Returns a vector of pointers to the chars
std::vector<char*> MFGrid::identicalChars(const char& aChar)
{
	std::vector<char*> charVector;
	for (int row = 0; row < this->size(); row++) 
	{
		for (int col = 0; col < this->size(); col++) 
		{
			char *charAtRowCol = this->charAtRowCol(row, col);
			if (*charAtRowCol == aChar)
				charVector.push_back(charAtRowCol);
		}
	}
	return charVector;
} 

// Returns neighboring pointers of same specified char for row and col
std::vector<char*> MFGrid::charNeighbors(const int& row, const int& col, const char& theChar) 
{	
	char *anotherChar;
	std::vector<char*> charNeighbors;
	
	// Above
	if (row - 1 >= 0 && *(anotherChar = this->charAtRowCol(row - 1, col)) == theChar)
		charNeighbors.push_back(anotherChar);
	
	// Below
	if (row + 1 < this->size() && *(anotherChar = this->charAtRowCol(row + 1, col)) == theChar)
		charNeighbors.push_back(anotherChar);
	// Left
	if (col - 1 >= 0 && *(anotherChar = this->charAtRowCol(row, col - 1)) == theChar)
		charNeighbors.push_back(anotherChar);
	
	// Right
	if (col + 1 < this->size() && *(anotherChar = this->charAtRowCol(row, col + 1)) == theChar)
		charNeighbors.push_back(anotherChar);
	
	return charNeighbors;
}

// Returns isolated identical chars from a specific row col starting position
std::vector<char*> MFGrid::isolatedChars(const int& row, const int& col, const char& body) 
{
	using std::vector;
	
	vector<char*> conChars, difV, loopChars; 
	vector<char*> allChars = this->identicalChars(body); // All body chars
	vector<char*>::iterator disc_end;
	
	//Find the head and add its neighbors
	loopChars = this->charNeighbors(row, col, body);
	conChars.assign(loopChars.begin(), loopChars.end());
	
	// Find connectedChars
	while (loopChars.size() != 0) 
	{
		
		// Return every similar neighbor for each char in loopChars
		vector<char*> newNeighbors;
		vector<char*>::iterator new_End, charItrtr;
		
		for(charItrtr = loopChars.begin(); charItrtr < loopChars.end(); charItrtr++)
		{
			int loopRow, loopCol;
			rowColForChar(*charItrtr, loopRow, loopCol);
			vector<char*> veryNewNeighbors = charNeighbors(loopRow, loopCol, body);
			newNeighbors.insert(newNeighbors.end(), veryNewNeighbors.begin(), veryNewNeighbors.end()); 
		}
		
		if (newNeighbors.size() == 0) // No neighbors? just break
			break;
		
		// Remove duplicates from newNeighbors
		sort(newNeighbors.begin(), newNeighbors.end());
		new_End = unique(newNeighbors.begin(), newNeighbors.end());
		newNeighbors.erase(new_End, newNeighbors.end());
		
		// Remove duplicates from connectedChars
		sort(conChars.begin(), conChars.end());
		new_End = unique(conChars.begin(), conChars.end());
		conChars.erase(new_End, conChars.end());
		
		// Find the difference between connectedChars and newNeighbors
		vector<char*> difference(newNeighbors.size());
		new_End = set_difference(newNeighbors.begin(), newNeighbors.end(), conChars.begin(), conChars.end(), difference.begin());
		
		// Add the contents of newNeighbors to connectedChars
		conChars.insert(conChars.begin(), difference.begin(), new_End);
		loopChars.assign(difference.begin(), new_End);
	}
	
	// Symmetric difference between connected and every = disconnected
	vector<char*> discChars(allChars.size());
	sort(conChars.begin(), conChars.end());
	sort(allChars.begin(), allChars.end());
	disc_end = set_difference(allChars.begin(), allChars.end(), conChars.begin(), conChars.end(), discChars.begin());
	discChars.erase(disc_end, discChars.end());
	return discChars;
}/*
std::vector<char*> MFGrid::isolatedChars(const int& row, const int& col, const char& body) 
{
	using std::vector;
	
	vector<char*> difV, loopChars; 
	vector<char*> conChars = this->identicalChars(body); // All body chars
	vector<char*>::iterator disc_end;
	
	//Find the head and add its neighbors
	loopChars.push_back(this->charAtRowCol(row, col));
	
	// Find connectedChars
	while (loopChars.size() != 0) 
	{
		
		// Return every similar neighbor for each char in loopChars
		vector<char*> newNeighbors;
		vector<char*>::iterator new_End, charItrtr;
		
		for(charItrtr = loopChars.begin(); charItrtr < loopChars.end(); charItrtr++)
		{
			int loopRow, loopCol;
			rowColForChar(*charItrtr, loopRow, loopCol);
			vector<char*> veryNewNeighbors = charNeighbors(loopRow, loopCol, body);
			newNeighbors.insert(newNeighbors.end(), veryNewNeighbors.begin(), veryNewNeighbors.end()); 
		}
		
		if (newNeighbors.size() == 0) // No neighbors? just break
			break;
		
		// Remove duplicates from newNeighbors
		sort(newNeighbors.begin(), newNeighbors.end());
		new_End = unique(newNeighbors.begin(), newNeighbors.end());
		newNeighbors.erase(new_End, newNeighbors.end());
		
		// Take the intersection of remaining chars and neighbors
		loopChars = vector<char*>(newNeighbors.size());
		new_End = set_intersection(conChars.begin(), conChars.end(), newNeighbors.begin(), newNeighbors.end(), loopChars.begin());
		loopChars.erase(new_End, loopChars.end());
		
		// Remove chars in loopChar from conChars
		vector<char*>difference(conChars.size());
		new_End = set_difference(conChars.begin(), conChars.end(), loopChars.begin(), loopChars.end(), difference.begin());
		difference.erase(new_End, difference.end());
		conChars = difference;
	}
	
	return conChars;
}
*/
std::vector<char*> MFGrid::sandwitchedChars(const int& row, const int& col, const char& head, const char& body) 
{	
	using std::vector;
	vector<Position> dispVect;
	vector<Position>::iterator dispItrtr;
	vector<char*>sandwitchedChars;
	Position up(-1, 0), down(1, 0), left(0, -1), right(0, 1);
	dispVect.push_back(up); dispVect.push_back(down); dispVect.push_back(left); dispVect.push_back(right);
	dispVect.push_back(up+left); dispVect.push_back(up+right); dispVect.push_back(down+left); dispVect.push_back(down+right);
	
	// Go through each displacement: up, down, left, right
	for(dispItrtr = dispVect.begin(); dispItrtr < dispVect.end(); dispItrtr++) 
	{
		int nextRow = row, nextCol = col;
		int disRow = (*dispItrtr).row, disCol = (*dispItrtr).col;
		vector<char*> foundChars;
		
		// Go in displacement until we find another identical char, defaultChar or the edge
		for (nextRow += disRow, nextCol+= disCol;
			 nextRow >= 0 && nextCol >= 0 && nextCol < this->size() && nextRow < this->size(); 
			 nextRow += disRow, nextCol+= disCol) 
		{
			char *foundChar = charAtRowCol(nextRow, nextCol);
			
			if (*foundChar == getDefaultChar()) 
				break;
			else if (*foundChar != head && *foundChar != body) 
				foundChars.push_back(foundChar); 
			else 
			{
				sandwitchedChars.insert(sandwitchedChars.end(), foundChars.begin(), foundChars.end());
				break;
			}
		}
	}
	vector<char*>::iterator anEnd;
	sort(sandwitchedChars.begin(), sandwitchedChars.end());
	anEnd = unique(sandwitchedChars.begin(), sandwitchedChars.end());
	sandwitchedChars.erase(anEnd, sandwitchedChars.end());

	for (int i = 0; i < sandwitchedChars.size(); i++) 
	{
		int aRow, aCol;
		char *aChar = sandwitchedChars.at(i);
		rowColForChar(aChar, aRow, aCol);
	}
	
	return sandwitchedChars;
}

std::vector<Position> MFGrid::differentRowCols(MFGrid& anotherGrid)
{
	std::vector<Position> differences;
	if (size() != anotherGrid.size())
		return differences;

	for (int row = 0; row < size(); row++) 
	{
		for (int col = 0; col < size(); col++) 
		{
			if (*charAtRowCol(row, col) != *anotherGrid.charAtRowCol(row, col))
			{
				Position aPos(row, col);
				differences.push_back(aPos);
			}
		}
	}
	return differences;
}

void MFGrid::clear()
{
	for (int row = 0; row < size(); row++)
		for (int col = 0; col < size(); col++)
			drawPosition(row, col, DEFAULT_CHAR);
}

XMLNode MFGrid::getXMLNode()
{
	XMLNode xGridNode = XMLNode::createXMLTopNode("grid", false);
	char bufferChar[10];
	for (int row = 0; row < size(); row++) {
		XMLNode xRowNode = xGridNode.addChild("row");
		for (int col = 0; col < size(); col++) {
			XMLNode xEntryNode = xRowNode.addChild("entry");
			sprintf(bufferChar, "%c", *charAtRowCol(row, col));
			xEntryNode.addAttribute("value", bufferChar);
		}
	}
	return xGridNode;
}