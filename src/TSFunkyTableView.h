#import <Cocoa/Cocoa.h>


@interface TSFunkyTableView : NSTableView {
	
	//For Animations
	BOOL isAnimatingHighlight, 
		 shouldAnimateHighlight, 
		 shouldChangeColor,
		 acceptsMouseDown;

	float animationTime, animationFPS;
	
	NSTimer *animationTimer;
	NSRect highlightRect;
	NSColor *highlightColor, *defaultHighlightColor;
}
- (NSColor *)paleBackgroundColorFromColor:(NSColor *)aColor;
- (NSColor *)colorForRow:(int)rowIndex;
- (void)setHighlightColorForRow:(int)rowIndex;
- (void)setShouldChangeColor:(BOOL)aBool;
- (void)setShouldChangeColorWithoutDisplay:(BOOL)aBool;
- (void)setDefaultHighlightColor:(NSColor *)aColor;

- (void)animatedHighlightChangetoRow:(int)destionationRow;
- (void)animatedHighlightChangeStep:(NSTimer *)theTimer;
- (void)setShouldAnimateHighlight:(BOOL)aBool;
- (void)setAnimationTime:(float)time;
- (void)setAnimationFramesPerSecond:(float)fps;
- (BOOL)isAnimatingHighlight;
- (void)interuptHighlightAnimation;
- (void)setAcceptsMouseDown:(BOOL)aBool;
- (BOOL)acceptsMouseDown;
@end

@interface iTableColumnHeaderCell : NSTableHeaderCell {
    NSImage *metalBg;
    NSMutableDictionary *attrs;
}
@end

@interface NSObject(TSFunkyTableViewDataSourceMethods)
- (NSColor*)tableView:(NSTableView*)aTableView colorForRow:(int)aRow;

@end
