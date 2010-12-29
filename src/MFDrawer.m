#import "MFDrawer.h"


@implementation MFDrawerFrame
- (void)drawRect:(NSRect)aRect { 
	
	NSRect newRect = [self frame];
	NSRect topRightRect, topMiddleRect, 
		bottomRightRect, bottomMiddleRect, drawerCenterRect;
	
	NSImage *topMiddle = [NSImage imageNamed:@"top_middle"],
		*topRight = [NSImage imageNamed:@"top_right"],
		*bottomMiddle = [NSImage imageNamed:@"bottom_middle"],
		*bottomRight = [NSImage imageNamed:@"bottom_right"];
	
	topRightRect.origin.x = newRect.origin.x + newRect.size.width - [topRight size].width;
	topRightRect.origin.y = newRect.origin.y + newRect.size.height - [topRight size].height;
	topRightRect.size = [topRight size];
	
	topMiddleRect.origin.x = newRect.origin.x;
	topMiddleRect.origin.y = newRect.origin.y + newRect.size.height - [topMiddle size].height;
	topMiddleRect.size.height = topRightRect.size.height;
	topMiddleRect.size.width = newRect.size.width - topRightRect.size.width;
	
	bottomRightRect.origin.x = newRect.origin.x + newRect.size.width - [bottomRight size].width;
	bottomRightRect.origin.y = newRect.origin.y;
	bottomRightRect.size = [bottomRight size];
	
	bottomMiddleRect.origin = newRect.origin;
	bottomMiddleRect.size.height = [bottomMiddle size].height;
	bottomMiddleRect.size.width = newRect.size.width - bottomRightRect.size.width;
	
	drawerCenterRect.size.width = newRect.size.width;
	drawerCenterRect.size.height = newRect.size.height - bottomMiddleRect.size.width - topMiddleRect.size.width;
	drawerCenterRect.origin.x = newRect.origin.x;
	drawerCenterRect.origin.y = newRect.origin.y /*+ bottomMiddleRect.size.height*/;

	[[self clippingPathInRect:newRect] setClip];
	[[NSColor lightGrayColor] set];
	NSRectFill(aRect);
	[topRight drawInRect:topRightRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
	[topMiddle drawInRect:topMiddleRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
	[[NSColor clearColor] set];
	//[NSBezierPath fillRect:bottomRightRect];
	[bottomRight drawInRect:bottomRightRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
	[bottomMiddle drawInRect:bottomMiddleRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
	
	[[[self subviews] objectAtIndex:0] setNeedsDisplay:YES];
}
                                                                        
+ (NSRect) frameRectForContentRect: (NSRect) contentRect styleMask: (unsigned) styleMask
{
	return NSInsetRect( contentRect, -11, -2.0 );
}

+ (NSRect) contentRectForFrameRect: (NSRect) frameRect styleMask: (unsigned) styleMask
{
	return NSInsetRect( frameRect, 0.0, 2.0 );
}

- (NSRect) contentRect
{
		// Inset from the drawer's outer bounds at the top and bottom, because the
		// content view must be fully opaque.
	return NSInsetRect( [self bounds], 0.0, 2.0 );
}

- (void) mouseDown: (NSEvent*) event
{
//	NSLog( @"-[NSDrawerFrame mouseDown:] here" );
	
		// For some reason, NSDrawerFrame's implementation of mouseDown: does nothing
		// when clicking in the drawer frame - probably because the content view extends
		// into the original frame -, so we override this method. The only difficulty is
		// that most mouseDowns are caught by other views, because we have no real frame.
	
	NSPoint mouse = [(NSView*)self convertPoint:[event locationInWindow] fromView:nil];
	NSRect bounds = [self bounds];
	
		// left edge
	NSRect rect = NSMakeRect( NSMinX(bounds), NSMinY(bounds), 9, NSHeight(bounds) );
	if ( NSPointInRect(mouse, rect) ) {
		if ( [self respondsToSelector:@selector(resizeWithEvent:)] ) {
			[self performSelector:@selector(resizeWithEvent:) withObject:event];
		}
	}
	
		// right edge
	rect = NSMakeRect( NSMaxX(bounds) - 9, NSMinY(bounds),
		9, NSHeight(bounds) );
	if ( NSPointInRect(mouse, rect) ) {
		if ( [self respondsToSelector:@selector(resizeWithEvent:)] ) {
			[self performSelector:@selector(resizeWithEvent:) withObject:event];
		}
	}
}
- (NSColor*) contentFill { return [NSColor clearColor]; }

- (NSBezierPath*)clippingPathInRect:(NSRect)aRect {
	/*
	 p2   p3       p4  p5                                                                                
	    +-+--------+-+                                                                                   
     p1 +-+        +-+ p6                                                                                
	    |            |                                                                                   
	    |            |                                                                                   
		|            |                                                                                   
	    |            |                                                                                   
	    |            |                                                                                   
	 p12+-+        +-+p7                                                                                 
	    +-+--------+-+                                                                                   
     p11 p10      p9  p8 */ 
	
	const float CORNER_RADIUS = 5.0;
	NSBezierPath *clipPath = [NSBezierPath bezierPath];
	int i;
	NSPoint p[12];
	p[0].x = p[1].x = p[11].x = p[10].x = aRect.origin.x;
	p[2].x = p[9].x = aRect.origin.x + CORNER_RADIUS;
	p[3].x = p[8].x = aRect.size.width + aRect.origin.x - CORNER_RADIUS;
	p[4].x = p[5].x = p[6].x = p[7].x = aRect.size.width + aRect.origin.x;
	p[1].y = p[2].y = p[3].y = p[4].y = aRect.origin.y + aRect.size.height;
	p[0].y = p[5].y = aRect.origin.y + aRect.size.height - CORNER_RADIUS;
	p[11].y = p[6].y = aRect.origin.y + CORNER_RADIUS;
	p[10].y = p[9].y = p[8].y = p[7].y = aRect.origin.y;
	/*
	[clipPath moveToPoint:p[0]];
	[clipPath appendBezierPathWithArcFromPoint:p[1] toPoint:p[2] radius:CORNER_RADIUS];
	[clipPath moveToPoint:p[3]];
	[clipPath appendBezierPathWithArcFromPoint:p[4] toPoint:p[5] radius:CORNER_RADIUS];
	[clipPath moveToPoint:p[6]];
	[clipPath appendBezierPathWithArcFromPoint:p[7] toPoint:p[8] radius:CORNER_RADIUS];
	[clipPath moveToPoint:p[9]];
	[clipPath appendBezierPathWithArcFromPoint:p[10] toPoint:p[11] radius:CORNER_RADIUS];*/
	[clipPath moveToPoint:p[0]];
	for (i = 0; i < 12; i++) {
		[clipPath lineToPoint:p[i]];
		[clipPath appendBezierPathWithArcFromPoint:p[++i] toPoint:p[++i] radius:CORNER_RADIUS];
	}
	[clipPath lineToPoint:p[0]];
	[clipPath closePath];
	return clipPath;
}

@end
@implementation NSDrawerWindow(hack)

- (id)initWithContentRect:(struct _NSRect)fp8 styleMask:(unsigned int)fp24 backing:(int)fp28 defer:(BOOL)fp32 drawer:(id)fp36 {

	[super initWithContentRect:fp8 styleMask:fp24 backing:fp28 defer:fp32];
	[self setOpaque:NO];
	return self;
}

@end
