#import "MFPlayerCell.h"
#define MARGIN_TOP 9.0f
#define MARGIN_SIDES 7.0f
#define CIRCLE_DIAMETER 13.0f
@interface NSView(NSViewAdditions)
- (int)editedRow;
@end
@implementation MFPlayerCell

- (id)init
{
	if ([super init])
	{
		playerDict = nil;
		isColorCirclePressed = NO;
		circleHighlight = [[NSImage imageNamed:@"circlehighlight"] retain];
		[circleHighlight setFlipped:YES];
		fieldEditorRect.origin.x = MARGIN_SIDES;
		fieldEditorRect.origin.y = MARGIN_TOP - 1.0f;;
		return self;
		
	} else return nil;
}

- (id) nameAttributes
{
	id attributes;
	float fontSize = 12.0f;
	BOOL isAlive = [[playerDict objectForKey:@"blocks"] intValue] > 0;
	NSColor *fontColor = (isAlive ? [NSColor blackColor] : [[NSColor blackColor] colorWithAlphaComponent:0.4f]);
	//NSColor *fontColor = ([self isHighlighted]?[NSColor whiteColor]:[NSColor blackColor]);
	attributes = [[NSDictionary alloc] initWithObjectsAndKeys: 
		[NSFont fontWithName:@"Helvetica Bold" size:fontSize], NSFontAttributeName, 
		fontColor, NSForegroundColorAttributeName,
		[NSColor blackColor], NSStrokeColorAttributeName, nil];
	return attributes;
}

- (id)statsAttributesDimmed:(BOOL)areDimmed
{
	id attributes;
	float fontSize = 10.0f;
	float alpha = (areDimmed ? 0.5f:0.9f);
	
	NSColor *fontColor = [NSColor colorWithCalibratedRed:0.0f
												   green:0.0f
													blue:0.0f
												   alpha:alpha];
	
	attributes = [[NSDictionary alloc] initWithObjectsAndKeys: 
		[NSFont systemFontOfSize:fontSize], NSFontAttributeName, 
		fontColor, NSForegroundColorAttributeName, nil];
	
    return attributes;
}

- (void)setObjectValue:(NSDictionary *)dict 
{ 
	playerDict = dict;
}

- (void)setIsColorCircledPressed:(BOOL)aBool { isColorCirclePressed = aBool; }

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect smallerRect = cellFrame;
	NSRect coloredCircle;
	NSPoint nameOrigin;
	NSPoint statsOrigin;
	NSString *statsString;
	
	int selfRow = [(NSTableView*)controlView rowAtPoint:cellFrame.origin];
	
	// Reduce the drawing area with the margins
	smallerRect.origin.x += MARGIN_SIDES;
	smallerRect.origin.y += MARGIN_TOP;
	smallerRect.size.width -= MARGIN_SIDES*2;
	smallerRect.size.height -= MARGIN_TOP*2;
	
	if (selfRow != [controlView editedRow]) {
		//Name goes to the top
		NSString *name = [playerDict objectForKey:@"name"];
		nameOrigin.x = smallerRect.origin.x;
		nameOrigin.y = smallerRect.origin.y - smallerRect.size.height + 15.0f;
		[name drawAtPoint:nameOrigin withAttributes:[self nameAttributes]];
	}
	
	fieldEditorRect.size = NSMakeSize(cellFrame.size.width - (2*MARGIN_SIDES), 15.0f);
	
	statsString =  [NSString stringWithFormat:@"%@: %i %@: %i", NSLocalizedString(@"blocks", @"blocks"), [[playerDict objectForKey:@"blocks"] intValue],
		NSLocalizedString(@"bites", @"bites"), [[playerDict objectForKey:@"bites"] intValue]];
	statsOrigin.x = smallerRect.origin.x;
	statsOrigin.y = smallerRect.origin.y + smallerRect.size.height - 8.0f;
	[statsString drawAtPoint:statsOrigin withAttributes:[self statsAttributesDimmed:!([[playerDict objectForKey:@"showStats"] boolValue])]];
	
	// Colored circle goes justified right
	coloredCircle.origin.x = smallerRect.origin.x + smallerRect.size.width - CIRCLE_DIAMETER;
	// Minor adjustment needed for this one, no idea why
	coloredCircle.origin.y = smallerRect.origin.y + smallerRect.size.height - CIRCLE_DIAMETER*1.3f; 
	coloredCircle.size.width = coloredCircle.size.height = CIRCLE_DIAMETER;
	coloredCircleRect = coloredCircle;
	
	[[playerDict objectForKey:@"color"] set];
	[[NSBezierPath bezierPathWithOvalInRect:coloredCircle] fill];
	
	NSRect tempSrc = NSZeroRect;
    tempSrc.size = [circleHighlight size];
	
	// Just to make it fit snug
	coloredCircle.size.width -= 0.5f;
	coloredCircle.size.height -= 0.5f;
	
	[circleHighlight setFlipped:(isColorCirclePressed == NO)];
	[circleHighlight drawInRect:coloredCircle
					   fromRect:tempSrc
					  operation:NSCompositeSourceOver
					   fraction:0.8f];
}

- (NSRect)fieldEditorRect { return fieldEditorRect; }

NSRect circleRectFromCellFrame(NSRect cellFrame)
{
	NSRect coloredCircle, smallerRect = cellFrame;
	smallerRect.origin.x += MARGIN_SIDES;
	smallerRect.origin.y += MARGIN_TOP;
	smallerRect.size.width -= MARGIN_SIDES*2;
	smallerRect.size.height -= MARGIN_TOP*2;
	coloredCircle.origin.x = smallerRect.origin.x + smallerRect.size.width - CIRCLE_DIAMETER;
	coloredCircle.origin.y = smallerRect.origin.y + smallerRect.size.height - CIRCLE_DIAMETER*1.3f; 
	coloredCircle.size.width = coloredCircle.size.height = CIRCLE_DIAMETER;
	return coloredCircle;

}
- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag
{
	if (![controlView respondsToSelector:@selector(coloredCircleClicked:)])
		return NO;
		
	NSPoint eventLocation = [theEvent locationInWindow];
	NSPoint localPoint = [controlView convertPoint:eventLocation fromView:nil];
	coloredCircleRect = circleRectFromCellFrame(cellFrame);
	float maxX = coloredCircleRect.size.width + coloredCircleRect.origin.x,
		  minX = coloredCircleRect.origin.x,
		  maxY = coloredCircleRect.size.height + coloredCircleRect.origin.y,
		  minY = coloredCircleRect.origin.y;
	if (localPoint.x < maxX && localPoint.x > minX && localPoint.y < maxY && localPoint.y > minY) {
		[controlView performSelector:@selector(coloredCircleClicked:) withObject:theEvent]; 
		return YES;
	} else
		return NO;
}
@end

