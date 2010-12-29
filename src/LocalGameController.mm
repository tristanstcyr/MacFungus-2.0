#import "LocalGameController.h"
const NSString *normalSettingsKey = @"normalGameSettings";
const NSString *playersArrayKey = @"normalGamePlayers";

@implementation LocalGameController
- (id) init 
{
	if (self = [super init]) 
	{
		NSData *settingsData = [[NSUserDefaults standardUserDefaults] objectForKey:normalSettingsKey],
			   *playersData = [[NSUserDefaults standardUserDefaults] objectForKey:playersArrayKey];
		
		if (settingsData == nil) 
		{
			NSArray *keys = [NSArray arrayWithObjects:@"isUsingHotCorners", @"gridSize", @"gameSpeed", 
				@"timeLimit", @"isOnTracker", @"gameName", nil];
			NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithBool:YES], [NSNumber numberWithInt:20],
														 [NSNumber numberWithInt:0], [NSNumber numberWithInt:0], 
														 [NSNumber numberWithBool:NO], @"", nil];
			gameSettings = [NSMutableDictionary dictionaryWithObjects:objects forKeys:keys];
		} else 
			[self setValue:[NSUnarchiver unarchiveObjectWithData:settingsData] forKey:@"gameSettings"];
		
		if (playersData == nil) 
		{
			[self addPlayerWithName:@"Player 1" color:[NSColor orangeColor]];
			[self addPlayerWithName:@"Player 2" color:[NSColor purpleColor]];
		} else {
			NSEnumerator *archivedPlayers = [[NSUnarchiver unarchiveObjectWithData:playersData] objectEnumerator];
			NSDictionary *aDict;
			while (aDict = [archivedPlayers nextObject])
				[self addPlayerWithName:[aDict objectForKey:@"name"] color:[aDict objectForKey:@"color"]];
		}
		[gameSettings retain];
		isTableViewButtonsViewVisible = NO;
	}
	return self;
}

- (void)dealloc 
{
	[gameSettings release];
	[playersArray release];
	[super dealloc];
}

- (void)saveGameSettings 
{
	NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
	[self resetPlayerDictionaries];
	[userDef setObject:[NSArchiver archivedDataWithRootObject:gameSettings] forKey:normalSettingsKey]; 
	[userDef setObject:[NSArchiver archivedDataWithRootObject:playersArray] forKey:playersArrayKey];
	[userDef synchronize];
}

- (void)openGameWindow 
{
	[super openGameWindow];
	[self showPlayersTableViewButtons];
	[[self chatController] setChatEnabled:YES];
	if ([[gameSettings objectForKey:@"timeLimit"] intValue] > 0)
		[clockIndicator setHidden:NO];
}

- (IBAction)addPlayerButtonPushed:(id)sender 
{ 
	const int MAX_PLAYERS = 4;
	NSColor *newPlayerColor;
	NSString *newPlayerName;
	NSArray *colorArray = [NSArray arrayWithObjects:[NSColor blueColor], 
							[NSColor redColor], [NSColor orangeColor], [NSColor purpleColor], nil];
	
	// Find a unique color
	for (int colorIndex = 0; colorIndex < [colorArray count]; colorIndex++) {
		BOOL foundIdentical = NO;
		newPlayerColor = [colorArray objectAtIndex:colorIndex];
		for (int playerIndex = 0; playerIndex < [playersArray count]; playerIndex++) {
			NSColor *playerColor = [[playersArray objectAtIndex:playerIndex] objectForKey:@"color"];
			if (foundIdentical = [playerColor isEqualToColor:newPlayerColor withinRange:MAX_COLOR_PROXIMITY])
				break;
		}
		if (!foundIdentical) break;
	}
	
	// Find a unique name
	for (int nameNumber = 0; nameNumber < MAX_PLAYERS; nameNumber++)
	{
		BOOL foundIdentical = NO;
		newPlayerName = [NSString stringWithFormat:@"%@ %i", NSLocalizedString(@"player",@"player"), nameNumber+1];
		for (int playerIndex = 0; playerIndex < [playersArray count]; playerIndex++) {
			NSString *playerName = [[playersArray objectAtIndex:playerIndex] objectForKey:@"name"];
			if ([playerName isEqualToString:newPlayerName]) {
				foundIdentical = YES;
				break;
			}
		}
		if (foundIdentical == NO)
			break;
	}

	[self addPlayerWithName:newPlayerName color:newPlayerColor];
	[playersTableView selectRow:[playersArray count]-1 byExtendingSelection:NO];
	[self evaluateAddRemovePlayerButtons];
}

- (IBAction)removePlayerButtonPushed:(id)sender
{
	int selectedRow = [playersTableView selectedRow];
	if (selectedRow == -1)
		return;
	[self removePlayerAtIndex:selectedRow];
	[self evaluateAddRemovePlayerButtons];
}

- (void)skipButtonPushed:(id)sender 
{
	[self skipTurn];
}

- (void)evaluateAddRemovePlayerButtons {
	int numberOfPlayers = [playersArray count];
	[plusPlayerButton setEnabled:(numberOfPlayers < 4)];
	[minusPlayerButton setEnabled:(numberOfPlayers > 2 && [playersTableView selectedRow] >= 0)];
}

- (void)showPlayersTableViewButtons
{
	if (!isTableViewButtonsViewVisible) {
		NSRect buttonViewRect;
		buttonViewRect.size = [tableViewButtonsView frame].size;
		buttonViewRect.origin.y = [playersTableView frame].size.height - buttonViewRect.size.height;
		buttonViewRect.origin.x = -buttonViewRect.size.width;
		[tableViewButtonsView setFrame:buttonViewRect];
		[playersTableView addSubview:tableViewButtonsView];
		buttonViewRect.origin.x = 0;
		[NSView setDefaultDuration:0.3f];
		[tableViewButtonsView animateToFrame:buttonViewRect];
		[self evaluateAddRemovePlayerButtons];
		isTableViewButtonsViewVisible = YES;
	}
}

- (void)hidePlayersTableViewButtons 
{ 
	if (isTableViewButtonsViewVisible) {
		NSRect buttonViewRect = [tableViewButtonsView frame];
		buttonViewRect.origin.x = -buttonViewRect.size.width;
		[plusPlayerButton setEnabled:NO];
		[minusPlayerButton setEnabled:NO];
		[NSView setDefaultDuration:0.3f];
		[NSView setDefaultBlockingMode:NSAnimationBlocking];
		[tableViewButtonsView animateToFrame:buttonViewRect];
		isTableViewButtonsViewVisible = NO;
		[tableViewButtonsView removeFromSuperview];
	}
}

- (void)startGame 
{
	[self hidePlayersTableViewButtons];
	[super startGame];
	[self nextTurn];
}

- (void)stopGame 
{
	[super stopGame];
	[self showPlayersTableViewButtons];
}

- (void)nextTurn 
{
	if (aGame->getWinnerIndex() != -1) {
		[drumsSound play];
		[gridView setAcceptsInput:NO];
		[skipButton setEnabled:NO];
		[biteButton setEnabled:NO];
		
	} else {
		int playerIndex = aGame->getCurrentPlayerIndex();
		NSTimeInterval timeLimit = [[gameSettings objectForKey:@"timeLimit"] doubleValue];
		aGame->setRandomShapeIndex();
		[biteButton setEnabled:(aGame->getPlayerAtIndex(aGame->getCurrentPlayerIndex()).bites > 0)];
		[skipButton setEnabled:YES];
		[self updateGridShapeView];
		[playersTableView selectRow:playerIndex byExtendingSelection:NO];
		[gameWindow makeFirstResponder:gridView];
		if (timeLimit)
			[clockIndicator startClockForTime:timeLimit];
	}
	[super nextTurn];
}

- (void)tableViewSelectionDidChange:(NSNotificationCenter*)notif  { 
	[super tableViewSelectionDidChange:notif];
	[self evaluateAddRemovePlayerButtons];
}

@end
