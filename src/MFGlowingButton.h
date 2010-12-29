#include <Cocoa/Cocoa.h>

@interface MFGlowingButton : NSButton {
	NSTimer *_timer;
	NSColor* _color;
	double _time, _alpha;
	float _pulseIncrement;
	bool _isGlowing, _shouldStopGlowing;
}

- (void)startGlowingWithColor:(NSColor*)aColor;
- (void)stopGlowing;
- (BOOL)isGlowing;
@end
