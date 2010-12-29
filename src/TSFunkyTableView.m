#import "TSFunkyTableView.h"
#import "MFPlayerCell.h"
#import "CTGradient.h"

@implementation TSFunkyTableView

#pragma mark -

#pragma mark Laundry

#define ANIM_FPS 0.02f
#define ANIM_TIME 0.5f
#define DEF_HI_COLOR [NSColor colorWithCalibratedRed:162.0f/255.0f green:183.0f/255.0f blue:207.0f/255.0f alpha:1.0f]
- (id)initWithCoder:(NSCoder *)decoder
{	
	if (self = [super initWithCoder:decoder])
	{
		// Set defaults
		isAnimatingHighlight = shouldAnimateHighlight = NO;
		acceptsMouseDown = YES;
		animationTime = ANIM_TIME;
		animationFPS = ANIM_FPS;
		defaultHighlightColor = highlightColor = [DEF_HI_COLOR retain];
		[self selectRow:0 byExtendingSelection:NO];	
		
		/* Set all columns of tableView to use an iTableColumnHeaderCell as their headerCell. */
		NSArray *columns = [self tableColumns];
		NSEnumerator *cols = [columns objectEnumerator];
		NSTableColumn *col = nil;
		iTableColumnHeaderCell *iHeaderCell;
		highlightRect = [self rectOfRow:[self selectedRow]];
		while (col = [cols nextObject]) {
			iHeaderCell = [[iTableColumnHeaderCell alloc] initTextCell:[[col headerCell] stringValue]];
			[col setHeaderCell:iHeaderCell];
			[iHeaderCell release];
		}
		
		return self;
		
	} else return nil;
}

- (void)awakeFromNib
{
	highlightRect = [self rectOfRow:[self selectedRow]];
	highlightColor = [[self colorForRow:[self selectedRow]] retain];
}

- (void)dealloc 
{
	[highlightColor release];
	[defaultHighlightColor release];
	[super dealloc];
}

#pragma mark -

#pragma mark Selection

/*
- (void)mouseDown:(NSEvent*)anEvent
{
	if (![self acceptsMouseDown]) { 
		NSBeep();
		return;
	}
	
	NSPoint convertedPoint = [self convertPoint:[anEvent locationInWindow] toView:nil];
	int clickCount = [anEvent clickCount], 
			   row = [self rowAtPoint:convertedPoint],
			   col = 0; //Bug! return -1 even though it is in the column 0
	
	if(row >= 0 && col >= 0) 
	{
		NSCell *cell = [[[self tableColumns] objectAtIndex:col] dataCellForRow:row];
		NSRect cellFrame = [self frameOfCellAtColumn:col row:row];

		if (![cell trackMouse:anEvent inRect:cellFrame ofView:self untilMouseUp:YES] && clickCount == 2)
			[self performSelector:[self doubleAction]];
	}
	if (row >= 0)
		[self selectRow:row byExtendingSelection:NO];
	else
		[self deselectAll:self];
}
*/
- (void)selectRow:(int)rowIndex byExtendingSelection:(BOOL)flag 
{
	if (shouldAnimateHighlight) {
		[self animatedHighlightChangetoRow:rowIndex];
	} else {
		[self setHighlightColorForRow:rowIndex];
		[self setNeedsDisplayInRect:highlightRect];
		highlightRect = [self rectOfRow:rowIndex];
		[self setNeedsDisplayInRect:highlightRect];
	}
	[super selectRow:rowIndex byExtendingSelection:NO];
}

// To be implemented elegantly
- (void)deselectAll:(id)sender { 
	[super deselectAll:sender];
	[self animatedHighlightChangetoRow:-1];
}

- (void)setAcceptsMouseDown:(BOOL)aBool { acceptsMouseDown = aBool; }
- (BOOL)acceptsMouseDown { return acceptsMouseDown; }


#pragma mark -

#pragma mark Drawing

- (NSColor *)paleBackgroundColorFromColor:(NSColor *)aColor
{
	return [aColor blendedColorWithFraction:0.6f ofColor:[NSColor whiteColor]];
}

- (void)drawRect:(NSRect)aRect
{
	// Draw the background
	NSColor *backgroundColor = [self paleBackgroundColorFromColor:highlightColor];
	CTGradient *backgroundGradient = [CTGradient gradientWithBeginningColor:[self paleBackgroundColorFromColor:backgroundColor] endingColor:backgroundColor];
	
	[backgroundGradient fillRect:[self frame] angle:90.0f];
	
	// Draw the highlight
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	NSRect highlightContour;
	NSColor *highlightPale = [highlightColor blendedColorWithFraction:0.4f ofColor:[NSColor whiteColor]];
	CTGradient *highlightGradient = [CTGradient gradientWithBeginningColor:highlightPale endingColor:highlightColor];
	highlightRect.size.width = [self frame].size.width;
	highlightRect.size.height = [self rowHeight];
	highlightContour = highlightRect;
	highlightContour.size.width += 10.0f;
	highlightContour.size.height -= 1.0f;
	highlightContour.origin.y += 1.0f;
	highlightContour.origin.x -= 5.0f;
	
	[highlightColor set];
	[highlightGradient fillRect:highlightRect angle:90.0f];
	
	
	[NSBezierPath setDefaultLineWidth:0.1f];
	[NSBezierPath strokeRect:highlightContour];
	[[NSGraphicsContext currentContext] setShouldAntialias:YES];
	
	// Draw every row's cells
	unsigned int i, rows = [self numberOfRows];
	for (i=0; i < rows; i++)
		[self drawRow:i clipRect:[self frame]];
}

// Overidden so we get no highlight from the NSTableView super class
- (id)_highlightColorForCell:(NSCell *)cell { return nil;}


#pragma mark -

#pragma mark Change Color of Rows

- (NSColor *)colorForRow:(int)rowIndex
{
	//Asks the delegate for the color
	//If the delegate does not respond to selector then use default
	
	if ([[self delegate] respondsToSelector:@selector(tableView:colorForRow:)] && shouldChangeColor && rowIndex != -1) {
		return [[self delegate] tableView:self colorForRow:rowIndex];
	
	} else
		return defaultHighlightColor;
}

- (void)setHighlightColorForRow:(int)rowIndex
{
	if (highlightColor != defaultHighlightColor)
		[highlightColor release];
		
	highlightColor = [[self colorForRow:rowIndex] retain];
}

- (void)setShouldChangeColor:(BOOL)aBool 
{ 
	shouldChangeColor = aBool;
	[self setHighlightColorForRow:[self selectedRow]];
	[self display];
}

- (void)setShouldChangeColorWithoutDisplay:(BOOL)aBool { shouldChangeColor = aBool; }


- (void)setDefaultHighlightColor:(NSColor *)aColor
{
	[defaultHighlightColor release];
	defaultHighlightColor = [aColor retain];
}


#pragma mark -


#pragma mark Animation

- (NSRect)rectOfRow:(int)aRow 
{
	if (aRow < 0) {
		NSRect hiddenRect;
		hiddenRect.origin.x = 0;
		hiddenRect.origin.y = -[self rowHeight];
		hiddenRect.size.height = [self rowHeight];
		hiddenRect.size.height = [self frame].size.width;
		return hiddenRect;
	} else 
		return [super rectOfRow:aRow];
}

- (void)animatedHighlightChangetoRow:(int)destinationRow
{
	NSRect finalHighlightRect = [self rectOfRow:destinationRow];
	NSColor *destinationColor = [self colorForRow:destinationRow];
	
	[self interuptHighlightAnimation];

	// AnimArray is used to remember the destination rect, frame and destination row
	NSMutableArray *animArray = 
		[NSMutableArray arrayWithObjects:[NSValue valueWithRect:finalHighlightRect],
			[NSNumber numberWithFloat:0.0f], 
			[NSNumber numberWithInt:destinationRow],
			destinationColor, nil];
	isAnimatingHighlight = YES;
	animationTimer = [NSTimer scheduledTimerWithTimeInterval:ANIM_FPS
													  target:self
													selector:@selector(animatedHighlightChangeStep:)
													userInfo:animArray
													 repeats:YES];
}

- (void)animatedHighlightChangeStep:(NSTimer *)theTimer
{
	NSMutableArray *animArray = [theTimer userInfo];
	NSRect finalRect = [[animArray objectAtIndex:0] rectValue];
	float frame = [[animArray objectAtIndex:1] floatValue];
	NSColor *destinationColor = [animArray objectAtIndex:3], *currentColorMix;
	
	float move = (finalRect.origin.y - highlightRect.origin.y)*frame; // length we're moving this frame
	
	frame += 1.0f/(animationTime / ANIM_FPS); // advance time
	
	// Make sure we don't go too far in the decimals
	if (frame > 1.0f || fabs((finalRect.origin.y - highlightRect.origin.y)*frame) < 0.1f) 
	{ 
		[theTimer invalidate];
		highlightRect.origin.y = finalRect.origin.y;
		isAnimatingHighlight = NO;
		
	} else {
		highlightRect.origin.y += move;
		highlightRect.size = finalRect.size;
		
		[animArray replaceObjectAtIndex:1 withObject:[NSNumber numberWithFloat:frame]];
	}
	
	currentColorMix = [highlightColor blendedColorWithFraction:frame ofColor:destinationColor];
	[highlightColor release];
	highlightColor = [currentColorMix retain];
	
	if (isAnimatingHighlight)
		[self setBackgroundColor:[self paleBackgroundColorFromColor:highlightColor]];
	[self setNeedsDisplay:YES];
	//[self setNeedsDisplayInRect:origHRect];
	//[self setNeedsDisplayInRect:highlightRect];
}

- (BOOL)isAnimatingHighlight { return (isAnimatingHighlight && animationTimer != nil);}

- (void)interuptHighlightAnimation 
{ 
	if ([self isAnimatingHighlight]) 
	{
		[animationTimer invalidate];
		animationTimer = nil;
	}
	isAnimatingHighlight = NO; 
}

- (void)setShouldAnimateHighlight:(BOOL)aBool { shouldAnimateHighlight = aBool; }
- (void)setAnimationTime:(float)time { animationTime = time; }
- (void)setAnimationFramesPerSecond:(float)fps { animationFPS = fps; }

@end

#pragma mark -

#pragma mark Metallic Headers

// Metallic Header Cell Class
//  Created by Matt Gemmell on Thu Feb 05 2004.
//  <http://iratescotsman.com/>

@implementation iTableColumnHeaderCell


- (id)initTextCell:(NSString *)text
{
    if (self = [super initTextCell:text]) {
        metalBg = [[NSImage imageNamed:@"metal_column_header.png"] retain];
        if (text == nil || [text isEqualToString:@""]) {
            [self setTitle:@"Title"];
        }
        [metalBg setFlipped:YES];
        attrs = [[NSMutableDictionary dictionaryWithDictionary:
                                        [[self attributedStringValue] 
                                                    attributesAtIndex:0 
                                                    effectiveRange:NULL]] 
                                                        mutableCopy];
        return self;
    }
    return nil;
}


- (void)dealloc
{
    [metalBg release];
    [attrs release];
    [super dealloc];
}


- (void)drawWithFrame:(NSRect)inFrame inView:(NSView*)inView
{
    /* Draw metalBg lowest pixel along the bottom of inFrame. */
    NSRect tempSrc = NSZeroRect;
    tempSrc.size = [metalBg size];
    tempSrc.origin.y = tempSrc.size.height - 1.0;
    tempSrc.size.height = 1.0;
    
    NSRect tempDst = inFrame;
    tempDst.origin.y = inFrame.size.height - 1.0;
    tempDst.size.height = 1.0;
    
    [metalBg drawInRect:tempDst 
               fromRect:tempSrc 
              operation:NSCompositeSourceOver 
               fraction:1.0];
    
    /* Draw rest of metalBg along width of inFrame. */
    tempSrc.origin.y = 0.0;
    tempSrc.size.height = [metalBg size].height - 1.0;
    
    tempDst.origin.y = 1.0;
    tempDst.size.height = inFrame.size.height - 2.0;
    
    [metalBg drawInRect:tempDst 
               fromRect:tempSrc 
              operation:NSCompositeSourceOver 
               fraction:1.0];
    
    /* Draw white text centered, but offset down-left. */
    float offset = 0.5;
    [attrs setValue:[NSColor colorWithCalibratedWhite:1.0 alpha:0.7] 
             forKey:@"NSColor"];
    
    NSRect centeredRect = inFrame;
    centeredRect.size = [[self stringValue] sizeWithAttributes:attrs];
    centeredRect.origin.x += 
        ((inFrame.size.width - centeredRect.size.width) / 2.0) - offset;
    centeredRect.origin.y = 
        ((inFrame.size.height - centeredRect.size.height) / 2.0) + offset;
    [[self stringValue] drawInRect:centeredRect withAttributes:attrs];
    
    /* Draw black text centered. */
    [attrs setValue:[NSColor blackColor] forKey:@"NSColor"];
    centeredRect.origin.x += offset;
    centeredRect.origin.y -= offset;
    [[self stringValue] drawInRect:centeredRect withAttributes:attrs];
}

- (id)copyWithZone:(NSZone *)zone
{
    id newCopy = [super copyWithZone:zone];
    [metalBg retain];
    [attrs retain];
    return newCopy;
}

@end