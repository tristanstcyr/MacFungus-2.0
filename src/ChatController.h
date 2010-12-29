#import <Cocoa/Cocoa.h>
#import <AnimatedSplitView.h>
@interface ChatController : NSObject
{
    IBOutlet NSTextField *chatTextField;
    IBOutlet NSTextView *chatTextView;
    IBOutlet id splitView;
	IBOutlet NSDrawer *drawer;
	IBOutlet NSButton *drawerButton;
	id delegate;
}

- (void)setChatEnabled:(BOOL)aBool;
- (IBAction)submitTextField:(id)sender;
- (IBAction)toggleDrawer:(id)sender;

- (void)postMessage:(NSString*)msgStr fromName:(NSString*)nameStr;
- (void)postSystemMessage:(NSString*)msgString;
- (void)clearChatTextView;

- (void)setDelegate:(id)anObject;
- (id)delegate;

+ (NSDictionary *)chatNameAttributes;
+ (NSDictionary *)chatMessageAttributes;
+ (NSDictionary *)systemMessageAttributes;
@end
