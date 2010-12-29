#import "TSTimedProgressIndicator.h"


@implementation TSTimedProgressIndicator
const NSTimeInterval frameDrawInterval = 0.04f;
const float FRACTION_BASE = 100.0f;

- (void)setDelegate:(id)anObject { _delegate = anObject; }
- (id)delegate { return _delegate; };

- (void)awakeFromNib {
	fraction = 0;
	_delegate = nil;
	timer = nil;
	cell = [[TSTimedProgressIndicatorLCDCell alloc] init];
	cellFrame = [self bounds];
}

- (void)dealloc {
	[cell release];
	[super dealloc];
}

- (void)setFractionAndDisplay:(float)aFloat {
	fraction = aFloat;
	[self display];
}

- (void)stop { 
	_shouldStop = YES; 
	while(timer) 
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];//bug! will block forever if there's nothing in the loop...
}

- (void)resume {
	if (fraction >= FRACTION_BASE) {
		[self startClockForTime:_timeInverval];
		return;
	}
	[self stop];
	_shouldStop = NO;
	[NSThread detachNewThreadSelector:@selector(threadedStartClock) toTarget:self withObject:nil];

}

- (void)startClockForTime:(NSTimeInterval)aTimeInterval {
	[self stop];
	_shouldStop = NO;
	_timeInverval = aTimeInterval;
	[self setFractionAndDisplay:0];
	[NSThread detachNewThreadSelector:@selector(threadedStartClock) toTarget:self withObject:nil];
}

- (void)threadedStartClock {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	const float fractionStep = FRACTION_BASE/_timeInverval*frameDrawInterval;
	timer = [NSTimer timerWithTimeInterval:frameDrawInterval 
											 target:self
										   selector:@selector(advanceFraction:)
										   userInfo:[NSNumber numberWithDouble:fractionStep]
											repeats:YES];
	[runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
	[runLoop run];
	[pool release];
}

- (void)advanceFraction:(NSTimer*)aTimer {
	float fractionStep = [[aTimer userInfo] floatValue];
	fraction += fractionStep;
	if (_shouldStop) {
		[aTimer invalidate];
		timer = nil;
		return;
	} else if (FRACTION_BASE - fraction <= fractionStep) {
		id delegate = [self delegate];
		SEL delegateMethod = @selector(progressClockIndicatorDidEndAnimation:);
		fraction = FRACTION_BASE;
		[aTimer invalidate];
		timer = nil;
		[self display];
		if ([delegate respondsToSelector:delegateMethod])
			[delegate performSelectorOnMainThread:delegateMethod withObject:self waitUntilDone:NO];
	}
	
	[self display];
}
- (void)drawRect:(NSRect)aRect 
{
	[cell drawInteriorWithFrame:cellFrame withProgress:fraction];
}

/* Round clock
- (void)drawRect:(NSRect)aRect 
{
	NSBezierPath *background, *stroke, *arm = [NSBezierPath bezierPath];
	NSColor *color = [NSColor colorWithCalibratedWhite:0.4f alpha:1.0f];
	const float strokeInset = 1.5f;
	float armAngle = -fraction/FRACTION_BASE*360 + 90;
	NSPoint center;
	NSRect frame, smallerRect;
	frame = smallerRect = [self bounds];
	
	smallerRect.size.width -= strokeInset*2;
	smallerRect.size.height -= strokeInset*2;
	smallerRect.origin.x += strokeInset;
	smallerRect.origin.y += strokeInset;
	
	
	center.x = smallerRect.origin.x + smallerRect.size.width/2;
	center.y = smallerRect.origin.y + smallerRect.size.height/2;
	if (armAngle != 90) {
	[arm appendBezierPathWithArcWithCenter:center
									radius:smallerRect.size.width/2
								startAngle:90 
								  endAngle:armAngle
								  clockwise:YES];
	[arm lineToPoint:center];
	[arm closePath];
	}
	stroke = [NSBezierPath bezierPathWithOvalInRect:smallerRect];
	background = [NSBezierPath bezierPathWithOvalInRect:smallerRect];
	
	[[NSColor whiteColor] set];
	[background fill];
	[color set];
	[stroke setLineWidth:2.0f];
	[stroke stroke];
	[arm fill];
	
}*/
@end

@implementation TSTimedProgressIndicatorLCDCell

- (id) init {
	self = [super init];
	if (self != nil) {
		leftCap = [[NSImage imageNamed:@"lcdleftcap"] retain],
		rightCap = [[NSImage imageNamed:@"lcdrightcap"] retain],
		middle = [[NSImage imageNamed:@"lcdmiddle"] retain];
	}
	return self;
}

- (void)release {
	[leftCap release];
	[rightCap release];
	[middle release];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame withProgress:(float)fraction {
	NSRect leftCapRect, rightCapRect, middleRect, progressRect;
	
	leftCapRect.origin = NSZeroPoint;
	leftCapRect.size = [leftCap size];
	[leftCap drawInRect:leftCapRect
				fromRect:NSZeroRect
			  operation:NSCompositeSourceOver
			  fraction:1.0f];
	
	rightCapRect.origin.x = cellFrame.size.width - [rightCap size].width;
	rightCapRect.origin.y = 0;
	rightCapRect.size = [leftCap size];
	[rightCap drawInRect:rightCapRect
				fromRect:NSZeroRect
			  operation:NSCompositeSourceOver
			  fraction:1.0f];
	
	middleRect.origin.x = [leftCap size].width;
	middleRect.origin.y = 0;
	middleRect.size.width = cellFrame.size.width - [rightCap size].width - [leftCap size].width;
	middleRect.size.height = [leftCap size].height;
	[middle drawInRect:middleRect
				fromRect:NSZeroRect
			  operation:NSCompositeSourceOver
			  fraction:1.0f];
	
	if (fraction > 0.0f) {
		progressRect.origin = NSMakePoint(2.0f,3.0f);
		progressRect.size.height = middleRect.size.height - 6.0f;
		progressRect.size.width = (cellFrame.size.width - 3.0f)*fraction/FRACTION_BASE;
		[[NSColor colorWithCalibratedWhite:0.0f alpha:0.4f] set];
		[NSBezierPath fillRect:progressRect];
	}
}
@end