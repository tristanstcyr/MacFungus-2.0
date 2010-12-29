#import <Cocoa/Cocoa.h>


@interface MFPlayerCell : NSActionCell {
	
	BOOL isColorCirclePressed;
	NSDictionary *playerDict;
	NSImage *circleHighlight;
	NSRect fieldEditorRect, coloredCircleRect;
}
- (id) nameAttributes;
- (id)statsAttributesDimmed:(BOOL)areDimmed;
- (void)setIsColorCircledPressed:(BOOL)aBool;
- (void)setObjectValue:(NSDictionary *)dict;
- (NSRect)fieldEditorRect;
NSRect circleRectFromCellFrame(NSRect cellFrame);

@end
