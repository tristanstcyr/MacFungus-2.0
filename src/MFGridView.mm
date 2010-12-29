#import "MFGridView.h"
#import "CTGradient.h"

@implementation MFGridView

#pragma mark -

#pragma mark Laundry

- (id)initWithFrame:(NSRect)frameRect mode:(int)aMode prototype:(NSCell *)aCell numberOfRows:(int)numRows numberOfColumns:(int)numColumns {
	self = [super initWithFrame:frameRect mode:aMode prototype:aCell numberOfRows:numRows numberOfColumns:numColumns];
	if (self != nil) {
		isAnimating = NO;
		cellsNeedingRedraw = [NSMutableArray new];
		NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
		bool isInside = [self mouse:mouseLocation inRect:[self frame]];
		[self addTrackingRect:[self bounds]
						owner:self
					 userData:nil
				 assumeInside:isInside];
		if (isInside) [self mouseEntered:nil];
		[[self window] setAcceptsMouseMovedEvents:YES];
		colorDict = [[NSMutableDictionary alloc] init];
		imageDict = [[NSMutableDictionary alloc] init];
		isAcceptingInput = YES;
		
		backgroundImage = [self backgroundImageInSize:[self frame].size];
		[backgroundImage retain];
	}
	return self;
}

- (id)initSquareGridWithFrame:(NSRect)frameRect numberOfRowsAndCols:(int)rowsAndCols {
	NSCell *prototypeCell = [MFGridViewCell new];
	[self initWithFrame:frameRect mode:NSListModeMatrix prototype:prototypeCell numberOfRows:rowsAndCols numberOfColumns:rowsAndCols];
	[self setIntercellSpacing:NSMakeSize(0.0f, 0.0f)];
	[self setAllowsEmptySelection:YES];
	[self setCellSize:NSMakeSize(frameRect.size.width/rowsAndCols, frameRect.size.height/rowsAndCols)];
	[self sizeToCells];
	return self;
}

- (void)dealloc 
{
	[cellsNeedingRedraw release];
	[colorDict release];
	[imageDict release];
	[super dealloc];
}

- (void)viewDidMoveToWindow {

		[[self window] setAcceptsMouseMovedEvents:YES];
		[[self window] makeFirstResponder:self];
		trackingRectTag = [self addTrackingRect:[self bounds]
										  owner:self
									   userData:nil
								   assumeInside:NO];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
	if (trackingRectTag)
        [self removeTrackingRect:trackingRectTag];
}


#pragma mark -

#pragma mark Drawing

- (NSImage*)backgroundImageInSize:(NSSize)aSize {
	
	NSImage *image = [[NSImage alloc] initWithSize:aSize];
	NSRect imageRect;
	NSPoint aPoint;
	float cellSize = aSize.width/[self numberOfRows];
	imageRect.size = aSize;
	imageRect.origin = NSMakePoint(0,0);
	
	[image lockFocus];
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:imageRect];
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	
	[[NSColor colorWithCalibratedWhite:0.2f alpha:0.1f] set];
	for (int row = 1; row < [self numberOfRows]; row++) {
		NSBezierPath *bezierPath = [NSBezierPath bezierPath];
		aPoint = NSMakePoint(0, cellSize*row);
		[bezierPath moveToPoint:aPoint];
		aPoint = NSMakePoint(aSize.width, cellSize*row);
		[bezierPath lineToPoint:aPoint];
		[bezierPath stroke];
	}
	
	for (int col = 1; col < [self numberOfRows]; col++) {
		NSBezierPath *bezierPath = [NSBezierPath bezierPath];
		aPoint = NSMakePoint(cellSize*col, 0);
		[bezierPath moveToPoint:aPoint];
		aPoint = NSMakePoint(cellSize*col, aSize.width);
		[bezierPath lineToPoint:aPoint];
		[bezierPath stroke];
	}
	
	[image unlockFocus];
	
	return [image autorelease];
}

// Draws the cells in the cellsNeedingRedraw array and empties the array
- (void)drawCellsNeedingRedraw {
	
	NSEnumerator *anEnumerator;
	NSCell *aCell;
	NSInteger row, col;
	anEnumerator = [cellsNeedingRedraw objectEnumerator];
	while (aCell = [anEnumerator nextObject]) {
		[self drawCell:aCell];
		[self getRow:&row column:&col ofCell:aCell];
	}
	[cellsNeedingRedraw removeAllObjects];
}

- (void)drawRect:(NSRect)aRect 
{
	[backgroundImage drawInRect:aRect 
					   fromRect:aRect
					  operation:NSCompositeSourceOver 
					   fraction:1.0f];
	[super drawRect:aRect];
}

- (void)display
{
	for (int row = 0; row < [self numberOfRows]; row++) {
		for (int column = 0; column < [self numberOfColumns]; column++) {
			[self updateCellAtRow:row column:column];
		}
	}
	[self drawCellsNeedingRedraw];
}

#pragma mark -

#pragma mark Input

- (void)mouseMoved:(NSEvent*)anEvent
{
	if (isAnimating || !isAcceptingInput)
		return;
		
	if ([[self delegate] respondsToSelector:@selector(gridView:mouseMovedOverRow:column:withEvent:)]) {
		NSInteger row, col;
		NSPoint point = [anEvent locationInWindow]; 
		NSPoint pointInView = [self convertPoint:point fromView:nil];
		[self getRow:&row column:&col forPoint:pointInView];
		[[self delegate] gridView:self mouseMovedOverRow:row column:col withEvent:anEvent];
	}
}

- (void)mouseDown:(NSEvent*)anEvent
{
	if (isAnimating || !isAcceptingInput)
		return;
	
	NSInteger row, col;
	NSPoint point = [anEvent locationInWindow]; 
	NSPoint pointInView = [self convertPoint:point fromView:nil];
	[self getRow:&row column:&col forPoint:pointInView];
	[[self window] makeFirstResponder:self];
	if ([[self delegate] respondsToSelector:@selector(gridView:mouseDownOnRow:column:withEvent:)])
		[[self delegate] gridView:self mouseDownOnRow:row column:col withEvent:anEvent];
}

- (void)rightMouseDown:(NSEvent*)anEvent {
	
	if (isAnimating || !isAcceptingInput)
		return;
	[self mouseDown:anEvent];
}

- (void)mouseExited:(NSEvent*)anEvent {
	[self setHighlightGridAndDisplay:MFGrid([self numberOfRows])];
	[[self window] setAcceptsMouseMovedEvents:NO];
	[[self delegate] gridView:self mouseMovedOverRow:-1 column:-1 withEvent:anEvent];
}

- (void)mouseEntered:(NSEvent*)anEvent 
{ 
	[[self window] makeFirstResponder:self];
	[[self window] setAcceptsMouseMovedEvents:YES];
}

- (void)scrollWheel:(NSEvent *)anEvent {
	if ([[self delegate] respondsToSelector:@selector(gridView:scrollWheel:)])
		[[self delegate] gridView:self scrollWheel:anEvent];
}

- (void)setAcceptsInput:(BOOL)aBool { isAcceptingInput = aBool; }
- (BOOL)acceptsInput { return isAcceptingInput; }

- (BOOL)becomeFirstResponder { return YES; }
- (BOOL)acceptsFirstResponder { return YES; }

#pragma mark -

#pragma mark Cells and Grids

- (void)updateCellAtRow:(const int)row column:(const int)col
{
	if (row < 0 || col < 0)
		return;
	int nRow, nCol;
	char aChar;	
	bool isTouchingUp, isTouchingDown, isTouchingLeft, isTouchingRight;
	NSMutableArray *changedCells;
	NSColor *neutralColor = [self colorForChar:'0'];
	MFGridViewCell *aCell, *neighborCell;
	NSEnumerator *anEnumerator;
	
	isTouchingUp = isTouchingDown = isTouchingLeft = isTouchingRight = NO;
	aCell = [self cellAtRow:row column:col];
	changedCells = [NSMutableArray arrayWithObject:aCell];
	
	// Set the color
	aChar = *currentGrid->charAtRowCol(row, col);
	[aCell setColor:[self colorForChar:aChar]];
	[aCell setImage:[self imageForChar:aChar]];
	
	// Set the highlight color
	if (highlightGrid)
		[aCell setHighlightColor:(*highlightGrid->charAtRowCol(row, col) != '0' ? [self colorForChar:*highlightGrid->charAtRowCol(row, col)] : nil)];
	
	// Contacts
	// up
	if (row > 0) {
		nRow = row-1; nCol = col;
		neighborCell = [self cellAtRow:nRow column:nCol];
		isTouchingUp = ([neighborCell color] == [aCell color]);
		[aCell setIsTouchingUp:isTouchingUp];
		if ([neighborCell isTouchingDown] != isTouchingUp) { // Added to avoid unecessary redraws
			[neighborCell setIsTouchingDown:isTouchingUp];
			[changedCells addObject:neighborCell];
		}
	}
	
	// down
	if (row < [self numberOfColumns]-1) {
		neighborCell = [self cellAtRow:row+1 column:col];
		isTouchingDown = ([neighborCell color] == [aCell color]);
		[aCell setIsTouchingDown:isTouchingDown];
		if ([neighborCell isTouchingUp] != isTouchingDown) {
			[neighborCell setIsTouchingUp:isTouchingDown];
			[changedCells addObject:neighborCell];
		}
	}
	// left
	if (col > 0) {
		neighborCell = [self cellAtRow:row column:col-1];
		isTouchingLeft = ([neighborCell color] == [aCell color]);
		[aCell setIsTouchingLeft:isTouchingLeft];
		if ([neighborCell isTouchingRight] != isTouchingLeft) {
			[neighborCell setIsTouchingRight:isTouchingLeft];
			[changedCells addObject:neighborCell];
		}
	}
	// right
	if (col < [self numberOfColumns]-1) {
		neighborCell = [self cellAtRow:row column:col+1];
		isTouchingRight = ([neighborCell color] == [aCell color]);
		[aCell setIsTouchingRight:isTouchingRight];
		if ([neighborCell isTouchingLeft] != isTouchingRight) {
			[neighborCell setIsTouchingLeft:isTouchingRight];
			[changedCells addObject:neighborCell];
		}
	}
	
	// Diagonal corners
	anEnumerator = [changedCells objectEnumerator];
	while (aCell = [anEnumerator nextObject]) 
	{
		NSInteger aRow, aCol;
		NSColor *aColor = [aCell color];
		NSColor *cornerColor;
		[self getRow:&aRow column:&aCol ofCell:aCell];
		isTouchingUp = [aCell isTouchingUp];
		isTouchingDown = [aCell isTouchingDown];
		isTouchingLeft = [aCell isTouchingLeft];
		isTouchingRight = [aCell isTouchingRight];
		
		[self addCellNeedingRedraw:aCell];
		
		// Special cases for edges
		if (aRow == 0) {
			[aCell setTopLeftCornerColor:neutralColor];
			[aCell setTopRightCornerColor:neutralColor];
		} else if (aRow == [self numberOfRows]-1) {
			[aCell setBottomLeftCornerColor:neutralColor];
			[aCell setBottomRightCornerColor:neutralColor];
		}
		if (aCol == 0) {
			[aCell setTopLeftCornerColor:neutralColor];
			[aCell setBottomLeftCornerColor:neutralColor];
		} else if (aCol == [self numberOfColumns]-1) {
			[aCell setTopRightCornerColor:neutralColor];
			[aCell setBottomRightCornerColor:neutralColor];
		}
		
		// up left
		if (aRow > 0 && aCol > 0) {
			neighborCell = [self cellAtRow:aRow-1 column:aCol-1];
			cornerColor = (isTouchingUp && isTouchingLeft ? aColor : neutralColor);
			if (cornerColor != [neighborCell bottomRightCornerColor]) {
				[neighborCell setBottomRightCornerColor:cornerColor];
				[self addCellNeedingRedraw:neighborCell];
			}
		}
		
		// up right
		if (aRow > 0 && aCol < [self numberOfColumns]-1) {
			neighborCell = [self cellAtRow:aRow-1 column:aCol+1];
			cornerColor = (isTouchingUp && isTouchingRight ? aColor : neutralColor);
			if (cornerColor != [neighborCell bottomLeftCornerColor]) {
				[neighborCell setBottomLeftCornerColor:cornerColor];
				[self addCellNeedingRedraw:neighborCell];
			}
		}
		// down left
		if (aRow < [self numberOfRows]-1 && aCol > 0) {
			neighborCell = [self cellAtRow:aRow+1 column:aCol-1];
			cornerColor = (isTouchingDown && isTouchingLeft ? aColor : neutralColor);
			if (cornerColor != [neighborCell topRightCornerColor]) {
				[neighborCell setTopRightCornerColor:cornerColor];
				[self addCellNeedingRedraw:neighborCell];
			}
		}
		// down right
		if (aRow < [self numberOfRows]-1 && aCol < [self numberOfColumns]-1) {
			neighborCell = [self cellAtRow:aRow+1 column:aCol+1];
			cornerColor = (isTouchingDown && isTouchingRight ? aColor : neutralColor);
			if (cornerColor != [neighborCell topLeftCornerColor]) {	
				[neighborCell setTopLeftCornerColor:cornerColor];
				[self addCellNeedingRedraw:neighborCell];
			}
		}
	}
}

- (NSColor*)colorForChar:(char)aChar { return [colorDict objectForKey:[NSString stringWithChar:aChar]]; }
- (void)setColor:(NSColor*)aColor forChar:(char)aChar { 
	if (!aColor) [colorDict removeObjectForKey:[NSString stringWithChar:aChar]];
	else [colorDict setObject:aColor forKey:[NSString stringWithChar:aChar]]; 
}

- (NSImage*)imageForChar:(char)aChar { return [imageDict objectForKey:[NSString stringWithChar:aChar]]; }
- (void)setImage:(NSImage*)anImage forChar:(char)aChar {
	if (!anImage) [imageDict removeObjectForKey:[NSString stringWithChar:aChar]];
	else [imageDict setObject:anImage forKey:[NSString stringWithChar:aChar]]; 
}
- (void)setGrid:(MFGrid)aGrid { currentGrid.reset(new MFGrid(aGrid)); }

- (MFGrid)grid { return *currentGrid; }

- (void)setGridAndDisplay:(MFGrid)aGrid
{
	if (currentGrid) {
		std::vector<Position> rowColDifferences = currentGrid->differentRowCols(aGrid);
		std::vector<Position>::iterator itrtr;
		[self setGrid:aGrid];
		for(itrtr = rowColDifferences.begin(); itrtr < rowColDifferences.end(); itrtr++)
			[self updateCellAtRow:itrtr->row column:itrtr->col];
		[self drawCellsNeedingRedraw];
	} else {
		[self setGrid:aGrid];
		[self display];
	}
}

- (void)setHightlightGrid:(MFGrid)aGrid { highlightGrid.reset(new MFGrid(aGrid)); }

- (void)setHighlightGridAndDisplay:(MFGrid)aGrid
{
	std::vector<Position> rowColDifferences;
	
	if (highlightGrid) rowColDifferences = highlightGrid->differentRowCols(aGrid);
	
	[self setHightlightGrid:aGrid];
	
	for(int i = 0; i < rowColDifferences.size(); i++)
		[self updateCellAtRow:rowColDifferences.at(i).row column:rowColDifferences.at(i).col];
	
	[self drawCellsNeedingRedraw];
}

- (void)addCellNeedingRedraw:(NSCell*)aCell { 
	if (aCell && ![cellsNeedingRedraw containsObject:aCell])
		[cellsNeedingRedraw addObject:aCell]; 
}

#pragma mark -

#pragma mark Animation
- (void)animateWithSequences:(std::vector<std::vector<pMFGrid> >)sequences sounds:(NSArray*)aSoundArray delay:(float)timeLapse
{
	animationSequences = sequences;
	sounds = [aSoundArray retain];
	animInterval = timeLapse;
	[NSThread detachNewThreadSelector:@selector(threadAnimate) toTarget:self withObject:nil];
}

- (void)threadAnimate
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	NSTimer *aTimer;
	
	for (int i = 0; i < animationSequences.size(); i++) {
		NSMutableDictionary *animDict = 
			[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:i], @"sequence",
															  [NSNumber numberWithInt:0], @"step", nil];

		aTimer = [NSTimer timerWithTimeInterval:animInterval target:self selector:@selector(animationStep:) userInfo:animDict repeats:YES];
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:animInterval]];
		isAnimating = YES;
		[runLoop addTimer:aTimer forMode:NSDefaultRunLoopMode];
		[runLoop run];
	}
	isAnimating = NO;
	[pool release];
	if ([[self delegate] respondsToSelector:@selector(gridViewAnimationDidEnd:)]) {
		[[self delegate] performSelectorOnMainThread:@selector(gridViewAnimationDidEnd:) withObject:self waitUntilDone:NO];
	}
	
}

- (void)animationStep:(NSTimer*)aTimer {
	NSMutableDictionary *aDict = [aTimer userInfo];
	int sequence = [[aDict objectForKey:@"sequence"] intValue];
	int step = [[aDict objectForKey:@"step"] intValue];
	NSSound *sound = [sounds objectAtIndex:sequence];
	[sound stop];
	[sound play];
	[self setGridAndDisplay:*animationSequences.at(sequence).at(step)];
	++step;
	if (step >= animationSequences.at(sequence).size())
		[aTimer invalidate];
	else
		[aDict setObject:[NSNumber numberWithInt:step] forKey:@"step"];
}

- (BOOL)isAnimating { return isAnimating; }
@end
#pragma mark -

@implementation MFGridViewCell

- (id)initWithCoder:(NSCoder *)decoder
{	
	if (self = [super initWithCoder:decoder]) {
		color = NULL;
		highlightColor = NULL;
		topLeftCornerColor = NULL;
		topRightCornerColor =  NULL;
		bottomLeftCornerColor = NULL; 
		bottomRightCornerColor = NULL;
		isTouchingUp = isTouchingDown = isTouchingLeft = isTouchingRight = NO;
		return self;
	} else return NULL;
}

- (void)setColor:(NSColor *)aColor
{
	[color release];
	color = [aColor retain];
}

- (NSImage*)image { return image; }

- (void)setImage:(NSImage*)anImage
{
	if (image) [image release];
	image = anImage;
	if (image) [image retain];
}

- (NSColor*)color { return color; }

- (void)setHighlightColor:(NSColor *)aColor
{
	if (highlightColor != nil)
		[highlightColor release];
	
	highlightColor = aColor;
	
	if (highlightColor != nil)
		[highlightColor retain];
}

/*                                                              
        p3    p4                                                                                    
  p2 +---+----+---+  p5                                                                             
     |   |    |   |                                                                                 
  p1 +---+----+---+  p6                                                                             
     |   |    |   |                                                                                 
 p12 +---+----+---+  p7                                                                             
     |   |    |   |                                                                                 
 p11 +---+----+---+ p8                                                                              
       p10    p9                                                                                                  
*/
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	
	const float cornerRadius = cellFrame.size.width/2;
	NSColor *drawColor = [self color];
	NSImage *anImage;
	NSPoint p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12;
	NSBezierPath *mainShape = [NSBezierPath bezierPath],
				 *topLeftOutCorner = nil,
				 *topRightOutCorner = nil,
				 *bottomLeftOutCorner = nil,
				 *bottomRightOutCorner = nil;
	[mainShape setFlatness:1.0];
	p2.x = p1.x = p12.x = p11.x = cellFrame.origin.x;
	p3.x = p10.x = cellFrame.origin.x + cornerRadius;
	p4.x = p9.x = cellFrame.origin.x + cellFrame.size.width - cornerRadius;
	p5.x = p6.x = p7.x = p8.x = cellFrame.origin.x + cellFrame.size.width;
	
	p2.y = p3.y = p4.y = p5.y = cellFrame.origin.y;
	p1.y = p6.y = cellFrame.origin.y + cornerRadius;
	p12.y = p7.y = cellFrame.origin.y + cellFrame.size.height - cornerRadius;
	p11.y = p10.y = p9.y = p8.y =  cellFrame.origin.y + cellFrame.size.height;
	
	if (drawColor) {
		// Top left inner
		[mainShape moveToPoint:p1];
		if ([self isTouchingUp] || [self isTouchingLeft] || drawColor == [self topLeftCornerColor]) {
			// Draw square corner
			[mainShape lineToPoint:p2];
			[mainShape lineToPoint:p3];
			
		} else {
			// Draw rounded corner
			[mainShape appendBezierPathWithArcFromPoint:p2 toPoint:p3 radius:cornerRadius];
		}
		
		// Top Right
		[mainShape lineToPoint:p4];
		if ([self isTouchingUp] || [self isTouchingRight] || drawColor == [self topRightCornerColor]) {
			[mainShape lineToPoint:p5];
			[mainShape lineToPoint:p6];
		} else {
			[mainShape appendBezierPathWithArcFromPoint:p5 toPoint:p6 radius:cornerRadius];
		}
		
		[mainShape lineToPoint:p7];
		// Bottom Right
		if ([self isTouchingDown] || [self isTouchingRight]) {
			[mainShape lineToPoint:p8];
			[mainShape lineToPoint:p9];
		} else {
			[mainShape appendBezierPathWithArcFromPoint:p8 toPoint:p9 radius:cornerRadius];
		}
		
		[mainShape lineToPoint:p10];
		// Bottom Left
		if ([self isTouchingDown] || [self isTouchingLeft] || [self color] == [self bottomLeftCornerColor]) {
			[mainShape lineToPoint:p11];
			[mainShape lineToPoint:p12];
		} else {
			[mainShape appendBezierPathWithArcFromPoint:p11 toPoint:p12 radius:cornerRadius];
		}
		[mainShape lineToPoint:p1];
		[mainShape closePath];
		[[self color] set];
		[mainShape fill];
	}
	
	if (topLeftCornerColor) {
		topLeftOutCorner = [NSBezierPath bezierPath];
		[topLeftOutCorner appendInverseArcWithCenter:cellFrame.origin radius:cornerRadius withAngle:0];
	}
	
	if (bottomRightCornerColor) {
		NSPoint arcP = cellFrame.origin;
		arcP.x += cellFrame.size.width;
		arcP.y += cellFrame.size.height;
		bottomRightOutCorner = [NSBezierPath bezierPath];
		[bottomRightOutCorner appendInverseArcWithCenter:arcP radius:cornerRadius withAngle:180];
	}
	
	if (bottomLeftCornerColor) {
		NSPoint arcP = cellFrame.origin;
		arcP.y += cellFrame.size.height;
		bottomLeftOutCorner = [NSBezierPath bezierPath];
		[bottomLeftOutCorner appendInverseArcWithCenter:arcP radius:cornerRadius withAngle:90];
	}
	
	if (topRightCornerColor) {
		NSPoint arcP = cellFrame.origin;
		arcP.x += cellFrame.size.width;
		topRightOutCorner = [NSBezierPath bezierPath];
		[topRightOutCorner appendInverseArcWithCenter:arcP radius:cornerRadius withAngle:-90];
	}
	
	if (topLeftOutCorner) {
		[topLeftCornerColor set];
		[topLeftOutCorner fill];
	}
	
	if (topRightOutCorner) {
		[topRightCornerColor set];
		[topRightOutCorner fill];
	}
	
	if (bottomRightOutCorner) {
		[bottomRightCornerColor set];
		[bottomRightOutCorner fill];
	}
	
	if (bottomLeftOutCorner) {
		[bottomLeftCornerColor set];
		[bottomLeftOutCorner fill];
	}
	
	if (anImage = [self image]) {
		NSRect imageRect = NSMakeRect(0,0,0,0);
		imageRect.size = [anImage size];
		[anImage drawInRect:cellFrame 
				   fromRect:imageRect
				  operation:NSCompositeSourceOver
				   fraction:1.0f];
	}
	
	if (highlightColor) {
		[[highlightColor colorWithAlphaComponent:0.5f] set];
		[NSBezierPath fillRect:cellFrame];
	}
}

- (BOOL)isTouchingUp { return isTouchingUp; }
- (BOOL)isTouchingDown { return isTouchingDown; }
- (BOOL)isTouchingLeft { return isTouchingLeft; }
- (BOOL)isTouchingRight { return isTouchingRight; }
- (void)setIsTouchingUp:(BOOL)aBool { isTouchingUp = aBool; }
- (void)setIsTouchingDown:(BOOL)aBool { isTouchingDown = aBool; }
- (void)setIsTouchingLeft:(BOOL)aBool { isTouchingLeft = aBool; }
- (void)setIsTouchingRight:(BOOL)aBool { isTouchingRight = aBool; }

- (void)setTopLeftCornerColor:(NSColor*)aColor { 
	if (topLeftCornerColor != NULL)
		[topLeftCornerColor release];
	topLeftCornerColor = [aColor retain];
}
- (void)setTopRightCornerColor:(NSColor*)aColor { 
	if (topRightCornerColor != NULL)
		[topRightCornerColor release];
	topRightCornerColor = [aColor retain];
}
- (void)setBottomLeftCornerColor:(NSColor*)aColor { 
	if (bottomLeftCornerColor != NULL)
		[bottomLeftCornerColor release];
	bottomLeftCornerColor = [aColor retain];
}
- (void)setBottomRightCornerColor:(NSColor*)aColor { 
	if (bottomRightCornerColor != NULL)
		[bottomRightCornerColor release];
	bottomRightCornerColor = [aColor retain];
}

- (NSColor*)topLeftCornerColor { return topLeftCornerColor; }
- (NSColor*)topRightCornerColor { return topRightCornerColor; }
- (NSColor*)bottomLeftCornerColor { return bottomLeftCornerColor; }
- (NSColor*)bottomRightCornerColor { return bottomRightCornerColor; }

- (void)dealloc {
	[image release];
	[color release];
	[highlightColor release];
	[topLeftCornerColor release];
	[topRightCornerColor release];
	[bottomLeftCornerColor release];
	[bottomRightCornerColor release];
	[super dealloc];
}

@end

@implementation NSBezierPath(InverseArc)
- (void)appendInverseArcWithCenter:(NSPoint)centerPoint radius:(float)radius withAngle:(int)anAngle {
	NSPoint p1, p2, c1, c2;
	float halfr = radius/2;
	c1 = c2 = p1 = p2 = centerPoint;
	
	switch (anAngle) {
		case 0: case 360:
			p1.x += radius; p2.y += radius;
			c1.x += halfr; c2.y += halfr;
			break;
		case 90: case -270:
			p1.y -= radius; p2.x += radius;
			c1.y -= halfr; c2.x += halfr;
			break;
		case 180: case -180:
			p1.x -= radius; p2.y -= radius;
			c1.x -= halfr; c2.y -= halfr;
			break;
		case -90: case 270:
			p1.y += radius; p2.x -= radius;
			c1.y += halfr; c2.x -= halfr;
	}
	[self closePath];
	[self moveToPoint:centerPoint];
	[self lineToPoint:p1];
	[self curveToPoint:p2 controlPoint1:c1 controlPoint2:c2];
	[self lineToPoint:centerPoint];
	[self closePath];
}
@end

@implementation NSString(MFGridViewExtensions)

+ (NSString*)stringWithChar:(char)aChar {
	char nullTerminatedChar[2];
	nullTerminatedChar[0] = aChar;
	nullTerminatedChar[1] = '\0';
	return [NSString stringWithCString:nullTerminatedChar encoding:NSASCIIStringEncoding];
}
@end