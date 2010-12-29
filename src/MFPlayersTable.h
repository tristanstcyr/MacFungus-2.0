#import <Cocoa/Cocoa.h>
#import <TSFunkyTableView.h>

@interface MFPlayersTable : TSFunkyTableView 
{
	
	NSTextView *fieldEditor;
	int editedRow, dropRow;
}
- (void)startEditingName:(id)sender;
- (void)fixEditor;
- (int)editedRow;
- (void)drawDropHighlightBetweenUpperRow:(int)upperRow andLowerRow:(int)lowerRow;
@end