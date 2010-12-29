#import <Cocoa/Cocoa.h>

@interface TSTimedProgressIndicatorLCDCell : NSCell { 
	NSImage *leftCap, *rightCap, *middle;
}
- (void)drawInteriorWithFrame:(NSRect)cellFrame withProgress:(float)fraction;
@end

@interface TSTimedProgressIndicator : NSView {
	BOOL _shouldStop;
	float fraction;
	id _delegate;
	NSRect cellFrame;
	NSTimer *timer;
	NSTimeInterval _timeInverval;
	TSTimedProgressIndicatorLCDCell *cell;
}
- (void)setFractionAndDisplay:(float)aFloat;
- (void)startClockForTime:(NSTimeInterval)timeInterval;
- (void)stop;
- (void)resume;
- (void)setDelegate:(id)anObject;
@end