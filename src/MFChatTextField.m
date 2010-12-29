#import "MFChatTextField.h"

@implementation MFChatTextField
- (id)initWithCoder:(NSCoder*)coder {
    if (self = [super initWithCoder:coder]) {
	NSTextFieldCell *oldCell = [self cell];
	MFChatTextFieldCell *myCell = [[MFChatTextFieldCell alloc] init];
	[myCell setAlignment:[oldCell alignment]];
	[myCell setFont:[oldCell font]];
	[myCell setControlSize:[oldCell controlSize]];
	[myCell setControlTint:[oldCell controlTint]];
	[myCell setEnabled:[oldCell isEnabled]];
	[myCell setBordered:[oldCell isBordered]];
	[myCell setBezeled:[oldCell isBezeled]];
	[myCell setBezelStyle:[oldCell bezelStyle]];
	[myCell setSelectable:[oldCell isSelectable]];
	[myCell setContinuous:[oldCell isContinuous]];
	[myCell setSendsActionOnEndEditing:[oldCell sendsActionOnEndEditing]];
	[myCell setEditable:[oldCell isEditable]];
	[myCell setTarget:[oldCell target]];
	[myCell setAction:[oldCell action]];
	[myCell setFont:[NSFont systemFontOfSize:12]];
	[self setCell:myCell];
	[myCell release];
	[self setAllowsEditingTextAttributes:YES];
	} else return nil;
	
	return self;
}

@end
@implementation MFChatTextFieldCell
const float INSET = 10;
+ (NSDictionary *)defaultAttributes
{
	NSFont *font = [NSFont systemFontOfSize:12.0];
	NSMutableParagraphStyle *pStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:NULL] autorelease];
	//[pStyle setFirstLineHeadIndent:INSET];
	[pStyle setLineSpacing:5];
	//[pStyle setHeadIndent:INSET];						
	
	return [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, pStyle, NSParagraphStyleAttributeName, NULL];
}

- (void)setStringValue:(NSString*)aString {
	NSAttributedString *AttString = [[NSAttributedString alloc] initWithString:aString];
	[self setAttributedStringValue:AttString];
	[AttString release];
}

- (void)setAttributedStringValue:(NSAttributedString *)attribStr {
	NSAttributedString *AttString = [[NSAttributedString alloc] initWithString:[attribStr string] attributes:[MFChatTextFieldCell defaultAttributes]];
	[super setAttributedStringValue:AttString];
	[AttString release];
}

- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj {
	NSTextView *fieldEditor = (NSTextView*)textObj;
	[fieldEditor setTextContainerInset:NSMakeSize(INSET,0)];
	[fieldEditor setString:[self stringValue]];
	return fieldEditor;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:cellFrame];
	cellFrame.origin.x += INSET;
	[super drawInteriorWithFrame:cellFrame inView:controlView];

}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {

   // showsFirstResponder is set for us by the NSControl that is drawing  us.  
	if ([self showsFirstResponder]) {     
		//We don't want a focus ring
		NSRect focusRingFrame = NSZeroRect;
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        [[NSBezierPath bezierPathWithRect:focusRingFrame] fill];
        [NSGraphicsContext restoreGraphicsState];
	}

	// other stuff might happen here
	 [self drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
