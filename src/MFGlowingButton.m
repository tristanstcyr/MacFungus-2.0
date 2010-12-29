#import "MFGlowingButton.h"
#import "math.h"

const float REG_INCR = 0.07, FAST_INCR = 0.2;
const NSTimeInterval timerDelay = 0.02;

@implementation MFGlowingButton

- (void)startGlowingWithColor:(NSColor*)aColor {
	_pulseIncrement = REG_INCR;
	_shouldStopGlowing = NO;
	if (_timer)
		return;
	_time = pi*3/2;
	_color = [aColor retain];
	_timer = [NSTimer scheduledTimerWithTimeInterval:timerDelay
											  target:self
											selector:@selector(advancePulse)
											userInfo:nil
											repeats:YES];
}

- (void)stopGlowing { 
	_pulseIncrement = (cos(_time) > 0 ? -FAST_INCR : FAST_INCR);
	_shouldStopGlowing = YES; 
}

- (void)advancePulse {
	_time += _pulseIncrement;
	_alpha = (sin(_time) + 1.1)/4;
	if (_shouldStopGlowing && _alpha < 0.05) {
		[_timer invalidate];
		_timer = nil;
		[_color release];
		_color = nil;
		_shouldStopGlowing = NO;
	}
	[self display];
}

- (void)drawRect:(NSRect)aRect {

	if (_color) {
		NSRect glowRect = [self bounds];
		glowRect.origin.y += 1.0;
		glowRect.origin.x += 1.0f;
		glowRect.size.height -= 3.0;
		NSImage *anImage = [[NSImage alloc] initWithSize:glowRect.size];
		[anImage lockFocus];
		[_color set];
		[NSBezierPath fillRect:NSMakeRect(0,0,glowRect.size.width,glowRect.size.height)];
		[anImage unlockFocus];
		[super drawRect:[self bounds]];
		[anImage drawInRect:glowRect
				   fromRect:NSZeroRect
				  operation:NSCompositeSourceOver 
				   fraction:_alpha];
	} else {
		[super drawRect:aRect];
	}
}

- (void)dealloc {
	[_color release];
	[super dealloc];
}

- (BOOL)isGlowing { return (_timer != nil); }

@end
