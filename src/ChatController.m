#import "ChatController.h"
@implementation ChatController

- (void)awakeFromNib {
	// Make the text views inset so they do not appear under the window
	const NSSize textInset = NSMakeSize(7,2);
	[chatTextView setTextContainerInset:textInset];
	[chatTextField setDelegate:self];
	[chatTextField setStringValue:@""];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self 
		   selector:@selector(textDidChange:)
			   name:NSControlTextDidChangeNotification 
			 object:chatTextField];
}

- (IBAction)submitTextField:(id)sender
{
	// Sent by the text field when the return key is pressed
	NSString *fieldString = [sender stringValue];
	[sender setStringValue:@""];
	[self textDidChange:nil];
	[[sender window] makeFirstResponder:sender];
	[self postSystemMessage:fieldString];
}

- (IBAction)toggleDrawer:(id)sender {
	[drawer toggle:sender];
	NSImage *buttonImage = 
		[NSImage imageNamed:([drawer state] == NSDrawerOpenState || 
			[drawer state] == NSDrawerOpeningState ? @"chatdrawerout" : @"chatdrawerin")];
	[drawerButton setImage:buttonImage];
}

- (void)setChatEnabled:(BOOL)aBool {
	[drawerButton setEnabled:aBool];
	int drawerState = [drawer state];;
	if (!aBool && drawerState == NSDrawerOpeningState || drawerState == NSDrawerOpenState)
		[drawer close];

}

- (void)postMessage:(NSString*)msgStr fromName:(NSString*)nameStr {
	if ([msgStr length] == 0 || [nameStr length] == 0)
		return;
	NSAttributedString *attNameStr, *attMsgStr;
	attNameStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@: ", nameStr] 
												 attributes:[ChatController chatNameAttributes]];
	attMsgStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", msgStr]
												attributes:[ChatController chatMessageAttributes]];
	[[chatTextView textStorage] appendAttributedString:attNameStr];
	[[chatTextView textStorage] appendAttributedString:attMsgStr];
	[chatTextView scrollRangeToVisible:NSMakeRange([[chatTextView textStorage] length], 1)];
}

- (void)postSystemMessage:(NSString*)msgString {
	NSAttributedString *msgAttStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@: ", msgString] 
												 attributes:[ChatController systemMessageAttributes]];
	[[chatTextView textStorage] appendAttributedString:msgAttStr];
}

- (void)textDidChange:(NSNotification *)aNotification {
	[chatTextView scrollRangeToVisible:NSMakeRange([[chatTextView textStorage] length], 1)];
	[chatTextField sizeToFit];
}



- (void)clearChatView { [chatTextView setString:@""]; }

- (void)setDelegate:(id)anObject { delegate = anObject; };
- (id)delegate { return delegate; }
- (void)clearChatTextView { [chatTextView setString:@""]; }
/*- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
	NSLog(@"!");
}*/
- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
	[chatTextField sizeToFit];

}

+ (NSDictionary *)chatNameAttributes
{
	NSFont *font = [NSFont fontWithName:@"Lucida Grande" size:10.0];
	font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
       
	NSMutableParagraphStyle *pStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:NULL] autorelease];
	[pStyle setLineBreakMode:NSLineBreakByWordWrapping];
	[pStyle setLineSpacing:1.8];
	[pStyle setParagraphSpacing:1.0];
	[pStyle setParagraphSpacingBefore:1.0];										
	
	return [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, 
													    pStyle , NSParagraphStyleAttributeName, NULL];
}

+ (NSDictionary *)chatMessageAttributes
{
	NSFont *font = [NSFont fontWithName:@"Lucida Grande" size:10.0];
	NSColor *color = [NSColor blackColor];
	
	NSMutableParagraphStyle *pStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:NULL] autorelease];
	[pStyle setLineBreakMode:NSLineBreakByWordWrapping];
	[pStyle setLineSpacing:1.8];
	[pStyle setParagraphSpacing:1.0];
	[pStyle setParagraphSpacingBefore:1.0];
	
	return [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, 
													   color, NSForegroundColorAttributeName, 
													    pStyle , NSParagraphStyleAttributeName, NULL];
}

+ (NSDictionary *)systemMessageAttributes
{
	NSFont *font = [NSFont fontWithName:@"Lucida Grande" size:10.0];
	font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSItalicFontMask];
	NSColor *color = [NSColor grayColor];
	
	NSMutableParagraphStyle *pStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:NULL] autorelease];
	[pStyle setLineBreakMode:NSLineBreakByWordWrapping];
	[pStyle setLineSpacing:1];
	[pStyle setParagraphSpacing:1.0];
	[pStyle setParagraphSpacingBefore:1.0];
	return [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, 
													   color, NSForegroundColorAttributeName, 
													    pStyle , NSParagraphStyleAttributeName, NULL];
}

@end
@implementation AnimatedSplitView(undraggable)
// Make splitview unmanipulable
- (void)mouseMoved:(NSEvent*)anEvent {}
- (void)mouseDown:(NSEvent*)anEvent {}
- (void)resetCursorRects { }
- (void)resetCursorRect:(NSRect)cellFrame inView:(NSView *)controlView { }

@end
@implementation NSTextField(sizeToFit)

- (void)sizeToFit {
	// Resize the textfield to fit its contents
	const float minSize = 17;
	NSTextView *textView = (NSTextView *)[[self window] fieldEditor:YES forObject:self];
	NSRect newFrame = [self frame];
	NSSize approxSize = [[textView layoutManager] usedRectForTextContainer:[textView textContainer]].size;
	if (approxSize.height < minSize || [[self stringValue] length] == 0)
		approxSize.height = minSize;
	newFrame.size.height = approxSize.height + 5;
	[self setFrame:newFrame];

	[self display];
}
@end