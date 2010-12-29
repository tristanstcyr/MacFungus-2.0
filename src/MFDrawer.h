/* CustomDrawer */

#import <Cocoa/Cocoa.h>
#import <NSDrawerFrame.h>
#import <NSDrawerWindow.h>

@interface MFDrawerFrame : NSDrawerFrame {}
- (NSBezierPath*)clippingPathInRect:(NSRect)aRect;
@end