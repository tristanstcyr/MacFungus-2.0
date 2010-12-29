#import "MFPlayersTable.h"
#import "MFPlayerCell.h"
#import "CTGradient.h"

@implementation MFPlayersTable

- (id)initWithCoder:(NSCoder *)decoder
{	
	
	if (self = [super initWithCoder:decoder])
	{
		editedRow = -1;
		dropRow = -2;
		fieldEditor = nil;
		[self setDoubleAction:@selector(startEditingName:)];
		return self;
	} else return nil;
}

- (void)selectRow:(int)rowIndex byExtendingSelection:(BOOL)flag
{
	int newSelection = [self selectedRow];
	
	if (newSelection != rowIndex)
	{
		[[self window] makeFirstResponder:self];
		[super selectRow:rowIndex byExtendingSelection:flag];
	}	
}

- (void)coloredCircleClicked:(NSEvent*)theEvent
{
	if ([[self delegate] respondsToSelector:@selector(coloredCircleClicked)])
		[[self delegate] performSelector:@selector(coloredCircleClicked)];
}

- (void)mouseDown:(NSEvent*)anEvent {
	if (![self acceptsMouseDown]) {
		NSBeep(); return;
	}
	[super mouseDown:anEvent];
}

- (void)drawRect:(NSRect)aRect
{
	[super drawRect:aRect];
	if (fieldEditor != nil) {
        NSResponder *resp = [[self window] firstResponder];
        if ([[self window] isKeyWindow] &&
		[resp isKindOfClass:[NSView class]] &&
		[(NSView *)resp isDescendantOf:self]) {
            [NSGraphicsContext saveGraphicsState];
            NSSetFocusRingStyle(NSFocusRingOnly);
            NSRectFill([fieldEditor frame]);
            [NSGraphicsContext restoreGraphicsState];
		}
	}
	if (dropRow > -1) {
		[self drawDropHighlightBetweenUpperRow:dropRow-1 andLowerRow:dropRow];
	}
}

- (void)drawDropHighlightBetweenUpperRow:(int)upperRow andLowerRow:(int)lowerRow {
	const float highlightHeight = 3;
	float y;
	NSRect dropHighlightRect;
	if (upperRow > 0) {
		y =[self rectOfRow:upperRow].origin.y + [self rectOfRow:upperRow].size.height;
		NSLog(@"upper:%i", lowerRow);
	}
	else {
		y = [self rectOfRow:lowerRow].origin.y;
		NSLog(@"lower:%i", lowerRow);
	}
	
	NSLog(@"y:%f",y);
	dropHighlightRect.origin.x = 0;
	dropHighlightRect.origin.y = y;
	dropHighlightRect.size.height = highlightHeight;
	dropHighlightRect.size.width = [self frame].size.width;
	[[highlightColor blendedColorWithFraction:0.3f ofColor:[NSColor blackColor]] set];
	[NSBezierPath fillRect:dropHighlightRect];
}

- (void)startEditingName:(id)sender 
{
	
	int i, selectedRow = [self selectedRow];
	
	if (selectedRow < 0) 
		return;
		
	MFPlayerCell *aCell = [self cell];
	const NSSize feSize = NSMakeSize(100,15); 
	editedRow = selectedRow;
	NSString *playerName = [[[self dataSource] tableView:self 
							   objectValueForTableColumn:[[self tableColumns] objectAtIndex:0]
													 row:[self selectedRow]] objectForKey:@"name"];
	
	fieldEditor = (NSTextView *)[[self window] fieldEditor:YES forObject:self];
	[fieldEditor setDelegate:self];
    [fieldEditor setHorizontallyResizable:YES];
	[fieldEditor setVerticallyResizable:NO];
	
	// bug! can't figure out why I need to do this twice!
	for (i = 0; i < 2; i++) 
	{
		[fieldEditor setFrame:NSMakeRect(0,0,feSize.width, feSize.height)];
		[[fieldEditor textContainer] setContainerSize:feSize];
	}
	
	[[fieldEditor textContainer] setHeightTracksTextView:NO];
    [[fieldEditor textContainer] setWidthTracksTextView:NO];
	[fieldEditor setTextContainerInset:NSMakeSize(-4.0f, 0.0f)];
    
	[fieldEditor setString:playerName];
	[[fieldEditor textStorage] setAttributes:[aCell nameAttributes] range:NSMakeRange(0,[playerName length])];
	[fieldEditor setBackgroundColor:nil];
    [fieldEditor selectAll:self];
    
	[self addSubview:fieldEditor];
    [[self window] makeFirstResponder:fieldEditor];
	[self fixEditor];
}

- (void)fixEditor
{
	int selectedRow = [self selectedRow];
	MFPlayerCell *aCell = [[[self tableColumns] objectAtIndex:0] dataCellForRow:selectedRow];
	NSRect fieldEditorRect = [aCell fieldEditorRect];
	fieldEditorRect.origin.y -= 3.0f;
	fieldEditorRect.origin.y += ([self rowHeight])*selectedRow;
	[fieldEditor setFrameOrigin:fieldEditorRect.origin];
	[self setNeedsDisplay:YES];
}

- (void)textDidChange:(NSNotification *)notification { [self fixEditor]; }
- (int)editedRow { return editedRow; }

- (void)textDidEndEditing:(NSNotification *)aNotification
{	
	if ([[self dataSource] respondsToSelector:@selector(tableView:setObjectValue:forTableColumn:row:)])
		[[self dataSource] tableView:self setObjectValue:[fieldEditor string] forTableColumn:0 row:editedRow];
	
	[fieldEditor removeFromSuperview];
	[[self window] makeFirstResponder:nil];
	[self reloadData];
	fieldEditor = nil;
    editedRow = -1;
	
	[self setNeedsDisplay:YES];
}

//- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent { return YES; }

- (void)setDropRow:(int)row dropOperation:(NSTableViewDropOperation)operation {
	dropRow = row;
	[super setDropRow:row dropOperation:operation];
}

- (void)concludeDragOperation:sender {
	dropRow = -2;
	[self setNeedsDisplay:YES];
	[super concludeDragOperation:sender];
}
- (void)draggingExited:(id <NSDraggingInfo>)sender {

	dropRow = -2;
	[self setNeedsDisplay:YES];
	[super draggingExited:sender];
}

@end
