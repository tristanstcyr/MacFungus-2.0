#import "GameController.h"
#define MFDragDropTableViewDataType @"MFDragDropTableViewDataType"

@interface GameController(Private)
- (void)loadNib;
- (void)modifierFlagsChanged:(NSEvent*)anEvent;
- (NSString*)shapeXML;
@end
@implementation GameController(Private)
- (void)loadNib {
	[NSBundle loadNibNamed:@"GameWindow" owner:self];
	MFPlayerCell *cell = [[MFPlayerCell new] autorelease];
	
	[[[playersTableView tableColumns] objectAtIndex:0] setDataCell:cell];
	[playersTableView setRowHeight:38.0f];
	[playersTableView setIntercellSpacing:NSMakeSize(0,0)];
	[playersTableView reloadData];
	[playersTableView selectRow:0 byExtendingSelection:NO];
	[playersTableView setShouldAnimateHighlight:YES];
	[playersTableView setShouldChangeColor:NO];
	[playersTableView setAutoresizesSubviews:YES];
	[tableViewButtonsView setAutoresizingMask:NSViewMinYMargin];
	[playersTableView registerForDraggedTypes:[NSArray arrayWithObjects:MFDragDropTableViewDataType, nil]];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(tableViewSelectionDidChange:) 
			   name:NSTableViewSelectionDidChangeNotification object:playersTableView];
	[gameWindow setDelegate:self];
	[biteButton setButtonType:NSOnOffButton];
	[clockIndicator setDelegate:self];
	[tableViewButtonsView setAutoresizingMask:NSViewMinYMargin];
}

- (void)modifierFlagsChanged:(NSEvent*)anEvent {
	BOOL newIsAlternateKeyPressed = ([anEvent modifierFlags] & NSAlternateKeyMask) != 0;
	
	if (newIsAlternateKeyPressed != isAlternateKeyPressed && [biteButton state] == NSOnState) {
		newIsAlternateKeyPressed ? [biteButton startGlowingWithColor:[NSColor redColor]] : [biteButton stopGlowing];
		NSEvent *mEvent = [NSEvent mouseEventWithType:NSMouseMoved
												 location:[gameWindow mouseLocationOutsideOfEventStream]
											modifierFlags:(newIsAlternateKeyPressed ? NSAlternateKeyMask : nil)
												timestamp:nil windowNumber:nil context:nil eventNumber:nil clickCount:nil pressure:nil];
		[gridView mouseMoved:mEvent];
	}
	isAlternateKeyPressed = newIsAlternateKeyPressed;
}

- (NSString*)shapeXML {
	NSBundle *bundle = [NSBundle bundleForClass: [self class]];
	NSError *anError = NULL;
	NSString *objcXMLString  = [NSString stringWithContentsOfFile:[bundle pathForResource: @"shapes" ofType: @"xml"]
														encoding:NSASCIIStringEncoding 
														   error:&anError];
	
	if (anError != NULL) {
		NSLog(@"Error loading shapes file: %@", [anError localizedDescription]);
		NSBeep();
		return nil;
	}
	
	return objcXMLString;
}

@end
@implementation GameController
- (id) init {
	if (self = [super init]) {
		colorRow = -1;
		isGameStarted = isAlternateKeyPressed = NO;
		controlsGameSettings = YES;
		afterAnimationSelector = nil;
		aGame = new MFGame();
		aGame->setShapesFromXMLCString([[self shapeXML] cString]);
		playersArray = [[NSMutableArray alloc] init];
		[self loadNib];
		
		// Load the sounds
		biteSound = [NSSound soundNamed:@"bite"];
		eraseSound = [NSSound soundNamed:@"phaser"];
		boingSound = [NSSound soundNamed:@"boing"];
		drumsSound = [NSSound soundNamed:@"drums"];
		bellSound = [NSSound soundNamed:@"bell"];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
											  selector:@selector(stopGame)
											     name:NSWindowWillCloseNotification
											   object:gameWindow];
	}
	
	return self;
}

- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (IBAction)settingsTimeLimitDidChange:(id)sender {

	int newTimeLimit = [[gameSettings objectForKey:@"timeLimit"] intValue];
	NSRect indicatorFrame = [clockIndicator frame];
	NSRect smallFrame;
	smallFrame.size.height = indicatorFrame.size.height;
	smallFrame.size.width = 3.0f;
	smallFrame.origin.x = indicatorFrame.origin.x + indicatorFrame.size.width/2 - smallFrame.size.width/2;
	smallFrame.origin.y = indicatorFrame.origin.y;
	
	if (newTimeLimit != 0 && [clockIndicator isHidden]) {
		[clockIndicator setFrame:smallFrame];
		[clockIndicator setHidden:NO];
		[NSView setDefaultBlockingMode:NSAnimationNonblocking];
		[NSView setDefaultAnimationCurve:NSAnimationEaseInOut];
		[NSView setDefaultDuration:0.3f];
		[clockIndicator animateToFrame:indicatorFrame];
	} else if (newTimeLimit == 0 && ![clockIndicator isHidden]) {
		[NSView setDefaultBlockingMode:NSAnimationBlocking];
		[NSView setDefaultDuration:0.3f];
		[NSView setDefaultAnimationCurve:NSAnimationEaseInOut];
		[clockIndicator animateToFrame:smallFrame];
		[clockIndicator setHidden:YES];
		[clockIndicator setFrame:indicatorFrame];
	}
}

// These are for the subclasses to be implemented
- (IBAction)addPlayerButtonPushed:(id)sender {}
- (IBAction)removePlayerButtonPushed:(id)sender {}
- (IBAction)skipButtonPushed:(id)sender {}
- (IBAction)biteButtonPushed:(id)sender {
	if ([biteButton state] == NSOffState)
		[biteButton stopGlowing];
	else if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
		[biteButton startGlowingWithColor:[NSColor redColor]];
}
- (IBAction)startStopGameButtonPushed:(id)sender 
{ 
	// To prevent abusing of the start stop button
	[startStopGameButton setEnabled:NO forTime:STARTSTOP_MIN_TIME];
	
	if (!isGameStarted) {
		[startStopGameButton setTitle:@"Stop Game"];
		[self startGame];
	} else {
		[startStopGameButton setTitle:@"Start Game"];
		[self stopGame];
	}
}

- (void)addPlayerWithName:(NSString*)aName color:(NSColor*)aColor {
	aGame->addPlayer([aName cStringUsingEncoding:NSUnicodeStringEncoding], Color([aColor redComponent], 
																		   [aColor greenComponent], 
													                       [aColor blueComponent]));
	int playerIndex = aGame->getNumberOfPlayers()-1;
	MFPlayer newPlayer = aGame->getPlayerAtIndex(playerIndex);
	NSDictionary *playerDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:aName, @"name",
		[NSNumber numberWithInt:newPlayer.bites], @"bites",
		[NSNumber numberWithInt:aGame->getNumberOfCharsForPlayerIndex(playerIndex)], @"blocks", 
		aColor, @"color", 
		[NSNumber numberWithBool:NO], @"showStats", nil];
	[playersArray addObject:playerDict];
	[playersTableView reloadData];
	[playersTableView display];
}
- (void)removePlayerAtIndex:(int)anIndex { 
	int selectedRow = [playersTableView selectedRow];
	[playersArray removeObjectAtIndex:anIndex];
	aGame->removePlayerAtIndex(anIndex);
	
	[playersTableView reloadData];
	if (selectedRow > 0)
		[playersTableView selectRow:selectedRow-1 byExtendingSelection:NO];
}

- (void)disableAllGameButtons {
	[startStopGameButton setEnabled:NO];
	[biteButton setEnabled:NO];
	[biteButton setState:NSOffState];
	[skipButton setEnabled:NO];
}

- (void)resetPlayerDictionaries {
	NSEnumerator *anEnum = [playersArray objectEnumerator];
	while (NSMutableDictionary *aPlayer = [anEnum nextObject])
		[aPlayer setObject:[NSNumber numberWithInt:1] forKey:@"blocks"];
}

NSImage* getHotCornerImage(float size) {
	
	const float borderSides = size/4,
				borderTopBottom = size/6;
	NSPoint drawPoint = NSMakePoint(borderSides, borderTopBottom);
	
	NSBezierPath *aPath = [NSBezierPath bezierPath];
	NSRect imageRect = NSMakeRect(0,0,size,size);
	NSImage *cornerImage = [[NSImage alloc] initWithSize:NSMakeSize(size,size)];
	[cornerImage lockFocus];
		[aPath moveToPoint:drawPoint];
		drawPoint.x = size - borderSides;
		[aPath lineToPoint:drawPoint];
		drawPoint.x = size/2;
		drawPoint.y = size - borderTopBottom;
		[aPath lineToPoint:drawPoint];
		[aPath closePath];
		[[NSColor blackColor] set];
		[aPath fill];
	[cornerImage unlockFocus];
	return [cornerImage autorelease];
}

NSImage* getHeadImage(float size) {
	
	NSRect imageRect = NSMakeRect(0,0,size,size);
	const float inset = size/7.0f;
	NSImage *headImage;
	NSRect smallerCellFrame = imageRect;
	smallerCellFrame.origin.x += inset;
	smallerCellFrame.size.width -= inset*2;
	smallerCellFrame.origin.y += inset;
	smallerCellFrame.size.height -= inset*2;
	
	headImage = [[NSImage alloc] initWithSize:NSMakeSize(size,size)];
	[headImage lockFocus];
	// Draw the head
	{
		NSBezierPath *head = [NSBezierPath bezierPathWithOvalInRect:smallerCellFrame];
		[[NSColor whiteColor] set];
		[head fill];
		
		[[NSColor blackColor] set];
		[head setLineWidth:1.2];
		[head stroke];
	}
	[headImage unlockFocus];
	
	  return [headImage autorelease];
}



- (void)coloredCircleClicked
{
	NSColorPanel* panel = [NSColorPanel sharedColorPanel];
	if ([playersTableView selectedRow] == colorRow) {
		[panel performClose:self];
		return;
	}
	[panel setTarget: self];
	[panel setShowsAlpha: NO];
	[panel setDelegate:self];
	[panel setColor:[[playersArray objectAtIndex:[playersTableView selectedRow]] objectForKey:@"color"]];
	colorRow = [playersTableView selectedRow];
	[panel orderFront:self];
	[panel setAction: @selector(colorChanged:)];
}

- (void)resumeProgressIndicator { [clockIndicator resume]; }

- (BOOL)colorChanged:(id)sender
{
	NSColor *pickedColor = [[sender color] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	if ([[NSColor whiteColor] isEqualToColor:pickedColor withinRange:MAX_COLOR_PROXIMITY])
		return NO;
	
	for (int i = 0; i < [playersArray count]; i++) {
		if (i != [playersTableView selectedRow]) {
			NSColor *playerColor = [[playersArray objectAtIndex:i] objectForKey:@"color"];
			if ([playerColor isEqualToColor:pickedColor withinRange:MAX_COLOR_PROXIMITY])
				return NO;
		}
	}

	[[playersArray objectAtIndex:[playersTableView selectedRow]] setObject:pickedColor forKey:@"color"];
	[playersTableView reloadData];
	return YES;
}

- (BOOL)windowShouldClose:(id)sender
{
	if (sender == [NSColorPanel sharedColorPanel]) 
		colorRow = -1;
	return YES;
}

- (BOOL)isGameStarted { return isGameStarted; }

std::vector<MFPlayer> playersVectorFromDictionaryArray(NSArray *aPlayersArray)
{
	std::vector<MFPlayer> playersVector;
	NSEnumerator *thePlayers = [aPlayersArray objectEnumerator];
	NSDictionary *aPlayerDict;
	
	while (aPlayerDict = [thePlayers nextObject]) 
	{
		NSColor *cocoaColor = [aPlayerDict objectForKey:@"color"];
		Color aColor([cocoaColor redComponent], [cocoaColor greenComponent],[cocoaColor blueComponent]);
		std::string aName = [[aPlayerDict objectForKey:@"name"] cStringUsingEncoding:NSASCIIStringEncoding];
		int numBites = [[aPlayerDict objectForKey:@"bites"] intValue];
		playersVector.push_back(MFPlayer(aColor, aName, numBites, true));
	}
	
	return playersVector;
}

NSArray* playersDictionaryArrayFromVector(std::vector<MFPlayer> playersVector)
{
	NSMutableArray *cocoaPlayersArray = [NSMutableArray new];
	std::vector<MFPlayer>::iterator cPlayerPtr;
	for (cPlayerPtr = playersVector.begin(); cPlayerPtr < playersVector.end(); cPlayerPtr++) {
		Color cColor = cPlayerPtr->color;
		NSColor *cocoaColor = [NSColor colorWithCalibratedRed:cColor.red 
														green:cColor.green
														 blue:cColor.blue
														alpha:1.0f];
		NSString *aName = [NSString stringWithCString:cPlayerPtr->name.c_str()
										     encoding:NSASCIIStringEncoding];
		NSNumber *bites = [NSNumber numberWithInt:cPlayerPtr->bites];
		NSMutableDictionary *playerDict = 
			[NSMutableDictionary dictionaryWithObjectsAndKeys:cocoaColor, @"color",
														      aName, @"name",
															  bites, @"bites",
															  [NSNumber numberWithBool:NO], @"showStats", nil];
		[cocoaPlayersArray addObject:playerDict];
	}
	return [cocoaPlayersArray autorelease];
}
/*
- (void)threadedUpdateGridShapeView
{
	NSAutoreleasePool *aPool = [NSAutoreleasePool new];

	NSRect gsvOutFrame, gsvInFrame, gsvRegFrame;
	MFGridShape gridShape = aGame->getShapeAtIndex(aGame->getCurrentShapeIndex());
	gsvOutFrame = [gridShapeView frame];
	gsvOutFrame.origin.x = gsvOutFrame.size.width;
	gsvInFrame = gsvRegFrame = [gridShapeView centeredFrameForShape:aGame->getShapeAtIndex(aGame->getCurrentShapeIndex())];
	gsvInFrame.origin.x = -gsvOutFrame.size.width;
	
	// Bring it out
	[NSView setDefaultBlockingMode:NSAnimationBlocking];
	[NSView setDefaultDuration:0.2f];
	[gridShapeView animateToFrame:gsvOutFrame];
	[gridShapeView setHidden:YES];
	
	[gridShapeView setShape:gridShape.rotate(aGame->getCurrentShapeDegrees()) withColor:[[playersArray objectAtIndex:aGame->getCurrentPlayerIndex()] objectForKey:@"color"]];
	
	// Bring it in
	[gridShapeView setFrame:gsvInFrame];
	[gridShapeView setHidden:NO];
	[gridShapeView animateToFrame:gsvRegFrame];
	[aPool release];
}*/


// Sent from the window to notify us that a modifier key has changed (i.e. option key)
// Were interested here by the option key when we're using the big bite

- (ChatController*)chatController { return chatController; }

@end
@implementation GameController(GameWindowViews)
- (void)openGameWindow 
{
	if (![gameWindow isVisible]) 
	{
		[biteButton setEnabled:NO];
		[skipButton setEnabled:NO];
		[playersTableView reloadData];
		[settingsView setFrameOrigin:NSMakePoint(0,0)];
		[settingsView setFrameSize:[mainView frame].size];
		
		[mainView addSubview:settingsView];
	}

	[gameWindow makeKeyAndOrderFront:self];
}

- (void)updateGridShapeView 
{
	static int previousPlayerIndex;
	int currentPlayerIndex = aGame->getCurrentPlayerIndex();
	
	if (!gridShapeView) {
		NSRect gridShapeViewRect;
		previousPlayerIndex = -1;
		float size = [playersTableView frame].size.width;
		gridShapeViewRect.size = NSMakeSize(size,size);
		gridShapeViewRect.origin = NSMakePoint(0,0);
		gridShapeView = [[MFGridShapeView alloc] initSquareGridWithFrame:gridShapeViewRect numberOfRowsAndCols:7];
		[[[splitView subviews] objectAtIndex:1] addSubview:gridShapeView positioned:NSWindowAbove relativeTo:nil];
		[gridShapeView setDelegate:self];
	}
	//if (previousPlayerIndex != currentPlayerIndex) {
	//	[NSThread detachNewThreadSelector:@selector(threadedUpdateGridShapeView) toTarget:self withObject:nil];
//	} else {
		MFGridShape gridShape = aGame->getShapeAtIndex(aGame->getCurrentShapeIndex());
		[gridShapeView setShape:gridShape.rotate(aGame->getCurrentShapeDegrees()) withColor:[[playersArray objectAtIndex:aGame->getCurrentPlayerIndex()] objectForKey:@"color"]];
	//}
	
	previousPlayerIndex = currentPlayerIndex;
}

- (void)showSettingsView:(BOOL)aBool {
	
	NSRect settingsViewFrame = [settingsView frame];
	
	if (aBool && settingsViewFrame.origin.x < 0)
		settingsViewFrame.origin.x = 0;
	else if (!aBool && settingsViewFrame.origin.x >= 0)
		settingsViewFrame.origin.x = -settingsViewFrame.size.width;
	else
		return;
	
	[NSView setDefaultBlockingMode:NSAnimationBlocking];
	[NSView setDefaultDuration:0.3f];	
	[settingsView animateToFrame:settingsViewFrame];
}

- (void)sizeWindowForGridSize:(int)gridSize {
		NSRect windowRect = [gameWindow frame],
			   mainViewRect = [mainView frame];
		
		int wh = (gridSize < 20? 20: gridSize)*CELL_SIZE;
		int whDif = wh - mainViewRect.size.width;
		
		windowRect.size.width += whDif;
		windowRect.size.height += whDif;
		windowRect.origin.y -= whDif;
		[gameWindow setFrameInsideScreen:windowRect display:YES animate:YES];
		mainViewRect = [mainView frame];
}

- (BOOL)gameWindowVisible {
	return [gameWindow isVisible];

}
@end

@implementation GameController(GamePlay)
const float ANIM_PAUSE = 0.15; 

- (void)nextTurn { [playersTableView display]; }
- (void)startGame {
	
	if (isGameStarted)
		return;
	
	const int gridSize = [[gameSettings objectForKey:@"gridSize"] intValue];
	NSRect gridViewRect, mainViewRect;
	gridView = [[MFGridView alloc] autorelease];
	
	[self sizeWindowForGridSize:gridSize];
	mainViewRect = [mainView frame];
	gridViewRect = NSMakeRect (0,0, mainViewRect.size.width, mainViewRect.size.height);
	gridView = [gridView initSquareGridWithFrame:gridViewRect numberOfRowsAndCols:gridSize];
	
	aGame->setGridSize(gridSize);
	[gridView setImage:getHotCornerImage([mainView frame].size.width/gridSize) forChar:'&'];
	[gridView setColor:[NSColor colorWithCalibratedWhite:0.9f alpha:1.0f] forChar:'*'];
	
	// Configure the colors for the gridview
	const NSImage *headImage = getHeadImage(mainViewRect.size.width/gridSize);
	for (int i = 0; i < [playersArray count]; i++) 
	{
		char playerHead = 'A' + i,
		playerBody = 'a' + i;
		NSDictionary *playerDict = [playersArray objectAtIndex:i];
		NSColor *playerColor = [playerDict objectForKey:@"color"];
		[gridView setColor:playerColor forChar:playerHead];
		[gridView setColor:playerColor forChar:playerBody];
		[gridView setImage:headImage forChar:playerHead];
	}
	
	aGame->setIsUsingHotCorners([[gameSettings objectForKey:@"isUsingHotCorners"] boolValue]);
	aGame->startGame();
	isGameStarted = YES;
	
	[gridView setDelegate:self];
	[gridView setGridAndDisplay:aGame->getCurrentGrid()];
	[mainView addSubview:gridView positioned:NSWindowBelow relativeTo:settingsView];
	[mainView setNextResponder:gridView];
	[gridView setNextResponder:nil];
	
	[splitView showShapeView:YES];
	[self showSettingsView:NO];
	
	if (aGame->getCurrentPlayerIndex() != [playersTableView selectedRow])
		[playersTableView setShouldChangeColorWithoutDisplay:YES];
	else 
		[playersTableView setShouldChangeColor:YES];

	[playersTableView deselectAll:self];
	[playersTableView selectRow:aGame->getCurrentPlayerIndex() byExtendingSelection:NO];
	[playersTableView setAcceptsMouseDown:NO];
}

- (void)stopGame {

	if (!isGameStarted)
		return;
	isGameStarted = NO;	
	
	[clockIndicator stop];
	[clockIndicator setFractionAndDisplay:0];

	[playersTableView setShouldChangeColor:NO];
	[playersTableView deselectAll:self];
	[playersTableView setAcceptsMouseDown:YES];
	[skipButton setEnabled:NO];
	[biteButton setEnabled:NO];
	[biteButton setState:NSOffState];
	[splitView showShapeView:NO];
	[gridShapeView setShape:MFGridShape() withColor:nil];
	[mainView setNextResponder:nil];
	[self showSettingsView:YES];
	
	[gridView removeFromSuperviewWithoutNeedingDisplay];
	[self resetPlayerDictionaries];
}
- (void)skipTurn {
	int playerIndex = aGame->getCurrentPlayerIndex();
	bool punished = (aGame->getPlayerAtIndex(playerIndex)).turnSkips > 1;
	NSMutableArray *soundsArray = [NSMutableArray new];
	std::vector<pMFGrid> eraseSequence, eatSequence;
	std::vector<std::vector<pMFGrid> > animationSequences;
	aGame->skipTurn(playerIndex);
	eraseSequence = aGame->getLastEraseSequence();
	eatSequence = aGame->getLastEatSequence();
	
	if (eatSequence.size() > 0) {
		[soundsArray addObject:biteSound];
		animationSequences.push_back(eatSequence);
	}
	if (eraseSequence.size() > 0) {
		[soundsArray addObject:eraseSound];
		animationSequences.push_back(eraseSequence);
	}
	
	if (punished && animationSequences.size() > 0) {
		[gridView animateWithSequences:animationSequences sounds:soundsArray delay:ANIM_PAUSE];
		afterAnimationSelector = @selector(nextTurn);
	} else {
		[self nextTurn];
	}
}

- (void)playShape:(int)shapeIndex withDegrees:(int)degrees atRow:(int)aRow column:(int)aColumn
{
	NSMutableArray *soundsArray = [NSMutableArray new];
	std::vector<std::vector<pMFGrid> > animationSequences;
	std::vector<pMFGrid> eatSequence, eraseSequence;
	if(aGame->playShapeIsValid(degrees, aGame->getCurrentPlayerIndex(), aRow, aColumn) == false) {
		[boingSound play];
		return;
	}
	[clockIndicator stop];
	
	[gridView setHighlightGridAndDisplay:MFGrid([gridView numberOfRows])];
	[gridView setGridAndDisplay:aGame->getShapeOnGrid(degrees, aGame->getCurrentPlayerIndex(), aRow, aColumn)];
	aGame->playShape(degrees, aGame->getCurrentPlayerIndex(), aRow, aColumn);
	eatSequence = aGame->getLastEatSequence();
	eraseSequence = aGame->getLastEraseSequence();
	
	if (eatSequence.size() > 0) {
		[soundsArray addObject:biteSound];
		animationSequences.push_back(eatSequence);
	}
	if (eraseSequence.size() > 0) {
		[soundsArray addObject:eraseSound];
		animationSequences.push_back(eraseSequence);
	}
	if (animationSequences.size() > 0) {
		[self disableAllGameButtons];
		[gridView animateWithSequences:animationSequences sounds:[soundsArray autorelease] delay:ANIM_PAUSE];
		afterAnimationSelector = @selector(nextTurn);
	} else {
		[self nextTurn];
	}
}

- (void)playBite:(int)shapeIndex withDegrees:(int)degrees atRow:(int)aRow column:(int)aColumn
{
	NSMutableArray *soundsArray = [[NSMutableArray new] autorelease];
	std::vector<std::vector<pMFGrid> > animationSequences;
	std::vector<pMFGrid> eraseSequence;
	if(aGame->playBiteIsValid(shapeIndex , aGame->getCurrentPlayerIndex(), aRow, aColumn) == 0) {
		[boingSound play];
		return;
	}
	
	[clockIndicator stop];
	[gridView setHighlightGridAndDisplay:MFGrid([gridView numberOfRows])];
	aGame->playBite(shapeIndex, aGame->getCurrentPlayerIndex(), aRow, aColumn);
	[biteSound play];
	
	[gridView setGridAndDisplay:aGame->getLastMoveGrid()];
	eraseSequence = aGame->getLastEraseSequence();
	if (eraseSequence.size() > 0) {
		[soundsArray addObject:eraseSound];
		animationSequences.push_back(eraseSequence);
	}
	if (animationSequences.size() > 0) {
		[self disableAllGameButtons];
		[gridView animateWithSequences:animationSequences sounds:soundsArray delay:ANIM_PAUSE];
		if ([[gameSettings objectForKey:@"timeLimit"] intValue] != 0)
			afterAnimationSelector = @selector(resumeProgressIndicator);
	} else if ([[gameSettings objectForKey:@"timeLimit"] intValue] != 0) { 
		[self resumeProgressIndicator]; 
	}
	
	[biteButton setState:NSOffState];
	[biteButton stopGlowing];
	[playersTableView display];
	
	if (aGame->getWinnerIndex() != -1)
		[self nextTurn];
}

// MFGridView Delegate Methods
- (void)gridView:(MFGridView*)aGridView mouseMovedOverRow:(int)aRow column:(int)aCol withEvent:(NSEvent*)anEvent
{
	unsigned int modifFlags = [anEvent modifierFlags];
	if ([gridView isAnimating])
		return;
	if (aRow == -1 || aCol == -1) {
		[gridView setHighlightGridAndDisplay:MFGrid(aGame->getCurrentGrid().size())];
	} else if([biteButton state] == NSOffState) 
	{
		MFGrid highlightGrid;
		int degrees = aGame->getCurrentShapeDegrees();
		highlightGrid = aGame->getShapeHighlightGrid(degrees, aGame->getCurrentPlayerIndex(), aRow, aCol);					
		[gridView setHighlightGridAndDisplay:highlightGrid];
	} else {
		bool isBigBite = ((modifFlags & NSAlternateKeyMask) != 0);
		int shapeIndex (isBigBite ? aGame->getCurrentShapeIndex() : 3);
		int shapeDegrees = aGame->getCurrentShapeDegrees();
		MFGrid aHighlightGrid = aGame->getBiteHighlightGrid(shapeIndex, shapeDegrees, aGame->getCurrentPlayerIndex(), aRow, aCol);
		[gridView setHighlightGridAndDisplay:aHighlightGrid];
	}
}

- (void)gridView:(MFGridView*)aGridView mouseDownOnRow:(int)aRow column:(int)aCol withEvent:(NSEvent*)anEvent
{
	unsigned int modifFlags = [anEvent modifierFlags];
	
	if ([gridView isAnimating])
		return;
	
	if (modifFlags & NSControlKeyMask || [anEvent type] == NSRightMouseDown) {
		aGame->rotateCurrentShape();
		[self updateGridShapeView];
		[self gridView:aGridView mouseMovedOverRow:aRow column:aCol withEvent:anEvent];
		return;
	}
	
	if ([biteButton state] == NSOffState)
		[self playShape:aGame->getCurrentShapeIndex() withDegrees:aGame->getCurrentShapeDegrees() atRow:aRow column:aCol];
	else {
		bool isBigBite = ((modifFlags & NSAlternateKeyMask) != 0);
		int shapeIndex =  (isBigBite ? aGame->getCurrentShapeIndex() : 3);
		int shapeDegrees = aGame->getCurrentShapeDegrees();
		[self playBite:shapeIndex withDegrees:shapeDegrees atRow:aRow column:aCol];
	}
}

- (void)gridView:(MFGridView*)aGridView scrollWheel:(NSEvent*)anEvent
{
	static float rotation = 0;
	float deltaY = [anEvent deltaY];
	rotation += deltaY*5;
	if (deltaY < 0) {
		aGame->rotateCurrentShape();
	} else {
		aGame->rotateCurrentShape();											// ok this is a bit sloopy...but it works
		aGame->rotateCurrentShape();
		aGame->rotateCurrentShape();
	}
	[self updateGridShapeView];
	[gridView mouseMoved:[NSApp currentEvent]];
}
- (void)gridViewAnimationDidEnd:(MFGridView*)aGridView  
{
	if (afterAnimationSelector) {
		[self performSelector:afterAnimationSelector];
		afterAnimationSelector = nil;
	}
	[startStopGameButton setEnabled:YES];
}

- (void)progressClockIndicatorDidEndAnimation:(TSTimedProgressIndicator*)aClock {
	if (isGameStarted) {
		[bellSound stop];
		[bellSound play];
		[self skipTurn];
	}
}

@end
@implementation GameController(MFPlayersTableDataSource)
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	
	NSMutableDictionary *playerDict = [playersArray objectAtIndex:rowIndex];
	int bites, blocks;
	if (isGameStarted) {
		MFPlayer currentPlayer = aGame->getPlayerAtIndex(rowIndex);
		bites = currentPlayer.bites;
		blocks = aGame->getNumberOfCharsForPlayerIndex(rowIndex);
	} else {
		bites = 3; blocks = 1;
	}
	
	[playerDict setObject:[NSNumber numberWithInt:bites] forKey:@"bites"];
	[playerDict setObject:[NSNumber numberWithInt:blocks] forKey:@"blocks"];
	
	return playerDict;
}
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [playersArray count];
}
- (NSColor *)tableView:(MFPlayersTable *)aTableView colorForRow:(int)rowIndex
{
	return [[playersArray objectAtIndex:rowIndex] objectForKey:@"color"];
}

- (void)tableView:(NSTableView*)aTableView setObjectValue:(id)aValue forTableColumn:(int)column row:(int)row 
{
	const int maxNameLength = 12;
	if (aValue == nil)
		return;
		
	if ([aValue length] > maxNameLength)
		aValue = [aValue substringWithRange:NSMakeRange(0 , maxNameLength)];
	
	NSMutableDictionary *playerDict = [playersArray objectAtIndex:row];
	[playerDict setObject:[NSString stringWithString:aValue] forKey:@"name"];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ([aCell isKindOfClass:[MFPlayerCell class]])
		[(MFPlayerCell*)aCell setIsColorCircledPressed:(rowIndex == colorRow)];
}

- (void)tableViewSelectionDidChange:(NSNotificationCenter*)notif  {
	colorRow = -1;
	if ([[NSColorPanel sharedColorPanel] isVisible])
		[self coloredCircleClicked];
}
@end
@implementation GameController(MFPlayerTableViewDragging)
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes 
										    toPasteboard:(NSPasteboard*)pboard 
{
	// Copy the row numbers to the pasteboard.
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
	[pboard declareTypes:[NSArray arrayWithObject:MFDragDropTableViewDataType] owner:self];
    [pboard setData:data forType:MFDragDropTableViewDataType];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv 
			    validateDrop:(id <NSDraggingInfo>)info 
				 proposedRow:(int)row 
	   proposedDropOperation:(NSTableViewDropOperation)op
{	
	if (op == NSTableViewDropOn)
		[tv setDropRow:(row+1) dropOperation:NSTableViewDropAbove];
    
	return NSDragOperationGeneric;    
}

- (BOOL)tableView:(NSTableView *)aTableView 
	   acceptDrop:(id <NSDraggingInfo>)info
              row:(int)dropRowIndex 
	dropOperation:(NSTableViewDropOperation)operation

{	
	int selectedRow = [playersTableView selectedRow];
	NSDictionary *selectedPlayer = nil;
	if (selectedRow >= 0)
		selectedPlayer = [playersArray objectAtIndex:selectedRow]; 
	
	NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:MFDragDropTableViewDataType];
	int dragRowIndex = [[NSKeyedUnarchiver unarchiveObjectWithData:rowData] firstIndex];
	NSDictionary *draggedRow = [[playersArray objectAtIndex:dragRowIndex] retain];
	if (dragRowIndex < dropRowIndex)
		dropRowIndex -= 1;
		
	[playersArray removeObjectAtIndex:dragRowIndex];
	[playersArray insertObject:draggedRow atIndex:dropRowIndex];
	
	// To preserve selection
	if (selectedPlayer) {
		selectedRow = [playersArray indexOfObject:selectedPlayer];
		[playersTableView selectRow:selectedRow byExtendingSelection:NO];
	}
	[playersTableView reloadData];
	
	aGame->swapPlayersAtIndexes(dropRowIndex, dragRowIndex);
	return YES;
}
@end
@implementation NSColor(NSColorCompare)

- (BOOL)isEqualToColor:(NSColor*)anotherColor 
{
	return ([self colorSpace] == [anotherColor colorSpace]
			&& [self redComponent] == [anotherColor redComponent]
			&& [self blueComponent] == [anotherColor blueComponent]
			&& [self greenComponent] == [anotherColor greenComponent]
			&& [self alphaComponent] == [anotherColor alphaComponent]);
}

- (BOOL)isEqualToColor:(NSColor*)otherColor withinRange:(float)range
{
	float red, green, blue;
	NSColor *color1 = [self colorUsingColorSpaceName:NSDeviceRGBColorSpace],
			*color2 = [otherColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	
	red = [color1 redComponent] - [color2 redComponent];
	green = [color1 greenComponent] - [color2 greenComponent];
	blue = [color1 blueComponent] - [color2 blueComponent];
	
	if (red < 0) red *= -1;
	if (green < 0) green *= -1;
	if (blue < 0) blue *= -1;
	
	return ( ((red+green+blue) / 3) < range);
}	

@end
@implementation NSButton(TimedSetEnable)

- (void)setEnabled:(BOOL)aBool forTime:(float)time {
	NSTimer *aTimer;
	[self setEnabled:aBool];
	aTimer = [NSTimer timerWithTimeInterval:time 
									 target:self 
								   selector:@selector(enableChangeEnded:)
								   userInfo:[NSNumber numberWithBool:!aBool]
									repeats:NO];
	[[NSRunLoop currentRunLoop] addTimer:aTimer forMode:NSDefaultRunLoopMode];

}

- (void)enableChangeEnded:(NSTimer*)aTimer {
	[self setEnabled:[[aTimer userInfo] boolValue]];
}

@end
@implementation NSWindow(ResizeInScreen)

- (void)setFrameInsideScreen:(NSRect)aRect display:(BOOL)displayFlag animate:(BOOL)animateFlag {

	if (aRect.origin.y < 0) aRect.origin.y = 0;
		if (aRect.origin.x + aRect.size.width > [[self screen] frame].size.width)
			aRect.origin.x -= aRect.origin.x + aRect.size.width - [[self screen] frame].size.width;
	[self setFrame:aRect display:displayFlag animate:animateFlag];
}
@end
@implementation MFPlayerTableSplitView
- (void)showShapeView:(BOOL)aBool {
	NSRect frame = [self frame];
	float p; 
	
	if (aBool) {
		p = frame.size.height + [self dividerThickness] - frame.size.width;
		[self setSplitterPosition:p animate:YES];
	} else {
		p = frame.size.height - [self dividerThickness];
		[self setSplitterPosition:p animate:YES];
	}
}

// Make splitview unmanipulable
- (void)mouseMoved:(NSEvent*)anEvent {}
- (void)mouseDown:(NSEvent*)anEvent {}
- (void)resetCursorRects { }
- (void)resetCursorRect:(NSRect)cellFrame inView:(NSView *)controlView { }

@end
@implementation MFGridShapeView
const char DRAW_CHAR = '-';
const int REF_ROW = 3, REF_COL = 3;

- (NSImage*)backgroundImageInSize:(NSSize)aSize { return nil; }
- (id)initSquareGridWithFrame:(NSRect)frameRect numberOfRowsAndCols:(int)rowsAndCols {
	[super initSquareGridWithFrame:(NSRect)frameRect numberOfRowsAndCols:(int)rowsAndCols];
	[self setIntercellSpacing:NSMakeSize(-0.5,-0.5)];
	return self;
}
- (void)mouseMoved:(NSEvent*)anEvent {}
- (void)rightMouseDown:(NSEvent*)anEvent {
	if ([[self delegate] respondsToSelector:@selector(gridView:mouseDownOnRow:column:withEvent:)])
		[[self delegate] gridView:self mouseDownOnRow:-1 column:-1 withEvent:anEvent];
 }
- (BOOL)acceptsFirstResponder { return NO; }
- (void)mouseDown:(NSEvent*)anEvent {
	if ([[self delegate] respondsToSelector:@selector(gridView:mouseDownOnRow:column:withEvent:)])
		[[self delegate] gridView:self mouseDownOnRow:-1 column:-1 withEvent:anEvent];}

- (void)setShape:(MFGridShape)aShape withColor:(NSColor*)aColor 
{
	MFGrid newGrid([self numberOfRows]);
	newGrid.drawShape(aShape, REF_ROW, REF_COL, DRAW_CHAR);
	[self setColor:aColor forChar:DRAW_CHAR];
	[self setGrid:newGrid];
	[self setFrame:[self centeredFrameForShape:aShape]];
	[self display];
}

- (NSRect)centeredFrameForShape:(MFGridShape)aShape {
	
	int tmR = 0, bmR = 0, rmC = 0, lmC = 0;
	float tSpace, bSpace, lSpace, rSpace;
	NSRect newFrame = [self frame];
	NSSize cellSize = [self cellSize];
	[self setCellSize:cellSize];
	std::vector<Position > posVect;
	posVect = aShape.cellVectors;
	
	for (int i = 0; i < posVect.size(); i++) {
		Position aPos = posVect.at(i);
		if (aPos.row < tmR) 
			tmR = aPos.row;
		if (aPos.row > bmR)
			bmR = aPos.row;
		if (aPos.col < lmC)
			lmC = aPos.col;
		if (aPos.col > rmC)
			rmC = aPos.col;
	}
	
	tSpace = cellSize.height * (REF_ROW + tmR);
	bSpace = cellSize.height * ([self numberOfRows] - (REF_ROW + bmR + 1));
	lSpace = cellSize.width * (REF_COL +lmC);
	rSpace = cellSize.width * ([self numberOfRows] - (REF_COL + rmC + 1));
	
	newFrame.origin.x = round((rSpace - lSpace)/2) + 0.5f;
	newFrame.origin.y = round((tSpace - bSpace)/2) + 0.5f;
	
	NSLog(@"(%f,%f,%f,%f)",newFrame.origin.x,newFrame.origin.y,newFrame.size.width,newFrame.size.height);
	return newFrame;
}

- (void)drawRect:(NSRect)aRect {
	[NSGraphicsContext saveGraphicsState]; 
	/*NSShadow* theShadow = [[NSShadow alloc] init]; 
	[theShadow setShadowOffset:NSZeroSize]; 
	[theShadow setShadowBlurRadius:2.0]; 
	[theShadow setShadowColor:[[self colorForChar:DRAW_CHAR] colorWithAlphaComponent:0.4]];
	[theShadow set];*/
	[super drawRect:aRect];
	[NSGraphicsContext restoreGraphicsState];
	//[theShadow release]; 
}

@end

@implementation MFShapeBGView
- (id) bottomTextAttributes
{
	id attributes;
	float fontSize = 10.0f;
	NSColor *textColor = [NSColor whiteColor];
	//NSColor *fontColor = ([self isHighlighted]?[NSColor whiteColor]:[NSColor blackColor]);
	attributes = [[NSDictionary alloc] initWithObjectsAndKeys: 
		[NSFont fontWithName:@"Helvetica Bold" size:fontSize], NSFontAttributeName, 
		textColor, NSForegroundColorAttributeName, nil];
	return attributes;
}
- (void)drawRect:(NSRect)aRect {
	[super drawRect:aRect];
	NSString *messageString = NSLocalizedString(@"shapeViewKey", @"shapeViewKey");
	NSRect imageRect;
	NSImage *background = [NSImage imageNamed:@"shapesbg"];
	NSSize textSize = [messageString sizeWithAttributes:[self bottomTextAttributes]];
	NSPoint drawPoint;
	
	imageRect.origin = NSZeroPoint;
	imageRect.size = [background size];
	drawPoint.x = ([self frame].size.width - textSize.width)/2;
	drawPoint.y = 12.0f;
	[[NSGraphicsContext currentContext] setShouldAntialias:YES];

	[background drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
	[messageString drawAtPoint:drawPoint withAttributes:[self bottomTextAttributes]];
}
@end
@implementation MFSettingsView
- (void)drawRect:(NSRect)aRect {
	[[NSColor controlColor] set];
	[NSBezierPath fillRect:aRect];
	[super drawRect:aRect];
}
@end

@implementation MFGameWindow

- (void)sendEvent:(NSEvent *)theEvent 
{
	id delegate = [self delegate];
	SEL optionKeySelector = @selector(modifierFlagsChanged:);
	if ([theEvent type] == NSFlagsChanged && [delegate respondsToSelector:optionKeySelector])
		[delegate performSelector:optionKeySelector withObject:theEvent];
	
	[super sendEvent:theEvent];
}

@end