/* TSAnimatedSplitView */

#import <Cocoa/Cocoa.h>

@interface AnimatedSplitView : NSSplitView
{
	BOOL isSplitterAnimating;
}

- (void)setSplitterPosition:(float)newSplitterPosition animate:(BOOL)animate;
- (float)splitterPosition;
@end
