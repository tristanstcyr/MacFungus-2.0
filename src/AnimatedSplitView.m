#import "AnimatedSplitView.h"


@implementation AnimatedSplitView

- (void)setSplitterPosition:(float)newSplitterPosition animate:(BOOL)animate {
	if ([[self subviews] count] < 2)
		return;
	
	NSView *subview0 = [[self subviews] objectAtIndex:0];
	NSView *subview1 = [[self subviews] objectAtIndex:1];
	
	NSRect subview0EndFrame = [subview0 frame];
	NSRect subview1EndFrame = [subview1 frame];
	
	if ([self isVertical]) {
		subview0EndFrame.size.width = newSplitterPosition;
		
		subview1EndFrame.origin.x = newSplitterPosition + [self dividerThickness];
		subview1EndFrame.size.width = [self frame].size.width - subview0EndFrame.size.width - [self dividerThickness];
	} else {
		subview0EndFrame.size.height = newSplitterPosition;
		
		subview1EndFrame.origin.y = newSplitterPosition + [self dividerThickness];
		subview1EndFrame.size.height = [self frame].size.height - subview0EndFrame.size.height - [self dividerThickness];
	}
	
	// Be sure the subview isn't hidden from a previous animation.
	[subview0 setHidden:NO];
	[subview1 setHidden:NO];
	
	// Update subviewEndFrame.origin so that the frame is positioned
	if (animate) {
		NSDictionary *subview0Animation = [NSDictionary dictionaryWithObjectsAndKeys:
			subview0, NSViewAnimationTargetKey,
			[NSValue valueWithRect:subview0EndFrame], NSViewAnimationEndFrameKey, nil];
		NSDictionary *subview1Animation = [NSDictionary dictionaryWithObjectsAndKeys:
			subview1, NSViewAnimationTargetKey,
			[NSValue valueWithRect:subview1EndFrame], NSViewAnimationEndFrameKey, nil];
		
		NSViewAnimation *animation = [[NSViewAnimation alloc]
initWithViewAnimations:[NSArray arrayWithObjects:subview0Animation,
	subview1Animation, nil]];
		
		[animation setAnimationBlockingMode:NSAnimationBlocking];
		[animation setDuration:0.3];
		// Use default animation curve, NSAnimationEaseInOut.
		
		isSplitterAnimating = YES;
		[animation startAnimation];
		isSplitterAnimating = NO;
		
		[animation release];
	} else {
		[subview0 setFrame:subview0EndFrame];
		[subview1 setFrame:subview1EndFrame];
	}
	[self adjustSubviews];
}

- (float)splitterPosition {
	if ([self isVertical])
		return [self frame].size.width - [[[self subviews] objectAtIndex:0] frame].size.width;
	else
		return [self frame].size.height - [[[self subviews] objectAtIndex:0] frame].size.height;
}

- (BOOL)isSplitterAnimating { return isSplitterAnimating; }

- (void)drawDividerInRect:(NSRect)aRect {
	NSImage *divImg = [NSImage imageNamed:@"divider"];
	[divImg drawInRect:aRect
	fromRect:NSZeroRect
	operation:NSCompositeSourceOver
	fraction:1.0f];
}
@end
