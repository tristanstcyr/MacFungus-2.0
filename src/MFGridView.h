/* MFGridView */

#import <Cocoa/Cocoa.h>
#import <MFGrid.h>

@interface MFGridViewCell : NSCell
{
	NSColor *color, *highlightColor,
			*topLeftCornerColor, *topRightCornerColor, 
			*bottomLeftCornerColor, *bottomRightCornerColor;
	NSImage *image;
	bool isHead,isHotCorner;
	bool isTouchingUp, isTouchingDown, isTouchingLeft, isTouchingRight;
}
- (NSColor*)color;
- (void)setColor:(NSColor *)aColor;
- (void)setImage:(NSImage*)anImage;
- (NSImage*)image;

- (void)setHighlightColor:(NSColor *)aColor;

- (BOOL)isTouchingUp;
- (BOOL)isTouchingDown;
- (BOOL)isTouchingLeft;
- (BOOL)isTouchingRight;
- (void)setIsTouchingUp:(BOOL)aBool;
- (void)setIsTouchingDown:(BOOL)aBool;
- (void)setIsTouchingLeft:(BOOL)aBool;
- (void)setIsTouchingRight:(BOOL)aBool;

- (void)setTopLeftCornerColor:(NSColor*)aColor;
- (void)setTopRightCornerColor:(NSColor*)aColor;
- (void)setBottomLeftCornerColor:(NSColor*)aColor;
- (void)setBottomRightCornerColor:(NSColor*)aColor;
- (NSColor*)topLeftCornerColor;
- (NSColor*)topRightCornerColor;
- (NSColor*)bottomLeftCornerColor;
- (NSColor*)bottomRightCornerColor;
@end

@interface MFGridView : NSMatrix
{
	NSTrackingRectTag trackingRectTag;
	pMFGrid currentGrid;
	pMFGrid highlightGrid;
	NSMutableDictionary *colorDict, *imageDict;
	NSImage *backgroundImage;
	NSMutableArray* cellsNeedingRedraw;
	
	//Animation
	bool isAnimating;
	bool isAcceptingInput;
	NSTimeInterval animInterval;
	NSArray *sounds;
	std::vector<std::vector<pMFGrid> > animationSequences;
}

- (id)initSquareGridWithFrame:(NSRect)frameRect numberOfRowsAndCols:(int)rowsAndCols;
- (NSImage*)backgroundImageInSize:(NSSize)aSize;

- (MFGrid)grid;
- (void)setAcceptsInput:(BOOL)aBool;
- (BOOL)acceptsInput;
- (void)setGrid:(MFGrid)aGrid;
- (void)setGridAndDisplay:(MFGrid)aGrid;
- (void)setHighlightGridAndDisplay:(MFGrid)aGrid;
- (void)addCellNeedingRedraw:(NSCell*)aCell;
- (void)drawCellsNeedingRedraw;
- (void)updateCellAtRow:(int)row column:(int)col;

- (NSColor*)colorForChar:(char)aChar;
- (void)setColor:(NSColor*)aColor forChar:(char)aChar;
- (NSImage*)imageForChar:(char)aChar;
- (void)setImage:(NSImage*)anImage forChar:(char)aChar;
- (void)animateWithSequences:(std::vector<std::vector<pMFGrid> >)sequences sounds:(NSArray*)sounds delay:(float)timeLapse;
- (void)threadAnimate;
- (BOOL)isAnimating;
@end

// The methods that the delegate should implement
@interface NSObject(MFGridViewDelegationMethods)
- (void)gridView:(id)aGridView mouseMovedOverRow:(int)row column:(int)col withEvent:(NSEvent*)anEvent;
- (void)gridView:(id)aGridView mouseDownOnRow:(int)row column:(int)col withEvent:(NSEvent*)anEvent;
- (void)gridView:(MFGridView*)aGridView rightMouseDownOnRow:(int)aRow column:(int)aCol;
- (void)gridView:(MFGridView*)aGridView scrollWheel:(NSEvent*)anEvent;
@end

@interface NSBezierPath(InverseArc)
- (void)appendInverseArcWithCenter:(NSPoint)centerPoint radius:(float)radius withAngle:(int)anAngle;
@end
@interface NSString(MFGridViewExtensions)
+ (NSString*)stringWithChar:(char)aChar;
@end