#import <Cocoa/Cocoa.h>
#import <MFPlayersTable.h>
#import <MFGame.h>
#import <MFGridView.h>
#import <MFPlayerCell.h>
#import <AnimatedSplitView.h>
#import <TSTimedProgressIndicator.h>
#import <NSView+AMViewAnimation.h>
#import <MFGlowingButton.h>
#import <ChatController.h>

static const float SETTINGS_SLIDE_TIME = 0.15f,
				   PLUSMINUS_SLIDE_TIME = 0.15f,
				   STARTSTOP_MIN_TIME = 1.0f,
				   MAX_COLOR_PROXIMITY = 0.1f,
				   CELL_SIZE = 18.0f;

@interface MFPlayerTableSplitView : AnimatedSplitView { }
- (void)showShapeView:(BOOL)aBool;
@end
@interface MFGridShapeView : MFGridView { }
- (void)setShape:(MFGridShape)gridShape withColor:(NSColor*)aColor;
- (NSRect)centeredFrameForShape:(MFGridShape)aShape;
@end
@interface MFShapeBGView : NSView {} @end
@interface MFSettingsView : NSView {} @end
@interface MFGameWindow : NSWindow {
	BOOL optionKeyIsDown;
} 
@end

@interface GameController : NSObject
{
    IBOutlet MFGameWindow *gameWindow;
	
	IBOutlet MFGlowingButton *biteButton;
	IBOutlet NSButton *skipButton;
	IBOutlet NSButton *startStopGameButton;
    IBOutlet NSButton *chatDrawerButton;
	
	IBOutlet TSTimedProgressIndicator *clockIndicator;
	IBOutlet NSView *mainView;
	IBOutlet MFSettingsView *settingsView;
	
	IBOutlet MFPlayerTableSplitView *splitView;
	IBOutlet MFPlayersTable *playersTableView;
	IBOutlet NSView *tableViewButtonsView;
	IBOutlet NSButton *plusPlayerButton;
	IBOutlet NSButton *minusPlayerButton;
	
	IBOutlet ChatController *chatController;
	
	int colorRow;
	BOOL isGameStarted, controlsGameSettings, isAlternateKeyPressed;

	MFGame *aGame;
	MFGridView *gridView;
	MFGridShapeView *gridShapeView;
	SEL afterAnimationSelector;
	
	NSMutableDictionary *gameSettings;
	NSMutableArray *playersArray;
	
	NSSound *biteSound;
	NSSound *eraseSound;
	NSSound *boingSound;
	NSSound *drumsSound;
	NSSound *bellSound;
}

- (IBAction)skipButtonPushed:(id)sender;
- (IBAction)biteButtonPushed:(id)sender;
- (IBAction)startStopGameButtonPushed:(id)sender;
- (IBAction)settingsTimeLimitDidChange:(id)sender;
- (IBAction)addPlayerButtonPushed:(id)sender;
- (IBAction)removePlayerButtonPushed:(id)sender;

- (BOOL)isGameStarted;
- (void)resumeProgressIndicator;
- (void)resetPlayerDictionaries;
- (void)disableAllGameButtons;
- (void)addPlayerWithName:(NSString*)aName color:(NSColor*)aColor;
- (void)removePlayerAtIndex:(int)anIndex;
- (ChatController*)chatController;
@end

@interface GameController(GamePlay)
- (void)startGame;
- (void)stopGame;
- (void)nextTurn;
- (void)skipTurn;
- (void)gridView:(MFGridView*)aGridView mouseMovedOverRow:(int)aRow column:(int)aCol withEvent:(NSEvent*)anEvent;
- (void)gridView:(MFGridView*)aGridView mouseDownOnRow:(int)aRow column:(int)aCol withEvent:(NSEvent*)anEvent;
- (void)gridViewAnimationDidEnd:(MFGridView*)aGridView ;
@end
@interface GameController(GameWindowViews)
- (void)openGameWindow;
- (BOOL)gameWindowVisible;
- (void)updateGridShapeView;
- (void)showSettingsView:(BOOL)aBool;
- (void)sizeWindowForGridSize:(int)gridSize;
@end
@interface GameController(MFPlayersTableDataSource)
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (NSColor *)tableView:(MFPlayersTable *)aTableView colorForRow:(int)rowIndex;
@end

@interface GameController(MFPlayersTableDelegation)
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes 
										    toPasteboard:(NSPasteboard*)pboard;
- (NSDragOperation)tableView:(NSTableView*)tv 
			    validateDrop:(id <NSDraggingInfo>)info 
				 proposedRow:(int)row 
	   proposedDropOperation:(NSTableViewDropOperation)op;
- (BOOL)tableView:(NSTableView *)aTableView 
	   acceptDrop:(id <NSDraggingInfo>)info
              row:(int)dropRowIndex 
	dropOperation:(NSTableViewDropOperation)operation;
@end

@interface NSColor(NSColorCompare)
- (BOOL)isEqualToColor:(NSColor*)anotherColor;
- (BOOL)isEqualToColor:(NSColor*)color2 withinRange:(float)range;
@end

@interface NSButton(TimedSetEnable)
- (void)setEnabled:(BOOL)aBool forTime:(float)time;
- (void)enableChangeEnded:(NSTimer*)aTimer;
@end

@interface NSWindow(ResizeInScreen)
- (void)setFrameInsideScreen:(NSRect)aRect display:(BOOL)displayFlag animate:(BOOL)animateFlag;
@end